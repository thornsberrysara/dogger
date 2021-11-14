defmodule Dogger.StaysFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dogger.Stays` context.
  """

  @doc """
  Generate a stay.
  """
  def stay_fixture(attrs \\ %{}) do
    {:ok, stay} =
      attrs
      |> Enum.into(%{
        arrival_date: ~D[2021-11-13],
        departure_date: ~D[2021-11-13]
      })
      |> Dogger.Stays.create_stay()

    stay
  end
end
