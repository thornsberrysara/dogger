defmodule Dogger.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    create table(:pets) do
      add :name, :string
      add :breed, :string
      add :dob, :date
      add :weight, :integer
      add :medications, :boolean, default: false, null: false

      timestamps()
    end
  end
end
