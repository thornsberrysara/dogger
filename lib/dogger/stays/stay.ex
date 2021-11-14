defmodule Dogger.Stays.Stay do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stays" do
    field :arrival_date, :date
    field :departure_date, :date

    timestamps()
  end

  @doc false
  def changeset(stay, attrs) do
    stay
    |> cast(attrs, [:arrival_date, :departure_date])
    |> validate_required([:arrival_date, :departure_date])
  end
end
