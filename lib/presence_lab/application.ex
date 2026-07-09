defmodule PresenceLab.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      PresenceLabWeb.Telemetry,
      PresenceLab.Repo,
      {Cluster.Supervisor, [topologies, [name: PresenceLab.ClusterSupervisor]]},
      {Phoenix.PubSub, name: PresenceLab.PubSub},
      # Start a worker by calling: PresenceLab.Worker.start_link(arg)
      # {PresenceLab.Worker, arg},
      # Start to serve requests, typically the last entry
      PresenceLabWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PresenceLab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PresenceLabWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
