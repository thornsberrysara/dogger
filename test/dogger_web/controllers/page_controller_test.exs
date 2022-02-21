defmodule DoggerWeb.PageControllerTest do
  use DoggerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Dogger"
  end
end
