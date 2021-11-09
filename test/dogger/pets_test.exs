defmodule Dogger.PetsTest do
  use Dogger.DataCase

  alias Dogger.Pets

  describe "pets" do
    alias Dogger.Pets.Pet

    import Dogger.PetsFixtures

    @invalid_attrs %{breed: nil, dob: nil, medications: nil, name: nil, weight: nil}

    test "list_pets/0 returns all pets" do
      pet = pet_fixture()
      assert Pets.list_pets() == [pet]
    end

    test "get_pet!/1 returns the pet with given id" do
      pet = pet_fixture()
      assert Pets.get_pet!(pet.id) == pet
    end

    test "create_pet/1 with valid data creates a pet" do
      valid_attrs = %{breed: "some breed", dob: ~D[2021-11-08], medications: true, name: "some name", weight: 42}

      assert {:ok, %Pet{} = pet} = Pets.create_pet(valid_attrs)
      assert pet.breed == "some breed"
      assert pet.dob == ~D[2021-11-08]
      assert pet.medications == true
      assert pet.name == "some name"
      assert pet.weight == 42
    end

    test "create_pet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pets.create_pet(@invalid_attrs)
    end

    test "update_pet/2 with valid data updates the pet" do
      pet = pet_fixture()
      update_attrs = %{breed: "some updated breed", dob: ~D[2021-11-09], medications: false, name: "some updated name", weight: 43}

      assert {:ok, %Pet{} = pet} = Pets.update_pet(pet, update_attrs)
      assert pet.breed == "some updated breed"
      assert pet.dob == ~D[2021-11-09]
      assert pet.medications == false
      assert pet.name == "some updated name"
      assert pet.weight == 43
    end

    test "update_pet/2 with invalid data returns error changeset" do
      pet = pet_fixture()
      assert {:error, %Ecto.Changeset{}} = Pets.update_pet(pet, @invalid_attrs)
      assert pet == Pets.get_pet!(pet.id)
    end

    test "delete_pet/1 deletes the pet" do
      pet = pet_fixture()
      assert {:ok, %Pet{}} = Pets.delete_pet(pet)
      assert_raise Ecto.NoResultsError, fn -> Pets.get_pet!(pet.id) end
    end

    test "change_pet/1 returns a pet changeset" do
      pet = pet_fixture()
      assert %Ecto.Changeset{} = Pets.change_pet(pet)
    end
  end
end
