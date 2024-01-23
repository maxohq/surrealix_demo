### https://github.com/oestrich/grapevine/blob/44e47a141db6d06550a242d3a303cf207a9e49dc/lib/grapevine/telnet/web_client.ex

defmodule Surreal.Client do
  @moduledoc false
  alias Surreal.ClientSupervisor
  use GenServer, restart: :transient
  require Logger

  def get_pid([world, user]) do
    pid_name = pid_name([world, user])

    case :global.whereis_name(pid_name) do
      :undefined ->
        Logger.debug("Surreal.Client starting child - #{inspect(pid_name)}")
        ClientSupervisor.start_child([world, user])

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
        :ok = ClientSupervisor.stop_child(pid)
        {:ok, :stopped}
    end
  end

  def start_link([world, user]) do
    GenServer.start_link(__MODULE__, [world, user], name: {:global, pid_name([world, user])})
  end

  def pid_name([world, user]) do
    {:surreal_client, world, user}
  end

  def init([world, user]) do
    {:ok, %{world: world, user: user}}
  end
end
