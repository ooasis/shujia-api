defmodule SJ.GraphqlResolver do
  import Ecto.Changeset
  import Ecto.Query
  import SJWeb.ErrorHelpers

  alias SJ.Guardian
  alias SJ.Repo
  alias SJ.{Publisher, Subject, Author, Translator, Catalog}

  @default_query_roles [:librarian, :member]
  @default_mutate_roles [:librarian]

  def fetch_one(model, roles \\ @default_query_roles) do
    fn _parent, %{id: id}, resolution ->
      if role_in(resolution, roles) do
        {:ok, Repo.get(model, id)}
      else
        {:error, "Not authorized to use this api"}
      end
    end
  end

  def fetch_all(model, roles \\ @default_query_roles) do
    fn _parent, %{id: _id}, resolution ->
      if role_in(resolution, roles) do
        {:ok, Repo.all(model)}
      else
        {:error, "Not authorized to use this api"}
      end
    end
  end

  def fetch_catalog(_parent, %{id: id}, resolution) do
    if role_in(resolution, [:librarian, :member]) do
      {
        :ok,
        Repo.one(
          from(c in Catalog,
            where: c.id == ^id,
            preload: [:items, :authors, :translators, :subjects, :publisher]
          )
        )
      }
    else
      {:error, "Not authorized to use this api"}
    end
  end

  def query_catalogs(_parent, %{q: q}, resolution) do
    if role_in(resolution, [:librarian, :member]) do
      {
        :ok,
        Repo.all(
          from(c in Catalog,
            # join: a in assoc(c, :authors),
            where: ilike(c.name, ^"%#{q}%") or ilike(c.alt_name, ^"%#{q}%"),
            #  or ilike(a.name, ^"%#{q}%"),
            preload: [:items, :authors, :translators, :subjects, :publisher]
          )
        )
      }
    else
      {:error, "Not authorized to use this api"}
    end
  end

  def create_named_obj(model, roles \\ @default_query_roles) do
    fn _parent, %{name: name}, resolution ->
      if role_in(resolution, roles) do
        # utc_now = DateTime.utc_now()

        case model.get_or_insert(%{name: name}) do
          {:ok, new_obj} ->
            {:ok, new_obj}

          {:error, cs} ->
            {:error, encode_changeset_error(cs)}
        end
      else
        {:error, "Not authorized to use this api"}
      end
    end
  end

  def create_catalog(_parent, args, resolution) do
    if role_in(resolution, [:librarian, :member]) do
      # utc_now = DateTime.utc_now()

      with {:ok, catalog} <- upsert_catalog_alone(args),
           {:ok, _} <- update_subjects(catalog.id, Map.get(args, :subjects, nil)),
           {:ok, _} <- update_authors(catalog.id, Map.get(args, :authors, nil)),
           {:ok, _} <- update_translators(catalog.id, Map.get(args, :translators, nil)) do
        {
          :ok,
          Repo.one(
            from(c in Catalog,
              where: c.id == ^catalog.id,
              preload: [:items, :authors, :translators, :subjects, :publisher]
            )
          )
        }
      else
        err -> {:error, err}
      end
    else
      {:error, "Not authorized to use this api"}
    end
  end

  #
  # PRIVATE
  #
  defp role_in(
         %{
           context: %{
             claims: claims
           }
         },
         roles
       ) do
    claims
    |> Guardian.decode_permissions_from_claims()
    |> Guardian.any_permissions?(%{"user_roles" => roles})
  end

  defp upsert_catalog_alone(args) do
    utc_now = DateTime.utc_now()

    case %Catalog{}
         |> cast(args, [:call_id, :edition, :name, :alt_name, :lang, :format, :publish_year])
         |> validate_required([:name, :lang, :format])
         |> validate_publish_year()
         |> put_change(:publish_date, parse_publish_date(args))
         |> put_change(:inserted_at, utc_now)
         |> put_change(:updated_at, utc_now)
         |> put_assoc(:publisher, parse_named_obj_value(args, :publisher, Publisher))
         |> Repo.insert(
           on_conflict: :replace_all,
           conflict_target: [:call_id, :name, :edition]
         ) do
      {:ok, new_obj} -> {:ok, new_obj}
      {:error, cs} -> {:error, encode_changeset_error(cs)}
    end
  end

  defp update_subjects(_catalog_id, nil) do
  end

  defp update_subjects(catalog_id, subjects) do
    Repo.delete_all(from(am in "catalog_subjects", where: am.catalog_id == ^catalog_id))

    subject_ids =
      insert_and_get_all(subjects, Subject)
      |> Enum.map(fn r -> r.id end)

    new_entries =
      for subject_id <- subject_ids, do: %{catalog_id: catalog_id, subject_id: subject_id}

    Repo.insert_all("catalog_subjects", new_entries)
    {:ok, ""}
  end

  defp update_authors(_catalog_id, nil) do
  end

  defp update_authors(catalog_id, authors) do
    Repo.delete_all(from(am in "catalog_authors", where: am.catalog_id == ^catalog_id))

    author_ids =
      insert_and_get_all(authors, Author)
      |> Enum.map(fn r -> r.id end)

    new_entries = for author_id <- author_ids, do: %{catalog_id: catalog_id, author_id: author_id}
    Repo.insert_all("catalog_authors", new_entries)
    {:ok, ""}
  end

  defp update_translators(_catalog_id, nil) do
  end

  defp update_translators(catalog_id, translators) do
    Repo.delete_all(from(am in "catalog_translators", where: am.catalog_id == ^catalog_id))

    translator_ids =
      insert_and_get_all(translators, Translator)
      |> Enum.map(fn r -> r.id end)

    new_entries =
      for translator_id <- translator_ids,
          do: %{catalog_id: catalog_id, translator_id: translator_id}

    Repo.insert_all("catalog_translators", new_entries)
    {:ok, ""}
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

  defp parse_publish_date(args) do
    case Map.get(args, :publish_year) do
      nil ->
        nil

      publish_year ->
        case Date.new(publish_year, 1, 1) do
          {:ok, d} -> d
          _ -> nil
        end
    end
  end

  # defp populate_virtual_fields(catalog) do
  #   catalog
  #   |> Map.put(:subject_set, populate_virtual(catalog.subjects))
  #   |> Map.put(:author_set, populate_virtual(catalog.authors))
  #   |> Map.put(:translator_set, populate_virtual(catalog.translators))
  #   |> Map.put(
  #     :publish_year,
  #     if(is_nil(catalog.publish_date), do: nil, else: catalog.publish_date.year)
  #   )
  # end

  # defp populate_virtual(field) when is_nil(field) do
  #   ""
  # end

  # defp populate_virtual(field) do
  #   field
  #   |> Enum.map_join(", ", & &1.name)
  # end

  defp parse_named_obj_value(params, field, field_model) do
    case params[field] do
      nil ->
        nil

      "" ->
        nil

      named_obj ->
        insert_and_get(named_obj["name"], field_model)
    end
  end

  # defp parse_field_values(params, field, field_model) do
  #   (params[field] || [])
  #   |> insert_and_get_all(field_model)
  # end

  # defp insert_and_get_all([]) do
  #   []
  # end

  defp insert_and_get_all(names, field_model) do
    utc_now = DateTime.utc_now()
    maps = Enum.map(names, &%{name: &1, inserted_at: utc_now, updated_at: utc_now})
    Repo.insert_all(field_model, maps, on_conflict: :nothing, conflict_target: :name)
    Repo.all(from(t in field_model, where: t.name in ^names))
  end

  defp insert_and_get(name, _) when is_nil(name) do
    nil
  end

  defp insert_and_get(name, field_model) do
    field_model.get_or_insert(%{name: name})
    Repo.one(from(t in field_model, where: t.name == ^name))
  end
end
