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
        breed: :Boxer,
        dob: ~D[2021-11-08],
        medications: true,
        name: "some name",
        weight: 42,
        owner: [
          email: "some email",
          first_name: "some first_name",
          last_name: "some last_name",
          phone_number: "5555555555"
        ]
      })
      |> Dogger.Pets.create_pet()

    pet
  end
end
