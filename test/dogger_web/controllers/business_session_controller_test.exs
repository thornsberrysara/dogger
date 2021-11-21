defmodule DoggerWeb.BusinessSessionControllerTest do
  use DoggerWeb.ConnCase, async: true

  import Dogger.BusinessesFixtures

  setup do
    %{business: business_fixture()}
  end

  describe "GET /businesses/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.business_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, business: business} do
      conn = conn |> log_in_business(business) |> get(Routes.business_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /businesses/log_in" do
    test "logs the business in", %{conn: conn, business: business} do
      conn =
        post(conn, Routes.business_session_path(conn, :create), %{
          "business" => %{"email" => business.email, "password" => valid_business_password()}
        })

      assert get_session(conn, :business_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ business.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the business in with remember me", %{conn: conn, business: business} do
      conn =
        post(conn, Routes.business_session_path(conn, :create), %{
          "business" => %{
            "email" => business.email,
            "password" => valid_business_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_dogger_web_business_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the business in with return to", %{conn: conn, business: business} do
      conn =
        conn
        |> init_test_session(business_return_to: "/foo/bar")
        |> post(Routes.business_session_path(conn, :create), %{
          "business" => %{
            "email" => business.email,
            "password" => valid_business_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, business: business} do
      conn =
        post(conn, Routes.business_session_path(conn, :create), %{
          "business" => %{"email" => business.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /businesses/log_out" do
    test "logs the business out", %{conn: conn, business: business} do
      conn = conn |> log_in_business(business) |> delete(Routes.business_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :business_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the business is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.business_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :business_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
