defmodule SJWeb.AuthController do
  use SJWeb, :controller

  plug(Ueberauth)
  plug Guardian.Permissions, [ensure: %{user_roles: [:admin]}] when action in [:create]

  import Ecto.Changeset
  require Logger

  alias Argon2, as: PasswordHash
  alias SJ.Repo
  alias SJ.User
  alias SJ.Guardian

  def auth_error(conn, {type, reason}, _opts) do
    conn |> render_json({:forbidden, type, reason}) |> halt()
  end

  #
  # AUTH PROTECTED
  #
  def create(conn, json_params) do
    # ensure_role_is(conn, :admin)

    utc_now = DateTime.utc_now()

    new_user =
      %User{}
      |> cast(json_params, [:email, :clear_password, :full_name, :role])
      |> validate_required([:email, :clear_password, :role])
      |> unique_constraint(:email)
      |> validate_format(:email, ~r/@/, message: "Does not look like a valid email")
      |> validate_length(:clear_password, min: 8, max: 20, message: "Password must between 8-20")
      |> validate_inclusion(:role, [:librarian, :member],
        message: "Allowed roles are [librarian, member]"
      )
      |> put_change(:password, encrypt_password(json_params["clear_password"]))
      |> put_change(:verification, build_verification_token())
      |> put_change(:inserted_at, utc_now)
      |> put_change(:updated_at, utc_now)

    response =
      case Repo.insert(new_user) do
        {:ok, created} ->
          Logger.debug("Created new user #{inspect(created)}")
          {:created, created}

        {:error, cs} ->
          if is_duplicate_email(cs) do
            email = json_params["email"]
            Logger.warn("Duplicate email: #{email}")
            {:conflict, :duplicate_email, email}
          else
            Logger.warn("Failed to create new user due to error: #{inspect(cs.errors)}")
            {:bad_request, :bad_request, cs}
          end
      end

    render_json(conn, response)
  end

  def change_password(
        conn,
        %{"id" => user_id, "old_password" => old_password, "new_password" => new_password} =
          _params
      ) do
    response =
      case Repo.get(User, user_id) do
        nil ->
          {:not_found, :invalid_id, user_id}

        user ->
          if user.verification != nil do
            {:not_acceptable, :not_verified}
          else
            case validate_password(user.password, old_password) do
              {:ok, _} ->
                changeset =
                  User.changeset(user)
                  |> put_change(:password, encrypt_password(new_password))
                  |> put_change(
                    :updated_at,
                    DateTime.utc_now()
                  )

                case Repo.update(changeset) do
                  {:ok, updated} ->
                    {:ok, updated}

                  {:error, cs} ->
                    Logger.error("Failed to change password: #{inspect(cs.errors)}")
                    {:internal_server_error, :db, cs}
                end

              {:error, err_code} ->
                {:not_acceptable, :invalid_password, err_code}
            end
          end
      end

    render_json(conn, response)
  end

  def get_user(conn, _params) do
    response = %{
      user: SJ.Guardian.Plug.current_resource(conn),
      claims: SJ.Guardian.Plug.current_claims(conn)
    }

    conn
    |> render_json({:ok, response})
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> render_json({:ok, "Signed out"})
  end

  #
  # PUBLIC
  #
  def verify(conn, %{"id" => user_id, "verification" => token} = _params) do
    response =
      case Repo.get(User, user_id) do
        nil ->
          {:not_found, :invalid_id, user_id}

        user ->
          if !is_blank(user.verification) do
            if user.verification == token do
              changeset =
                User.changeset(user)
                |> put_change(:verification, nil)

              case Repo.update(changeset) do
                {:ok, verified} ->
                  {:ok, verified}

                {:error, cs} ->
                  Logger.error("Failed to clear verification token: #{inspect(cs.errors)}")
                  {:internal_server_error, :db, cs}
              end
            else
              {:bad_request, :invalid_token, token}
            end
          else
            {:already_reported, user}
          end
      end

    render_json(conn, response)
  end

  def request_change_token(conn, %{"email" => email} = _params) do
    response =
      case Repo.get_by(User, email: email) do
        nil ->
          {:not_found, :invalid_email, email}

        user ->
          if is_blank(user.verification) do
            token = build_verification_token()

            changeset =
              User.changeset(user)
              |> put_change(:verification, token)

            case Repo.update(changeset) do
              {:ok, updated} ->
                send_password_recovery_email(updated)
                {:ok, updated.email}

              {:error, cs} ->
                Logger.error("Failed to set verification token: #{inspect(cs.errors)}")
                {:internal_server_error, :db, cs}
            end
          else
            {:not_acceptable, :not_verified, email}
          end
      end

    render_json(conn, response)
  end

  def reset_password(
        conn,
        %{"email" => email, "password" => password, "verification" => token} = _params
      ) do
    response =
      case Repo.get_by(User, email: email) do
        nil ->
          {:not_found, :invalid_email, email}

        user ->
          if !is_blank(user.verification) do
            if user.verification == token do
              changeset =
                User.changeset(user)
                |> put_change(:password, encrypt_password(password))
                |> put_change(:verification, nil)

              case Repo.update(changeset) do
                {:ok, updated} ->
                  {:ok, updated}

                {:error, cs} ->
                  Logger.error("Failed to reset password: #{inspect(cs.errors)}")
                  {:internal_server_error, :db, cs}
              end
            else
              {:bad_request, :invalid_token, token}
            end
          else
            {:not_acceptable, :reset_done, email}
          end
      end

    render_json(conn, response)
  end

  def callback(
        %{
          assigns: %{
            ueberauth_failure: _fails
          }
        } = conn,
        _params
      ) do
    conn
    |> render_json({:forbidden, :auth, "Failed to authenticate."})
  end

  def callback(
        %{
          assigns: %{
            ueberauth_auth: auth
          }
        } = conn,
        %{"provider" => "identity"} = _params
      ) do
    email = auth.uid
    password = auth.credentials.other.password

    response =
      case Repo.get_by(User, email: email) do
        nil ->
          {:not_found, :invalid_id, email}

        user ->
          if user.verification != nil do
            {:not_acceptable, :not_verified}
          else
            case validate_password(user, password) do
              {:ok, _} ->
                changeset =
                  User.changeset(user)
                  |> put_change(
                    :last_login,
                    DateTime.utc_now()
                  )

                case Repo.update(changeset) do
                  {:ok, _} ->
                    {:ok, token, _} =
                      Guardian.encode_and_sign(
                        user,
                        %{
                          typ: "access"
                        },
                        permissions: %{
                          user_roles: [user.role]
                        }
                      )

                    {:ok, %{token: token, user: user}}

                  {:error, cs} ->
                    Logger.error("Failed to sign in: #{inspect(cs.errors)}")
                    {:internal_server_error, :db, cs}
                end

              {:error, err_code} ->
                {:not_acceptable, :invalid_password, err_code}
            end
          end
      end

    render_json(conn, response)
  end

  def callback(
        %{
          assigns: %{
            ueberauth_auth: auth
          }
        } = conn,
        %{"provider" => provider} = _params
      ) do
    Logger.info("Auth callback from  #{provider}: #{inspect(auth)}")

    conn
    |> render_json({:forbidden, :auth, "Provider #{provider} is not supported yet"})
  end

  #
  # PRIVATE
  #
  defp build_verification_token() do
    :crypto.strong_rand_bytes(128)
    |> Base.url_encode64()
    |> binary_part(0, 128)
  end

  defp generate_random_password() do
    :crypto.strong_rand_bytes(64)
    |> Base.url_encode64()
    |> binary_part(0, 10)
  end

  defp encrypt_password(clear_password) do
    %{password_hash: password_hash} = PasswordHash.add_hash(clear_password)
    password_hash
  end

  def validate_password(user, clear_password) do
    PasswordHash.check_pass(user, clear_password, hash_key: :password)
  end

  defp is_duplicate_email(changeset) do
    !(changeset.errors
      |> Enum.find(fn x ->
        elem(x, 0) == :email && elem(elem(x, 1), 0) == "has already been taken"
      end)
      |> is_nil)
  end

  defp send_user_creation_email(new_user) do
    SJWeb.Email.welcome_html_email(new_user)
    |> SJ.Mailer.deliver_now()
  end

  defp send_password_recovery_email(user) do
    case SJWeb.Email.password_recover_html_email(user)
         |> SJ.Mailer.deliver_now() do
      {:ok, _} ->
        Logger.info("Password recovery email sent to #{user.email}")

      {:error, err} ->
        Logger.error(
          "Failed to send Password recovery email to #{user.email} due to error #{inspect(err)}"
        )
    end
  end

  # defp role_is(conn, role) do
  #   Guardian.Plug.current_claims(conn)
  #   |> Guardian.decode_permissions_from_claims()
  #   |> Guardian.all_permissions?(%{user_roles: [role]})
  # end

  # defp ensure_role_is(conn, role) do
  #   if !role_is(conn, role) do
  #     render_json(conn, {:forbidden, :not_authorized, ""})
  #   end
  # end
end
