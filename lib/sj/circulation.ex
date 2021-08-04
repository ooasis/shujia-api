defmodule SJ.Circulation do
  use Ecto.Schema

  schema "circulation" do
    field :cat_id, :integer
    field :cat_name, :string
    field :cat_copy_seq, :integer
    field :borrower_id, :integer
    field :borrower_name, :string
    field :checkout_date, :date
    field :return_date, :date
    field :last_modified_by, :string
    field :notes, :string

    timestamps([type: :utc_datetime_usec])
  end
end
