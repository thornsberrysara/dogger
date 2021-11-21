defmodule DoggerWeb.BusinessSettingsControllerTest do
  use DoggerWeb.ConnCase, async: true

  alias Dogger.Businesses
  import Dogger.BusinessesFixtures

  setup :register_and_log_in_business

  describe "GET /businesses/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.business_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if business is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.business_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.business_session_path(conn, :new)
    end
  end

  describe "PUT /businesses/settings (change password form)" do
    test "updates the business password and resets tokens", %{conn: conn, business: business} do
      new_password_conn =
        put(conn, Routes.business_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_business_password(),
          "business" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.business_settings_path(conn, :edit)
      assert get_session(new_password_conn, :business_token) != get_session(conn, :business_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Businesses.get_business_by_email_and_password(business.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.business_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "business" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :business_token) == get_session(conn, :business_token)
    end
  end

  describe "PUT /businesses/settings (change email form)" do
    @tag :capture_log
    test "updates the business email", %{conn: conn, business: business} do
      conn =
        put(conn, Routes.business_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_business_password(),
          "business" => %{"email" => unique_business_email()}
        })

      assert redirected_to(conn) == Routes.business_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Businesses.get_business_by_email(business.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.business_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "business" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /businesses/settings/confirm_email/:token" do
    setup %{business: business} do
      email = unique_business_email()

      token =
        extract_business_token(fn url ->
          Businesses.deliver_update_email_instructions(%{business | email: email}, business.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the business email once", %{conn: conn, business: business, token: token, email: email} do
      conn = get(conn, Routes.business_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.business_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Businesses.get_business_by_email(business.email)
      assert Businesses.get_business_by_email(email)

      conn = get(conn, Routes.business_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.business_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, business: business} do
      conn = get(conn, Routes.business_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.business_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Businesses.get_business_by_email(business.email)
    end

    test "redirects if business is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.business_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.business_session_path(conn, :new)
    end
  end
end
