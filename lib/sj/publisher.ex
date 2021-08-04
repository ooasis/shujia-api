defmodule SJ.Publisher do
  use Ecto.Schema

  schema "publisher" do
    field :name

    has_many :catalogs, SJ.Catalog

    timestamps([type: :utc_datetime_usec])
  end

  use SJ.NameModel

end
