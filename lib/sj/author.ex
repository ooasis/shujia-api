defmodule SJ.Author do
  use Ecto.Schema
  import Ecto.Changeset

  schema "author" do
    field :name

    many_to_many :catalogs, SJ.Catalog, join_through: "catalog_authors"

    timestamps([type: :utc_datetime_usec])
  end

  use SJ.NameModel

end
