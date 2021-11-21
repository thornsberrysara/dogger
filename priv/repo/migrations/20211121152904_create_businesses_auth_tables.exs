defmodule Dogger.Repo.Migrations.CreateBusinessesAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:businesses) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:businesses, [:email])

    create table(:businesses_tokens) do
      add :business_id, references(:businesses, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:businesses_tokens, [:business_id])
    create unique_index(:businesses_tokens, [:context, :token])
  end
end
