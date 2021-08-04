defmodule SJ.Inventory do
  use Ecto.Schema

  schema "inventory" do
    field :copy_seq, :integer

    belongs_to :catalog, SJ.Catalog
    belongs_to :borrowers, SJ.User, foreign_key: :borrower
    belongs_to :last_modified_bys, SJ.User, foreign_key: :last_modified_by

    field :checkout_date, :date
    field :due_date, :date
    field :notes, :string

    timestamps([type: :utc_datetime_usec])
  end
end
