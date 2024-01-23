import path from "node:path"
import { GenBase } from "./GenBase";
import { lpad } from "./utils";
import dedent from "ts-dedent";

export class RepoGenerator extends GenBase {
  constructor() {
    super();
    this.generatorName = "gen/src/RepoGenerator.ts";
  }

  run() {
    this.logRun();
    this.addBanner("ex");
    this.push("defmodule Surreal.Repo do");
    this.withIndent(() => {
      this.genFrontStatic();
      this.genMethods();
      this.genQueryMethod();
      this.genAdminHelpers();
    });
    this.push("end");
    this.push("");
  }

  methodsCreate() {
    return ["create", "insert"]
  }
  methodsWithIdData() {
    return ["update", "merge", "patch"]
  }
  methodsWithId() {
    return ["select", "delete"]
  }

  genMethods() {
    this.methodsCreate().map(method => {
      this.genMethodCreation(method)
    })
    this.methodsWithIdData().map(method => {
      this.genMethodWithData(method)
    })
    this.methodsWithId().map(method => {
      this.genMethodWithId(method)
    })

  }
  genMethodWithData(name: string) {
    let methods = dedent`

        ${this.methodBanner(name)}

        ${this.variationChangesetCreation(name) + "\n"}
        ${this.variationModuleIdData(name) + "\n"}
        ${this.variationModuleData(name) + "\n"}
        ${this.variationBinaryThingData(name) + "\n"}
        `
    methods = lpad(methods, "  ")
    this.push(methods)
  }

  genMethodWithId(name: string) {
    let methods = dedent`

        ${this.methodBanner(name)}

        ${this.variationModuleId(name) + "\n"}
        ${this.variationModule(name) + "\n"}
        ${this.variationBinaryThing(name) + "\n"}
        `
    methods = lpad(methods, "  ")
    this.push(methods)
  }

  genMethodCreation(name: string) {
    let methods = dedent`

        ${this.methodBanner(name)}

        ${this.variationChangesetCreation(name) + "\n"}
        ${this.variationSchemaCreation(name) + "\n"}
        ${this.variationModuleIdData(name) + "\n"}
        ${this.variationModuleDataCreation(name) + "\n"}
        ${this.variationBinaryThingData(name) + "\n"}
        `
    methods = lpad(methods, "  ")
    this.push(methods)
  }

  methodBanner(name: string) {
    return dedent`

    ###
    ### ${name.toUpperCase()} #########
    ###
    `
  }

  variationChangesetCreation(name: string) {
    return dedent`
        # with changeset
        def ${name}(%Ecto.Changeset{} = changeset) do
          {module, data} = module_data_from_changeset(changeset)
          ${name}(module, data)
        end
        # with list of changesets
        def ${name}(changesets) when is_list(changesets) do
          {module, data} = module_data_from_changeset(changesets)
          ${name}(module, data)
        end
        `
  }
  variationSchemaCreation(name: string) {
    return dedent`
        # with ecto schema
        def ${name}(struct) when is_struct(struct) do
          ${name}(struct_to_changeset(struct))
        end
        `
  }
  variationBinaryThing(name: string) {
    return dedent`
        # with binary id
        def ${name}(thing) when is_binary(thing) do
          Surrealix.${name}(current_repo(), thing)
        end
        `
  }
  variationBinaryThingData(name: string) {
    return dedent`
        # with binary id / data (map)
        def ${name}(thing, data) when is_binary(thing) and is_map(data) do
          Surrealix.${name}(current_repo(), thing, data)
        end
        # with binary id / data (list)
        def ${name}(thing, data) when is_binary(thing) and is_list(data) do
          Surrealix.${name}(current_repo(), thing, data)
        end
        `
  }
  variationModule(name: string) {
    return dedent`
        # with module
        def ${name}(module) when is_atom(module) do
          ${name}(to_thing(module)) |> as(module)
        end
        `
  }
  variationModuleId(name: string) {
    return dedent`
        # with module / id
        def ${name}(module, id) when is_atom(module) do
          ${name}(to_thing(module, id)) |> as(module)
        end
        `
  }
  variationModuleIdData(name: string) {
    return dedent`
        # with module / id / data
        def ${name}(module, id, data) when is_atom(module) do
          ${name}(to_thing(module, id), data) |> as(module)
        end
        `
  }
  variationModuleDataCreation(name: string) {
    return dedent`
        # with module / data (create / insert) - single
        def ${name}(module, data) when is_atom(module) and is_map(data) do
          # For some reason we get an array, extract the first element
          ${name}(to_thing(module), data) |> Res.first() |> as(module)
        end

        # with module / data (create / insert) - list
        def ${name}(module, data) when is_atom(module) and is_list(data) do
          ${name}(to_thing(module), data) |> as(module)
        end
        `
  }
  variationModuleData(name: string) {
    return dedent`
        # with module / data (updates / changes) (map)
        def ${name}(module, data) when is_atom(module) and is_map(data) do
          ${name}(to_thing(module), data) |> as(module)
        end
        # with module / data (updates / changes) (list)
        def ${name}(module, data) when is_atom(module) and is_list(data) do
          ${name}(to_thing(module), data) |> as(module)
        end
        `
  }

  genQueryMethod() {
    let content = this.queryMethod()
    content = lpad(content, "  ")
    this.push(content)
  }

  queryMethod() {
    return dedent`

        ${this.methodBanner("query")}

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
        `
  }

  genFrontStatic() {
    let content = dedent`

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

        def live_query(sql, vars \\\\ %{}, callback) do
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
        `

    content = lpad(content, "  ")
    this.push(content)
  }

  genAdminHelpers() {
    let content = dedent`

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

        `

    content = lpad(content, "  ")
    this.push(content)
  }
}

const generator = new RepoGenerator();
generator.run();
// console.log(generator.content)
const me = path.join(import.meta.dir, "../..", "lib/surreal/repo.ex")
Bun.write(me, generator.content)