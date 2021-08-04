defmodule SJ.User do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger
  alias SJ.Enums

  schema "user" do
    field :email, :string
    field :clear_password, :string, virtual: true
    field :password, :string
    field :full_name, :string
    field :role, Enums.Role
    field :last_login, :utc_datetime_usec
    field :verification, :string

    timestamps([type: :utc_datetime_usec])
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :email, :password, :full_name, :role, :last_login, :verification])
  end

  defimpl Jason.Encoder, for: SJ.User do
    def encode(model, opts) do
      model
      |> Map.take([:id, :email, :full_name, :role, :last_login, :verification])
      |> Jason.Encoder.encode(opts)
    end
  end

end
