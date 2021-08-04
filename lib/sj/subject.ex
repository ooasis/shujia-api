defmodule SJ.Subject do
  use Ecto.Schema

  schema "subject" do
    field :name

    many_to_many :catalogs, SJ.Catalog, join_through: "catalog_subjects"

    timestamps([type: :utc_datetime_usec])
  end

  use SJ.NameModel

end
