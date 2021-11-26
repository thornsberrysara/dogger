defmodule Dogger.Repo.Migrations.OwnerBelongsToBusiness do
  use Ecto.Migration

  def change do
    alter table(:owners) do
      add :business_id, references(:businesses)
    end
  end
end
