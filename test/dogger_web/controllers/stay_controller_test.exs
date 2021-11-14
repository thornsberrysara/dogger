defmodule DoggerWeb.StayControllerTest do
  use DoggerWeb.ConnCase

  import Dogger.StaysFixtures

  @create_attrs %{arrival_date: ~D[2021-11-13], departure_date: ~D[2021-11-13]}
  @update_attrs %{arrival_date: ~D[2021-11-14], departure_date: ~D[2021-11-14]}
  @invalid_attrs %{arrival_date: nil, departure_date: nil}

  describe "index" do
    test "lists all stays", %{conn: conn} do
      conn = get(conn, Routes.stay_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Stays"
    end
  end

  describe "new stay" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.stay_path(conn, :new))
      assert html_response(conn, 200) =~ "New Stay"
    end
  end

  describe "create stay" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.stay_path(conn, :create), stay: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.stay_path(conn, :show, id)

      conn = get(conn, Routes.stay_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Stay"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.stay_path(conn, :create), stay: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Stay"
    end
  end

  describe "edit stay" do
    setup [:create_stay]

    test "renders form for editing chosen stay", %{conn: conn, stay: stay} do
      conn = get(conn, Routes.stay_path(conn, :edit, stay))
      assert html_response(conn, 200) =~ "Edit Stay"
    end
  end

  describe "update stay" do
    setup [:create_stay]

    test "redirects when data is valid", %{conn: conn, stay: stay} do
      conn = put(conn, Routes.stay_path(conn, :update, stay), stay: @update_attrs)
      assert redirected_to(conn) == Routes.stay_path(conn, :show, stay)

      conn = get(conn, Routes.stay_path(conn, :show, stay))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, stay: stay} do
      conn = put(conn, Routes.stay_path(conn, :update, stay), stay: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Stay"
    end
  end

  describe "delete stay" do
    setup [:create_stay]

    test "deletes chosen stay", %{conn: conn, stay: stay} do
      conn = delete(conn, Routes.stay_path(conn, :delete, stay))
      assert redirected_to(conn) == Routes.stay_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.stay_path(conn, :show, stay))
      end
    end
  end

  defp create_stay(_) do
    stay = stay_fixture()
    %{stay: stay}
  end
end
