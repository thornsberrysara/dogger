defmodule DoggerWeb.BusinessConfirmationControllerTest do
  use DoggerWeb.ConnCase, async: true

  alias Dogger.Businesses
  alias Dogger.Repo
  import Dogger.BusinessesFixtures

  setup do
    %{business: business_fixture()}
  end

  describe "GET /businesses/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.business_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /businesses/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, business: business} do
      conn =
        post(conn, Routes.business_confirmation_path(conn, :create), %{
          "business" => %{"email" => business.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Businesses.BusinessToken, business_id: business.id).context == "confirm"
    end

    test "does not send confirmation token if Business is confirmed", %{conn: conn, business: business} do
      Repo.update!(Businesses.Business.confirm_changeset(business))

      conn =
        post(conn, Routes.business_confirmation_path(conn, :create), %{
          "business" => %{"email" => business.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Businesses.BusinessToken, business_id: business.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.business_confirmation_path(conn, :create), %{
          "business" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Businesses.BusinessToken) == []
    end
  end

  describe "GET /businesses/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.business_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.business_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /businesses/confirm/:token" do
    test "confirms the given token once", %{conn: conn, business: business} do
      token =
        extract_business_token(fn url ->
          Businesses.deliver_business_confirmation_instructions(business, url)
        end)

      conn = post(conn, Routes.business_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Business confirmed successfully"
      assert Businesses.get_business!(business.id).confirmed_at
      refute get_session(conn, :business_token)
      assert Repo.all(Businesses.BusinessToken) == []

      # When not logged in
      conn = post(conn, Routes.business_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Business confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_business(business)
        |> post(Routes.business_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, business: business} do
      conn = post(conn, Routes.business_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Business confirmation link is invalid or it has expired"
      refute Businesses.get_business!(business.id).confirmed_at
    end
  end
end
