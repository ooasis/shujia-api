defmodule SJ.NameModel do
  alias SJ.Repo

  defmacro __using__(_) do

    quote bind_quoted: [] do
      import Ecto.Changeset

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:name, :inserted_at, :updated_at])
        |> validate_required([:name])
        |> unique_constraint(:name)
      end

      def get_or_insert(params) do
        utc_now = DateTime.utc_now()
        struct = %__MODULE__{inserted_at: utc_now, updated_at: utc_now}
        Repo.insert(
          __MODULE__.changeset(struct, params),
          on_conflict: [set: [updated_at: utc_now]],
          conflict_target: :name
        )
      end

    end
  end

end
