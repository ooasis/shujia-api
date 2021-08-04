defmodule SJ.Catalog do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias SJ.Enums, as: SJEnums
  alias SJ.Repo
  alias SJ.{Subject, Author, Translator, Publisher, Inventory}

  schema "catalog" do
    field :call_id, :string
    field :edition, :string
    field :name, :string
    field :alt_name, :string
    field :lang, SJEnums.Language
    field :format, SJEnums.Format
    field :publish_year, :integer, virtual: true
    field :publish_date, :date

    has_many :items, Inventory
    belongs_to :publisher, Publisher

    field :subject_set, :string, virtual: true
    many_to_many :subjects, Subject, join_through: "catalog_subjects", on_replace: :delete
    field :author_set, :string, virtual: true
    many_to_many :authors, Author, join_through: "catalog_authors", on_replace: :delete
    field :translator_set, :string, virtual: true
    many_to_many :translators, Translator, join_through: "catalog_translators", on_replace: :delete

    timestamps([type: :utc_datetime_usec])
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:call_id, :edition, :name, :alt_name, :lang, :format, :publish_date])
    |> validate_required([:name, :lang, :format])
  end

  def query(q) do
    Repo.all(
      from c in __MODULE__,
      # join: a in assoc(c, :authors),
      where: ilike(c.name, ^"%#{q}%") or ilike(c.alt_name, ^"%#{q}%"),
      #  or ilike(a.name, ^"%#{q}%"),
      preload: [:items, :authors, :translators, :subjects, :publisher]
    )
    |> Enum.map(&pupulate_virtuals/1)
  end

  def find(cat_id) do
    Repo.one(
      from c in __MODULE__,
      where: c.id == ^cat_id,
      preload: [:items, :authors, :translators, :subjects, :publisher]
    )
    |> pupulate_virtuals()
  end

  def insert(params) do
    utc_now = DateTime.utc_now()
    %__MODULE__{}
    |> cast(params, [:call_id, :edition, :name, :alt_name, :lang, :format, :publish_year])
    |> validate_required([:name, :lang, :format])
    |> validate_publish_year()
    |> put_change(:publish_date, parse_publish_date(params))
    |> put_change(:inserted_at, utc_now)
    |> put_change(:updated_at, utc_now)
    |> put_assoc(:publisher, parse_named_obj_value(params, "publisher", Publisher))
    |> put_assoc(:subjects, parse_field_values(params, "subject_set", Subject))
    |> put_assoc(:authors, parse_field_values(params, "author_set", Author))
    |> put_assoc(:translators, parse_field_values(params, "translator_set", Translator))
    |> Repo.insert()
  end

  def update(%{"id" => cat_id} = params) do
    utc_now = DateTime.utc_now()
    cs = __MODULE__.find(cat_id)
         |> cast(params, [:alt_name, :lang, :format, :publish_year])
         |> validate_required([:lang, :format])
         |> put_change(:updated_at, utc_now)
         |> put_assoc(:subjects, parse_field_values(params, "subject_set", Subject))
         |> put_assoc(:authors, parse_field_values(params, "author_set", Author))
         |> put_assoc(:translators, parse_field_values(params, "translator_set", Translator))
    cs
    |> Repo.update()
  end

  defp validate_publish_year(changeset) do
    validate_change(
      changeset,
      :publish_year,
      fn _, publish_year ->
        case publish_year > 1900 && publish_year < 2050 do
          true -> []
          false -> [{:publish_year, "Invalid publish year: #{publish_year}"}]
        end
      end
    )
  end

  defp parse_publish_date(params) do
    case Map.get(params, "publish_year") do
      nil -> nil
      publish_year ->
        case Date.new(publish_year, 1, 1) do
          {:ok, d} -> d
          _ -> nil
        end
    end
  end

  defp pupulate_virtuals(catalog) do
    catalog
    |> Map.put(:subject_set, populate_virtual(catalog.subjects))
    |> Map.put(:author_set, populate_virtual(catalog.authors))
    |> Map.put(:translator_set, populate_virtual(catalog.translators))
    |> Map.put(:publish_year, (if (is_nil(catalog.publish_date)), do: nil, else: catalog.publish_date.year))
  end

  defp populate_virtual(field) when is_nil(field)do
    ""
  end
  defp populate_virtual(field) do
    field
    |> Enum.map_join(", ", &(&1.name))
  end

  defp parse_named_obj_value(params, field, field_model)  do
    case params[field] do
      nil -> nil
      "" -> nil
      named_obj ->
        insert_and_get(named_obj["name"], field_model)
    end
  end

  defp parse_field_values(params, field, field_model)  do
    (params[field] || "")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(& &1 == "")
    |> insert_and_get_all(field_model)
  end

  defp insert_and_get_all([]) do
    []
  end
  defp insert_and_get_all(names, field_model) do
    utc_now = DateTime.utc_now()
    maps = Enum.map(names, &%{name: &1, inserted_at: utc_now, updated_at: utc_now})
    Repo.insert_all(field_model, maps, on_conflict: :nothing)
    Repo.all(from t in field_model, where: t.name in ^names)
  end

  defp insert_and_get(name, _) when is_nil(name) do
    nil
  end
  defp insert_and_get(name, field_model) do
    field_model.get_or_insert(%{name: name})
    Repo.one(from t in field_model, where: t.name == ^name)
  end

end
