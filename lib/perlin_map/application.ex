defmodule PerlinMap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PerlinMapWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PerlinMap.PubSub},
      # Start the Endpoint (http/https)
      PerlinMapWeb.Endpoint
      # Start a worker by calling: PerlinMap.Worker.start_link(arg)
      # {PerlinMap.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PerlinMap.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PerlinMapWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
