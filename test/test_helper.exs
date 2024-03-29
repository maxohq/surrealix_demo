ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SurrealixDemo.Repo, :manual)
Mneme.start(restart: true)

defmodule MnemeDefaults do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      use Mneme, action: :accept, default_pattern: :last, force_update: false
    end
  end
end

defmodule TestSupport do
  @moduledoc false
  use ExUnit.Case

  def extract_res({:ok, res}) do
    Map.get(res, "result")
  end

  def extract_res({:ok, res}, index) do
    extract_res({:ok, res}) |> Enum.at(index) |> Map.get("result")
  end

  def extract_res_list({:ok, res}) do
    result = Map.get(res, "result")

    result
    |> Enum.map(fn x ->
      {:ok, Map.get(x, "result")}
    end)
  end

  def setup_surrealix(_context) do
    db = db_name()
    # NOT start_link(), so we can cleanup after test exits!
    # {:ok, pid} = Surrealix.start(debug: [:trace]) ## this is for debugging!
    {:ok, pid} = Surrealix.start()
    Surrealix.signin(pid, %{user: "root", pass: "root"})
    Surrealix.use(pid, "test", db)

    # NOW we set the Repo to use this new DB connection!
    Surreal.Repo.put_dynamic_repo(pid)

    on_exit(:drop_db, fn ->
      _res = Surrealix.query(pid, "remove database #{db};")
      Surrealix.stop(pid)
    end)

    %{pid: pid}
  end

  def db_name() do
    rand =
      :crypto.strong_rand_bytes(6)
      |> Base.encode64()

    "test_#{Regex.replace(~r/\W/, rand, "")}"
  end
end
