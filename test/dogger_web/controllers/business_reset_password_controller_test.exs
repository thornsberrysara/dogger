defmodule DoggerWeb.BusinessResetPasswordControllerTest do
  use DoggerWeb.ConnCase, async: true

  alias Dogger.Businesses
  alias Dogger.Repo
  import Dogger.BusinessesFixtures

  setup do
    %{business: business_fixture()}
  end

  describe "GET /businesses/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.business_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Forgot your password?</h1>"
    end
  end

  describe "POST /businesses/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, business: business} do
      conn =
        post(conn, Routes.business_reset_password_path(conn, :create), %{
          "business" => %{"email" => business.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Businesses.BusinessToken, business_id: business.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.business_reset_password_path(conn, :create), %{
          "business" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Businesses.BusinessToken) == []
    end
  end

  describe "GET /businesses/reset_password/:token" do
    setup %{business: business} do
      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_reset_password_instructions(business, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, Routes.business_reset_password_path(conn, :edit, token))
      assert html_response(conn, 200) =~ "<h1>Reset password</h1>"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.business_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /businesses/reset_password/:token" do
    setup %{business: business} do
      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_reset_password_instructions(business, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, business: business, token: token} do
      conn =
        put(conn, Routes.business_reset_password_path(conn, :update, token), %{
          "business" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == Routes.business_session_path(conn, :new)
      refute get_session(conn, :business_token)
      assert get_flash(conn, :info) =~ "Password reset successfully"
      assert Businesses.get_business_by_email_and_password(business.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.business_reset_password_path(conn, :update, token), %{
          "business" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Reset password</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.business_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
