defmodule Dogger.Repo.Migrations.CreateStays do
  use Ecto.Migration

  def change do
    create table(:stays) do
      add :arrival_date, :date
      add :departure_date, :date

      timestamps()
    end
  end
end
