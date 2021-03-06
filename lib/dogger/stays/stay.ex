defmodule Dogger.Stays.Stay do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stays" do
    field :arrival_date, :date, default: Date.utc_today()
    field :departure_date, :date, default: Date.utc_today()
    belongs_to :pet, Dogger.Pets.Pet

    timestamps()
  end

  @doc false
  def changeset(stay, attrs) do
    stay
    |> cast(attrs, [:arrival_date, :departure_date, :pet_id])
    |> validate_required([:arrival_date, :departure_date])
  end
end
