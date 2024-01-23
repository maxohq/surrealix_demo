defmodule Surreal.Conn do
  @moduledoc """
  Module to keep the logic symmetric with ClientSupervisor
  """
  alias Surreal.ConnSupervisor

  def get_pid([world, user], opts \\ []) do
    pid_name = pid_name([world, user])

    case :global.whereis_name(pid_name) do
      :undefined ->
        IO.puts("Surreal.Conn NOT FOUND: #{inspect(pid_name)}")
        ConnSupervisor.start_child([world, user], opts)

      pid ->
        {:ok, pid}
    end
  end

  def stop_pid([world, user]) do
    pid_name = pid_name([world, user])

    case :global.whereis_name(pid_name) do
      :undefined ->
        {:ok, :already_stopped}

      pid ->
        :ok = ConnSupervisor.stop_child(pid)
        {:ok, :stopped}
    end
  end

  def pid_name([world, user]), do: {:surreal_conn, world, user}
  def name([world, user]), do: [name: {:global, pid_name([world, user])}]
end
