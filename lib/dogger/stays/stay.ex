defmodule Dogger.Stays.Stay do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stays" do
    field :arrival_date, :date
    field :departure_date, :date
    belongs_to :pet, Dogger.Pets.Pet

    timestamps()
  end

  @doc false
  def changeset(stay, attrs) do
    stay
    |> cast(attrs, [:arrival_date, :departure_date, :pet_id])
    |> validate_required([:arrival_date, :departure_date, :pet_id])
  end
end
