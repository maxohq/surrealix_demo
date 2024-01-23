defmodule Surreal.Dumper do
  @moduledoc """
  Dumper for Ecto Changesets
  - Snippets from
    - https://github.com/elixir-ecto/ecto/blob/master/lib/ecto/repo/schema.ex (defp do_insert)


  TODO:
  - handle updates vs inserts differently
    # Differently from insert, update does not copy the struct
    # fields into the changeset. All changes must be in the
    # changeset before hand.
  """
  def from_changeset(changeset = %{valid?: true}) do
    changes = changeset.changes
    struct = struct_from_changeset!(:insert, changeset)
    schema = struct.__struct__
    dumper = schema.__schema__(:dump)
    {:ok, dump_changes!(:insert, changes, schema, dumper, Surreal.Adapter)}
  end

  def from_changeset(changeset = %{valid?: false}) do
    {:error, changeset.errors}
  end

  defp dump_changes!(action, changes, schema, dumper, adapter) do
    dump_fields!(action, schema, changes, dumper, adapter)
  end

  defp dump_fields!(action, schema, kw, dumper, adapter) do
    for {field, value} <- kw do
      {alias, type} = Map.fetch!(dumper, field)
      {alias, dump_field!(action, schema, field, type, value, adapter)}
    end
  end

  defp dump_field!(action, schema, field, type, value, adapter) do
    case Ecto.Type.adapter_dump(adapter, type, value) do
      {:ok, value} ->
        value

      :error ->
        raise Ecto.ChangeError,
              "value `#{inspect(value)}` for `#{inspect(schema)}.#{field}` " <>
                "in `#{action}` does not match type #{Ecto.Type.format(type)}"
    end
  end

  def struct_from_changeset!(action, %{data: nil}),
    do: raise(ArgumentError, "cannot #{action} a changeset without :data")

  def struct_from_changeset!(_action, %{data: struct}),
    do: struct

  def module_from_changeset!(action, %{} = chset) do
    struct = struct_from_changeset!(action, chset)
    struct.__struct__
  end
end
