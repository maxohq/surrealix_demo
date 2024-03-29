defmodule SurrealixDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SurrealixDemoWeb.Telemetry,
      SurrealixDemo.Repo,
      {DNSCluster, query: Application.get_env(:surrealix_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SurrealixDemo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SurrealixDemo.Finch},
      # Start a worker by calling: SurrealixDemo.Worker.start_link(arg)
      # {SurrealixDemo.Worker, arg},

      ## For SurrealDB
      {Surreal.ClientSupervisor, []},
      {Surreal.ConnSupervisor, []},
      %{id: Surreal.Repo, start: {Surreal.Repo, :start_link, [[]]}},

      # Start to serve requests, typically the last entry
      SurrealixDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SurrealixDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SurrealixDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
