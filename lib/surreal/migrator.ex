defmodule Surreal.Migrator do
  @moduledoc """
  A simple migrator module for SurrealDB migrations.

  For patterns mixing data / DDL changes see following discussion:
    - https://discuss.rubyonrails.org/t/patterns-for-data-only-rails-migrations/75320/22
  """
  def execute do
    files()
    |> Enum.map(fn module ->
      module.execute()
    end)
  end

  def rollback(amount \\ 1) do
    files()
    ## must to be in reverse order!
    |> Enum.reverse()
    |> Enum.take(amount)
    |> Enum.map(fn module ->
      module.rollback()
    end)
  end

  @doc """
  By convention all modules that start with "Surreal.Migrations" are considered migrations.
  """
  def files do
    with {:ok, list} <- :application.get_key(:surrealix_demo, :modules) do
      list
      |> Enum.filter(&(&1 |> Module.split() |> Enum.take(2) == ["Surreal", "Migrations"]))
      |> Enum.sort()
    end
  end
end
