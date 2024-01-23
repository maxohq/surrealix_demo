## **** GENERATED CODE! see gen/src/RepoGenerator.ts for details. ****

defmodule Surreal.Repo do
  alias Surreal.Config
  alias Surreal.Rec
  alias Surreal.Res

  require Logger

  @default_repo [0, 0]

  def start_link([]) do
    init()
  end

  def init() do
    with {:ok, pid} <- Surreal.Conn.get_pid(@default_repo, init_opts()) do
      Surrealix.wait_until_auth_ready(pid)
      {:ok, pid}
    end
  end

  defp init_opts do
    [
      hostname: Config.host(),
      port: Config.port(),
      on_auth: fn pid, _state ->
        IO.puts("PID: #{inspect(pid)}")
        Surrealix.signin(pid, %{user: Config.user(), pass: Config.pass()})
        Surrealix.use(pid, Config.ns(), Config.db())
      end
    ]
  end

  ### API ###

  def as(res, struct_module) do
    Res.as(res, struct_module)
  end

  def live_query(sql, vars \\ %{}, callback) do
    Surrealix.live_query(current_repo(), sql, vars, callback)
  end

  ###
  ### QUERY STRUCT
  ###
  alias Surreal.Query

  def all(%Query{} = q) do
    {sql, vars} = Query.to_raw_sql(q)

    # unwraps nested response from SurrealDB without raising on errors
    query(sql, vars)
    |> Surreal.Result.from_raw_query()
    |> Maxo.Result.map(&Enum.at(&1, 0))
    |> Maxo.Result.flatten()
  end

  def all!(%Query{} = q) do
    all(q) |> Maxo.Result.unwrap!()
  end

  def one!(%Query{} = q) do
    all!(q) |> Enum.at(0)
  end

  ###
  ### CREATE #########
  ###

  # with changeset
  def create(%Ecto.Changeset{} = changeset) do
    {module, data} = module_data_from_changeset(changeset)
    create(module, data)
  end

  # with list of changesets
  def create(changesets) when is_list(changesets) do
    {module, data} = module_data_from_changeset(changesets)
    create(module, data)
  end

  # with ecto schema
  def create(struct) when is_struct(struct) do
    create(struct_to_changeset(struct))
  end

  # with module / id / data
  def create(module, id, data) when is_atom(module) do
    create(to_thing(module, id), data) |> as(module)
  end

  # with module / data (create / insert) - single
  def create(module, data) when is_atom(module) and is_map(data) do
    # For some reason we get an array, extract the first element
    create(to_thing(module), data) |> Res.first() |> as(module)
  end

  # with module / data (create / insert) - list
  def create(module, data) when is_atom(module) and is_list(data) do
    create(to_thing(module), data) |> as(module)
  end

  # with binary id / data (map)
  def create(thing, data) when is_binary(thing) and is_map(data) do
    Surrealix.create(current_repo(), thing, data)
  end

  # with binary id / data (list)
  def create(thing, data) when is_binary(thing) and is_list(data) do
    Surrealix.create(current_repo(), thing, data)
  end

  ###
  ### INSERT #########
  ###

  # with changeset
  def insert(%Ecto.Changeset{} = changeset) do
    {module, data} = module_data_from_changeset(changeset)
    insert(module, data)
  end

  # with list of changesets
  def insert(changesets) when is_list(changesets) do
    {module, data} = module_data_from_changeset(changesets)
    insert(module, data)
  end

  # with ecto schema
  def insert(struct) when is_struct(struct) do
    insert(struct_to_changeset(struct))
  end

  # with module / id / data
  def insert(module, id, data) when is_atom(module) do
    insert(to_thing(module, id), data) |> as(module)
  end

  # with module / data (create / insert) - single
  def insert(module, data) when is_atom(module) and is_map(data) do
    # For some reason we get an array, extract the first element
    insert(to_thing(module), data) |> Res.first() |> as(module)
  end

  # with module / data (create / insert) - list
  def insert(module, data) when is_atom(module) and is_list(data) do
    insert(to_thing(module), data) |> as(module)
  end

  # with binary id / data (map)
  def insert(thing, data) when is_binary(thing) and is_map(data) do
    Surrealix.insert(current_repo(), thing, data)
  end

  # with binary id / data (list)
  def insert(thing, data) when is_binary(thing) and is_list(data) do
    Surrealix.insert(current_repo(), thing, data)
  end

  ###
  ### UPDATE #########
  ###

  # with changeset
  def update(%Ecto.Changeset{} = changeset) do
    {module, data} = module_data_from_changeset(changeset)
    update(module, data)
  end

  # with list of changesets
  def update(changesets) when is_list(changesets) do
    {module, data} = module_data_from_changeset(changesets)
    update(module, data)
  end

  # with module / id / data
  def update(module, id, data) when is_atom(module) do
    update(to_thing(module, id), data) |> as(module)
  end

  # with module / data (updates / changes) (map)
  def update(module, data) when is_atom(module) and is_map(data) do
    update(to_thing(module), data) |> as(module)
  end

  # with module / data (updates / changes) (list)
  def update(module, data) when is_atom(module) and is_list(data) do
    update(to_thing(module), data) |> as(module)
  end

  # with binary id / data (map)
  def update(thing, data) when is_binary(thing) and is_map(data) do
    Surrealix.update(current_repo(), thing, data)
  end

  # with binary id / data (list)
  def update(thing, data) when is_binary(thing) and is_list(data) do
    Surrealix.update(current_repo(), thing, data)
  end

  ###
  ### MERGE #########
  ###

  # with changeset
  def merge(%Ecto.Changeset{} = changeset) do
    {module, data} = module_data_from_changeset(changeset)
    merge(module, data)
  end

  # with list of changesets
  def merge(changesets) when is_list(changesets) do
    {module, data} = module_data_from_changeset(changesets)
    merge(module, data)
  end

  # with module / id / data
  def merge(module, id, data) when is_atom(module) do
    merge(to_thing(module, id), data) |> as(module)
  end

  # with module / data (updates / changes) (map)
  def merge(module, data) when is_atom(module) and is_map(data) do
    merge(to_thing(module), data) |> as(module)
  end

  # with module / data (updates / changes) (list)
  def merge(module, data) when is_atom(module) and is_list(data) do
    merge(to_thing(module), data) |> as(module)
  end

  # with binary id / data (map)
  def merge(thing, data) when is_binary(thing) and is_map(data) do
    Surrealix.merge(current_repo(), thing, data)
  end

  # with binary id / data (list)
  def merge(thing, data) when is_binary(thing) and is_list(data) do
    Surrealix.merge(current_repo(), thing, data)
  end

  ###
  ### PATCH #########
  ###

  # with changeset
  def patch(%Ecto.Changeset{} = changeset) do
    {module, data} = module_data_from_changeset(changeset)
    patch(module, data)
  end

  # with list of changesets
  def patch(changesets) when is_list(changesets) do
    {module, data} = module_data_from_changeset(changesets)
    patch(module, data)
  end

  # with module / id / data
  def patch(module, id, data) when is_atom(module) do
    patch(to_thing(module, id), data) |> as(module)
  end

  # with module / data (updates / changes) (map)
  def patch(module, data) when is_atom(module) and is_map(data) do
    patch(to_thing(module), data) |> as(module)
  end

  # with module / data (updates / changes) (list)
  def patch(module, data) when is_atom(module) and is_list(data) do
    patch(to_thing(module), data) |> as(module)
  end

  # with binary id / data (map)
  def patch(thing, data) when is_binary(thing) and is_map(data) do
    Surrealix.patch(current_repo(), thing, data)
  end

  # with binary id / data (list)
  def patch(thing, data) when is_binary(thing) and is_list(data) do
    Surrealix.patch(current_repo(), thing, data)
  end

  ###
  ### SELECT #########
  ###

  # with module / id
  def select(module, id) when is_atom(module) do
    select(to_thing(module, id)) |> as(module)
  end

  # with module
  def select(module) when is_atom(module) do
    select(to_thing(module)) |> as(module)
  end

  # with binary id
  def select(thing) when is_binary(thing) do
    Surrealix.select(current_repo(), thing)
  end

  ###
  ### DELETE #########
  ###

  # with module / id
  def delete(module, id) when is_atom(module) do
    delete(to_thing(module, id)) |> as(module)
  end

  # with module
  def delete(module) when is_atom(module) do
    delete(to_thing(module)) |> as(module)
  end

  # with binary id
  def delete(thing) when is_binary(thing) do
    Surrealix.delete(current_repo(), thing)
  end

  ###
  ### QUERY #########
  ###

  def query(sql) when is_binary(sql) do
    query(sql, %{})
  end

  def query(sql, vars) when is_binary(sql) and is_map(vars) do
    Logger.info("SQL: #{inspect(sql)}, #{inspect(vars)}")
    Surrealix.query(current_repo(), sql, vars)
  end

  def query(module, sql) when is_atom(module) and is_binary(sql) do
    query(module, sql, %{})
  end

  def query(module, sql, vars) when is_atom(module) and is_binary(sql) and is_map(vars) do
    query(sql, vars) |> Res.first() |> as(module)
  end

  ###
  ### Admin API #########
  ###

  def current_repo() do
    dynamic_repo() || default_repo()
  end

  def dynamic_repo do
    Maxo.ProcDict.get_with_ancestors(:surreal_repo)
  end

  def default_repo do
    Surreal.Conn.get_pid(@default_repo) |> Res.ok()
  end

  def put_dynamic_repo(pid) do
    Maxo.ProcDict.put(:surreal_repo, pid)
  end

  defp to_thing(module) do
    extract_table_name(module)
  end

  defp to_thing(module, id) do
    Rec.recid(extract_table_name(module), id)
  end

  defp extract_table_name(module) do
    # workaround to make sure the module is properly loaded (sometimes it is not loaded yet)
    Code.ensure_compiled(module)

    cond do
      has_function(module, :__table__, 0) -> module.__table__()
      has_function(module, :__schema__, 1) -> module.__schema__(:source)
      true -> raise "NOT POSSIBLE TO MAP #{module}"
    end
  end

  defp module_data_from_changeset(changesets) when is_list(changesets) and length(changesets) > 0 do
    module = Surreal.Dumper.module_from_changeset!(:insert, Enum.at(changesets, 0))
    data_list = Enum.map(changesets, &get_data_chset/1)
    {module, data_list}
  end

  defp module_data_from_changeset(changeset) do
    module = Surreal.Dumper.module_from_changeset!(:insert, changeset)
    data = get_data_chset(changeset)
    {module, data}
  end

  def struct_to_changeset(struct) do
    schema = struct.__struct__
    fullchanges = Map.take(struct, schema.__schema__(:fields))
    Ecto.Changeset.change(struct(schema), fullchanges)
  end

  def get_data_chset(chset) do
    {:ok, data} = Surreal.Dumper.from_changeset(chset)
    Enum.into(data, %{})
  end

  defp has_function(mod, fun, arity) do
    Kernel.function_exported?(mod, fun, arity)
  end
end
