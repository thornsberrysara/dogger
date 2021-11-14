defmodule Dogger.Repo.Migrations.StayBelongsToPet do
  use Ecto.Migration

  def change do
    alter table(:stays) do
      add :pet_id, references(:pets)
    end
  end
end
