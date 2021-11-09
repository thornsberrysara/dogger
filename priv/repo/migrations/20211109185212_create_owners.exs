defmodule Dogger.Repo.Migrations.CreateOwners do
  use Ecto.Migration

  def change do
    create table(:owners) do
      add :first_name, :string
      add :last_name, :string
      add :phone_number, :string
      add :email, :string

      timestamps()
    end
  end
end
