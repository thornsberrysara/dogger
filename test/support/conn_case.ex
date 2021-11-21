defmodule DoggerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DoggerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import DoggerWeb.ConnCase

      alias DoggerWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint DoggerWeb.Endpoint
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Dogger.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in businesses.

      setup :register_and_log_in_business

  It stores an updated connection and a registered business in the
  test context.
  """
  def register_and_log_in_business(%{conn: conn}) do
    business = Dogger.BusinessesFixtures.business_fixture()
    %{conn: log_in_business(conn, business), business: business}
  end

  @doc """
  Logs the given `business` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_business(conn, business) do
    token = Dogger.Businesses.generate_business_session_token(business)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:business_token, token)
  end
end
