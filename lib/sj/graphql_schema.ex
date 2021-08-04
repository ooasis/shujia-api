defmodule SJ.GraphqlSchema do
  use Absinthe.Schema
  # use Absinthe.Schema.Notation
  import_types(SJ.GraphqlType)

  alias SJ.GraphqlResolver

  query do
    field :users, list_of(:user) do
      resolve(GraphqlResolver.fetch_all(User))
    end

    field :user, :user do
      arg(:id, non_null(:id))
      resolve(GraphqlResolver.fetch_one(User))
    end

    field :publishers, list_of(:publisher) do
      resolve(GraphqlResolver.fetch_all(Publisher))
    end

    field :publisher, :publisher do
      arg(:id, non_null(:id))
      resolve(GraphqlResolver.fetch_one(Publisher))
    end

    field :subjects, list_of(:subject) do
      resolve(GraphqlResolver.fetch_all(Subject))
    end

    field :subject, :subject do
      arg(:id, non_null(:id))
      resolve(GraphqlResolver.fetch_one(Subject))
    end

    field :authors, list_of(:author) do
      resolve(GraphqlResolver.fetch_all(Author))
    end

    field :author, :author do
      arg(:id, non_null(:id))
      resolve(GraphqlResolver.fetch_one(Author))
    end

    field :translators, list_of(:translator) do
      resolve(GraphqlResolver.fetch_all(Translator))
    end

    field :translator, :translator do
      arg(:id, non_null(:id))
      resolve(GraphqlResolver.fetch_one(Translator))
    end

    field :catalogs, list_of(:catalog) do
      arg(:q, non_null(:string))
      resolve(&GraphqlResolver.query_catalogs/3)
    end

    field :catalog, :catalog do
      arg(:id, non_null(:id))
      resolve(&GraphqlResolver.fetch_catalog/3)
    end
  end

  mutation do
    field :create_publisher, type: :publisher do
      arg(:name, non_null(:string))
      resolve(GraphqlResolver.create_named_obj(Publisher))
    end

    field :create_subject, type: :subject do
      arg(:name, non_null(:string))
      resolve(GraphqlResolver.create_named_obj(Subject))
    end

    field :create_author, type: :author do
      arg(:name, non_null(:string))
      resolve(GraphqlResolver.create_named_obj(Author))
    end

    field :create_translator, type: :translator do
      arg(:name, non_null(:string))
      resolve(GraphqlResolver.create_named_obj(Translator))
    end

    field :create_catalog, type: :catalog do
      arg(:name, non_null(:string))
      arg(:alt_name, :string)
      arg(:call_id, non_null(:string))
      arg(:edition, :string)
      arg(:lang, non_null(:string))
      arg(:format, non_null(:string))
      arg(:publish_year, :integer)
      arg(:publisher, :string)
      arg(:subjects, list_of(:string))
      arg(:authors, list_of(:string))
      arg(:translators, list_of(:string))
      resolve(&GraphqlResolver.create_catalog/3)
    end
  end
end
