defmodule Dogger.PetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dogger.Pets` context.
  """

  @doc """
  Generate a pet.
  """
  def pet_fixture(attrs \\ %{}) do
    {:ok, pet} =
      attrs
      |> Enum.into(%{
        breed: "some breed",
        dob: ~D[2021-11-08],
        medications: true,
        name: "some name",
        weight: 42
      })
      |> Dogger.Pets.create_pet()

    pet
  end
end
