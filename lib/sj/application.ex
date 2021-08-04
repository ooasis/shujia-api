defmodule SJ.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      SJ.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, [name: SJ.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start the Endpoint (http/https)
      SJWeb.Endpoint,
      # Start a worker by calling: SJ.Worker.start_link(arg)
      # {SJ.Worker, arg}
      # Start the Telemetry supervisor
      SJWeb.Telemetry
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SJ.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SJWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
