defmodule Dogger.Pets.Pet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pets" do
    field :breed, :string
    field :dob, :date
    field :medications, :boolean, default: false
    field :name, :string
    field :weight, :integer
    belongs_to :owner, Dogger.Owners.Owner

    timestamps()
  end

  @doc false
  def changeset(pet, attrs) do
    pet
    |> cast(attrs, [:name, :owner_id, :breed, :dob, :weight, :medications])
    |> validate_required([:name, :owner_id, :breed, :dob, :weight, :medications])
  end
end
