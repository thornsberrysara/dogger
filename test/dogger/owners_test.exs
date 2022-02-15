defmodule Dogger.OwnersTest do
  use Dogger.DataCase

  alias Dogger.Owners

  describe "owners" do
    alias Dogger.Owners.Owner

    import Dogger.OwnersFixtures

    @invalid_attrs %{email: nil, first_name: nil, last_name: nil, phone_number: nil}

    test "list_owners/0 returns all owners" do
      owner = owner_fixture()
      assert Owners.get_owner!(owner.id) == owner
    end

    test "get_owner!/1 returns the owner with given id" do
      owner = owner_fixture()
      assert Owners.get_owner!(owner.id) == owner
    end

    test "create_owner/1 with valid data creates a owner" do
      valid_attrs = %{
        email: "some email",
        first_name: "some first_name",
        last_name: "some last_name",
        phone_number: "42",
        pets: []
      }

      assert {:ok, %Owner{} = owner} = Owners.create_owner(valid_attrs)
      assert owner.email == "some email"
      assert owner.first_name == "some first_name"
      assert owner.last_name == "some last_name"
      assert owner.phone_number == "42"
      assert owner.pets == []
    end

    test "create_owner/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Owners.create_owner(@invalid_attrs)
    end

    test "update_owner/2 with valid data updates the owner" do
      owner = owner_fixture()

      update_attrs = %{
        email: "some updated email",
        first_name: "some updated first_name",
        last_name: "some updated last_name",
        phone_number: "43",
        pets: []
      }

      assert {:ok, %Owner{} = owner} = Owners.update_owner(owner, update_attrs)
      assert owner.email == "some updated email"
      assert owner.first_name == "some updated first_name"
      assert owner.last_name == "some updated last_name"
      assert owner.phone_number == "43"
      assert owner.pets == []
    end

    test "update_owner/2 with invalid data returns error changeset" do
      owner = owner_fixture()
      assert {:error, %Ecto.Changeset{}} = Owners.update_owner(owner, @invalid_attrs)
      assert owner == Owners.get_owner!(owner.id)
    end

    test "delete_owner/1 deletes the owner" do
      owner = owner_fixture()
      assert {:ok, %Owner{}} = Owners.delete_owner(owner)
      assert_raise Ecto.NoResultsError, fn -> Owners.get_owner!(owner.id) end
    end

    test "change_owner/1 returns a owner changeset" do
      owner = owner_fixture()
      assert %Ecto.Changeset{} = Owners.change_owner(owner)
    end
  end
end
