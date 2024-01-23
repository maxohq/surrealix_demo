defmodule Mix.Tasks.Surreal.Migrate do
  use Mix.Task
  @shortdoc "Run Surreal migrations"
  @switches [
    all: :boolean,
    step: :integer,
    to: :integer,
    quiet: :boolean,
    log_level: :string
  ]

  @moduledoc """
  Runs the pending surreal migrations

  ## Examples

      $ mix surreal.migrate

      # with debug logging
      $ mix surreal.migrate --log-level=debug
  """

  @impl true
  def run(args) do
    # NEEDED TO LOAD config/runtime.exs file!
    Mix.Task.run("app.config")
    {opts, _} = OptionParser.parse!(args, strict: @switches)

    # default logging level to info
    Logger.configure(level: :info)

    if log_level = opts[:log_level] do
      Logger.configure(level: String.to_existing_atom(log_level))
    end

    # Boot the whole app, otherweise SurrealDB has troubles
    {:ok, _} = Application.ensure_all_started(:vecufy)

    res = Surreal.Migrator.execute()
    if log_level == "debug", do: IO.inspect(res, label: "migration response")
    :ok
  end
end
