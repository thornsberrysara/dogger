defmodule Dogger.Owners.Owner do
  use Ecto.Schema
  import Ecto.Changeset

  schema "owners" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :phone_number, :string
    has_many :pets, Dogger.Pets.Pet

    timestamps()
  end

  @doc false
  def changeset(owner, attrs) do
    owner
    |> cast(attrs, [:first_name, :last_name, :phone_number, :email])
    |> cast_assoc(:pets)
    |> validate_required([:first_name, :last_name, :phone_number, :email])
  end
end
