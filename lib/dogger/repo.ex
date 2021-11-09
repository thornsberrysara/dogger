defmodule Dogger.Repo do
  use Ecto.Repo,
    otp_app: :dogger,
    adapter: Ecto.Adapters.Postgres
end
