defmodule Dogger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Dogger.Repo,
      # Start the Telemetry supervisor
      DoggerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dogger.PubSub},
      # Start the Endpoint (http/https)
      DoggerWeb.Endpoint
      # Start a worker by calling: Dogger.Worker.start_link(arg)
      # {Dogger.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dogger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DoggerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
