defmodule SJ.Guardian do
  use Guardian,
    otp_app: :sj,
    permissions: %{
      user_roles: %{
        admin: 0b1,
        librarian: 0b10,
        member: 0b100
      }
    }

  use Guardian.Permissions, encoding: Guardian.Permissions.BitwiseEncoding

  alias SJ.Repo
  alias SJ.User

  def subject_for_token(user = %User{}, _claims) do
    {:ok, to_string(user.id)}
  end

  def subject_for_token(_, _), do: {:error, "Only resource with id is supported"}

  def resource_from_claims(claims) do
    case Repo.get(User, claims["sub"]) do
      nil -> {:error, "User not found"}
      user -> {:ok, user}
    end
  end

  def build_claims(claims, _resource, opts) do
    claims =
      claims
      |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))

    # IO.puts("Claim after #{inspect claims}")
    {:ok, claims}
  end
end
