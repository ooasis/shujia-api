defmodule SJ.Repo.Migrations.CreateTables do
  use Ecto.Migration

  alias SJ.Enums
  @timestamps_opts [type: :utc_datetime_usec]

  def change do

    create table(:user) do
      add :email, :string, null: false
      add :password, :string, null: false
      add :full_name, :string
      add :role, :enum_role
      add :last_login, :utc_datetime_usec
      add :verification, :string

      timestamps()
    end
    create unique_index(:user, [:email])

    create table(:publisher) do
      add :name, :string, null: false

      timestamps()
    end
    create unique_index(:publisher, [:name])

    create table(:author) do
      add :name, :string, null: false

      timestamps()
    end
    create unique_index(:author, [:name])

    create table(:translator) do
      add :name, :string, null: false

      timestamps()
    end
    create unique_index(:translator, [:name])

    create table(:subject) do
      add :name, :string, null: false

      timestamps()
    end
    create unique_index(:subject, [:name])

    create table(:catalog) do
      add :call_id, :string, null: false
      add :name, :string, null: false
      add :alt_name, :string
      add :edition, :string
      add :lang, :enum_lang, null: false
      add :format, :enum_format, null: false
      add :publish_date, :date

      add :publisher_id, references(:publisher)

      timestamps()
    end
    create unique_index(:catalog, [:call_id, :name, :edition])

    create table(:inventory) do
      add :catalog_id, references(:catalog), null: false
      add :copy_seq, :integer, null: false
      add :borrower, references(:user)
      add :last_modified_by, references(:user)
      add :checkout_date, :date
      add :due_date, :date
      add :notes, :string

      timestamps()
    end
    create unique_index(:inventory, [:catalog_id, :copy_seq])

    create table(:circulation) do
      add :cat_id, :integer, null: false
      add :cat_name, :string, null: false
      add :cat_copy_seq, :integer
      add :borrower_id, :integer, null: false
      add :borrower_name, :string, null: false
      add :checkout_date, :date, null: false
      add :return_date, :date, null: false
      add :last_modified_by, :string, null: false
      add :notes, :string

      timestamps()
    end
    create unique_index(:circulation, [:cat_id, :borrower_id, :checkout_date])

    # reference tables
    create table(:catalog_subjects, primary_key: false) do
      add :catalog_id, references(:catalog)
      add :subject_id, references(:subject)
    end
    create unique_index(:catalog_subjects, [:catalog_id, :subject_id])

    create table(:catalog_authors, primary_key: false) do
      add :catalog_id, references(:catalog)
      add :author_id, references(:author)
    end
    create unique_index(:catalog_authors, [:catalog_id, :author_id])

    create table(:catalog_translators, primary_key: false) do
      add :catalog_id, references(:catalog)
      add :translator_id, references(:translator)
    end
    create unique_index(:catalog_translators, [:catalog_id, :translator_id])

  end

end
