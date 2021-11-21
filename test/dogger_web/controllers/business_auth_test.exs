defmodule DoggerWeb.BusinessAuthTest do
  use DoggerWeb.ConnCase, async: true

  alias Dogger.Businesses
  alias DoggerWeb.BusinessAuth
  import Dogger.BusinessesFixtures

  @remember_me_cookie "_dogger_web_business_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, DoggerWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{business: business_fixture(), conn: conn}
  end

  describe "log_in_business/3" do
    test "stores the business token in the session", %{conn: conn, business: business} do
      conn = BusinessAuth.log_in_business(conn, business)
      assert token = get_session(conn, :business_token)
      assert get_session(conn, :live_socket_id) == "businesses_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Businesses.get_business_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, business: business} do
      conn = conn |> put_session(:to_be_removed, "value") |> BusinessAuth.log_in_business(business)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, business: business} do
      conn = conn |> put_session(:business_return_to, "/hello") |> BusinessAuth.log_in_business(business)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, business: business} do
      conn = conn |> fetch_cookies() |> BusinessAuth.log_in_business(business, %{"remember_me" => "true"})
      assert get_session(conn, :business_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :business_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_business/1" do
    test "erases session and cookies", %{conn: conn, business: business} do
      business_token = Businesses.generate_business_session_token(business)

      conn =
        conn
        |> put_session(:business_token, business_token)
        |> put_req_cookie(@remember_me_cookie, business_token)
        |> fetch_cookies()
        |> BusinessAuth.log_out_business()

      refute get_session(conn, :business_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Businesses.get_business_by_session_token(business_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "businesses_sessions:abcdef-token"
      DoggerWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> BusinessAuth.log_out_business()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if business is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> BusinessAuth.log_out_business()
      refute get_session(conn, :business_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_business/2" do
    test "authenticates business from session", %{conn: conn, business: business} do
      business_token = Businesses.generate_business_session_token(business)
      conn = conn |> put_session(:business_token, business_token) |> BusinessAuth.fetch_current_business([])
      assert conn.assigns.current_business.id == business.id
    end

    test "authenticates business from cookies", %{conn: conn, business: business} do
      logged_in_conn =
        conn |> fetch_cookies() |> BusinessAuth.log_in_business(business, %{"remember_me" => "true"})

      business_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> BusinessAuth.fetch_current_business([])

      assert get_session(conn, :business_token) == business_token
      assert conn.assigns.current_business.id == business.id
    end

    test "does not authenticate if data is missing", %{conn: conn, business: business} do
      _ = Businesses.generate_business_session_token(business)
      conn = BusinessAuth.fetch_current_business(conn, [])
      refute get_session(conn, :business_token)
      refute conn.assigns.current_business
    end
  end

  describe "redirect_if_business_is_authenticated/2" do
    test "redirects if business is authenticated", %{conn: conn, business: business} do
      conn = conn |> assign(:current_business, business) |> BusinessAuth.redirect_if_business_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if business is not authenticated", %{conn: conn} do
      conn = BusinessAuth.redirect_if_business_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_business/2" do
    test "redirects if business is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> BusinessAuth.require_authenticated_business([])
      assert conn.halted
      assert redirected_to(conn) == Routes.business_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> BusinessAuth.require_authenticated_business([])

      assert halted_conn.halted
      assert get_session(halted_conn, :business_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> BusinessAuth.require_authenticated_business([])

      assert halted_conn.halted
      assert get_session(halted_conn, :business_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> BusinessAuth.require_authenticated_business([])

      assert halted_conn.halted
      refute get_session(halted_conn, :business_return_to)
    end

    test "does not redirect if business is authenticated", %{conn: conn, business: business} do
      conn = conn |> assign(:current_business, business) |> BusinessAuth.require_authenticated_business([])
      refute conn.halted
      refute conn.status
    end
  end
end
