defmodule SJ.Repo.Migrations.CreateEnum do
  use Ecto.Migration
  alias SJ.Enums

  def up do
    Enums.Role.create_type
    Enums.Language.create_type
    Enums.Format.create_type
  end

  def down do
    Enums.Role.drop_type
    Enums.Language.drop_type
    Enums.Format.drop_type
  end

end
