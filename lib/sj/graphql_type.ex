defmodule SJ.GraphqlType do

  use Absinthe.Schema.Notation
  import_types Absinthe.Type.Custom

  enum :role do
    value :admin
    value :librarian
    value :member
  end

  enum :language do
    value :en
    value :cn
    value :tc
    value :sc
  end

  enum :format do
    value :book
    value :audio
    value :vedio
  end

  object :subject do
    field :id, :id
    field :name, :string
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  object :author do
    field :id, :id
    field :name, :string
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  object :translator do
    field :id, :id
    field :name, :string
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  object :publisher do
    field :id, :id
    field :name, :string
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  object :user do
    field :id, :id
    field :email, :string
    field :password, :string
    field :full_name, :string
    field :role, :role
    field :last_login, :datetime
    field :verification, :string
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

  object :catalog do
    field :id, :id
    field :name, :string
    field :alt_name, :string
    field :call_id, :string
    field :edition, :string
    field :lang, :language
    field :format, :format
    field :publish_date, :date

    field :publisher, :publisher
    field :subjects, list_of(:subject)
    field :authors, list_of(:author)
    field :translators, list_of(:translator)

    field :inserted_at, :datetime
    field :updated_at, :datetime
  end

end
