defmodule Dogger.OwnersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Dogger.Owners` context.
  """

  @doc """
  Generate a owner.
  """
  def owner_fixture(attrs \\ %{}) do
    {:ok, owner} =
      attrs
      |> Enum.into(%{
        email: "some email",
        first_name: "some first_name",
        last_name: "some last_name",
        phone_number: "42",
        pets: []
      })
      |> Dogger.Owners.create_owner()

    owner
  end
end
