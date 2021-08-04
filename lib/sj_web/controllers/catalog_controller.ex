defmodule SJWeb.CatalogController do
  use SJWeb, :controller

  alias SJ.{Catalog, Publisher, Author, Translator, Subject}

  def index(conn, %{"q" => q} = _params) do
    found_catalogs = Catalog.query(q)
    conn
    |> render(:index, catalogs: found_catalogs)
  end

  def show(conn, %{"id" => id}) do
    catalog = Catalog.find(id)
    conn
    |> render(:show, catalog: catalog)
  end

  def new(conn, _param) do
    catalog =
      Catalog.find(4762)
      |> Map.put(:id, nil)

    conn
    |> render(:new, changeset: Catalog.changeset(catalog))
  end

  def create(conn, %{"catalog" => catalog_params} = _param) do
    case Catalog.insert(catalog_params) do
      {:ok, created} ->
        catalog = Catalog.find(created.id)
        conn
        |> render(:show, catalog: catalog)
      {:error, cs} ->
        conn
        |> render(:new, changeset: cs)
    end
  end

  def edit(conn, %{"id" => cat_id} = _param) do
    catalog = Catalog.find(cat_id)
    conn
    |> render(:edit, cat_id: cat_id, changeset: Catalog.changeset(catalog))
  end

  def update(conn, %{"catalog" => catalog_params} = _param) do
    case Catalog.update(catalog_params) do
      {:ok, created} ->
        catalog = Catalog.find(created.id)
        conn
        |> render(:show, catalog: catalog)
      {:error, cs} ->
        conn
        |> render(:edit, changeset: cs, id: catalog_params.id)
    end

  end

end
