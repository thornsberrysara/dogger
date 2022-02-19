defmodule Dogger.Repo.Migrations.AlterRelationshipTables do
  use Ecto.Migration

  def change do
    drop(constraint(:stays, "stays_pet_id_fkey"))
    drop(constraint(:pets, "pets_owner_id_fkey"))

    alter table(:stays) do
      modify :pet_id, references(:pets, on_delete: :delete_all)
    end

    alter table(:pets) do
      modify :owner_id, references(:owners, on_delete: :delete_all)
    end
  end
end
