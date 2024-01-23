defmodule Surreal.Rec do
  @moduledoc false
  def recid(table, id) do
    "#{table}:#{wrap(id)}"
  end

  # Must put ⟨ and ⟩ around ID when it contains some shady chars, like `:`, or `-`
  def wrap(id) when is_binary(id) do
    cond do
      String.contains?(id, "-") -> "⟨#{id}⟩"
      String.contains?(id, ":") -> "⟨#{id}⟩"
      true -> id
    end
  end

  def wrap(id) when is_number(id), do: id
end
