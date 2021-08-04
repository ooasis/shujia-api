defmodule SJ.Translator do
  use Ecto.Schema

  schema "translator" do
    field :name

    many_to_many :catalogs, SJ.Catalog, join_through: "catalog_translators"

    timestamps([type: :utc_datetime_usec])
  end

  use SJ.NameModel

end
