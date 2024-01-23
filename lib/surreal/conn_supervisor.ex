defmodule Surreal.ConnSupervisor do
  @moduledoc """
  Supervisor for Surrealix websockex processes.
  Please use `Surreal.Conn` in userland code!
  """
  use DynamicSupervisor

  alias Surrealix.Socket
  alias Surreal.Conn

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child([world, user], opts \\ []) do
    DynamicSupervisor.start_child(__MODULE__, childspec([world, user], opts))
  end

  def stop_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def childspec([world, user], opts) do
    {Socket, opts ++ Conn.name([world, user])}
  end
end
