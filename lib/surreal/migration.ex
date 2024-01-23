defmodule Surreal.Migration do
  defmacro __using__(id) do
    if String.length(id) != 14 || !Regex.run(~r/\d{14}/, id) do
      raise "ID needs to be a timestamp upto seconds (14 digits)"
    end

    # append 'a' char, so that SurrealDB creates normal looking IDs for migrations
    id = id <> "a"

    quote do
      alias Surreal.Rec
      alias Surreal.Repo
      alias Surreal.Res

      @id unquote(id)
      def id, do: @id

      def execute do
        if is_nil(migration_status()) do
          up()
          mark_as_run()
        end
      end

      def rollback do
        if migration_status() do
          down()
          mark_as_pending()
        end
      end

      ###### private ########

      defp recid do
        Rec.recid("migrations", id())
      end

      def migration_status do
        with {:ok, res} <- Repo.select(recid()) |> Res.res() do
          res
        end
      end

      defp mark_as_run do
        Repo.query("create migrations set id=$id, created = time::now();", %{id: id()})
      end

      defp mark_as_pending do
        Repo.delete(recid())
      end
    end
  end
end
