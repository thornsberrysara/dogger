defmodule Dogger.StaysTest do
  use Dogger.DataCase

  alias Dogger.Stays

  describe "stays" do
    alias Dogger.Stays.Stay

    import Dogger.StaysFixtures

    @invalid_attrs %{arrival_date: nil, departure_date: nil}

    test "list_stays/0 returns all stays" do
      stay = stay_fixture()
      assert Stays.list_stays() == [stay]
    end

    test "get_stay!/1 returns the stay with given id" do
      stay = stay_fixture()
      assert Stays.get_stay!(stay.id) == stay
    end

    test "create_stay/1 with valid data creates a stay" do
      valid_attrs = %{arrival_date: ~D[2021-11-13], departure_date: ~D[2021-11-13]}

      assert {:ok, %Stay{} = stay} = Stays.create_stay(valid_attrs)
      assert stay.arrival_date == ~D[2021-11-13]
      assert stay.departure_date == ~D[2021-11-13]
    end

    test "create_stay/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stays.create_stay(@invalid_attrs)
    end

    test "update_stay/2 with valid data updates the stay" do
      stay = stay_fixture()
      update_attrs = %{arrival_date: ~D[2021-11-14], departure_date: ~D[2021-11-14]}

      assert {:ok, %Stay{} = stay} = Stays.update_stay(stay, update_attrs)
      assert stay.arrival_date == ~D[2021-11-14]
      assert stay.departure_date == ~D[2021-11-14]
    end

    test "update_stay/2 with invalid data returns error changeset" do
      stay = stay_fixture()
      assert {:error, %Ecto.Changeset{}} = Stays.update_stay(stay, @invalid_attrs)
      assert stay == Stays.get_stay!(stay.id)
    end

    test "delete_stay/1 deletes the stay" do
      stay = stay_fixture()
      assert {:ok, %Stay{}} = Stays.delete_stay(stay)
      assert_raise Ecto.NoResultsError, fn -> Stays.get_stay!(stay.id) end
    end

    test "change_stay/1 returns a stay changeset" do
      stay = stay_fixture()
      assert %Ecto.Changeset{} = Stays.change_stay(stay)
    end
  end
end
