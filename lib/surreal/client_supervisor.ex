defmodule Surreal.ClientSupervisor do
  @moduledoc """
  Supervisor for Client processes (SurrealDB conn + user info + channel (optinal))
  """
  use DynamicSupervisor
  alias Surreal.Client

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    DynamicSupervisor.start_child(__MODULE__, {Client, opts})
  end

  def stop_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
