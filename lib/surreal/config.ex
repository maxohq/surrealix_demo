defmodule Surreal.Config do
  @moduledoc """
  Config for SurrealDB
  """
  def host, do: config_or_env(:host, "SURREALDB_HOST")
  def port, do: config_or_env(:host, "SURREALDB_PORT")
  def user, do: config_or_env(:user, "SURREALDB_USER")
  def pass, do: config_or_env(:pass, "SURREALDB_PASS")
  def ns, do: config_or_env(:ns, "SURREALDB_NS")
  def db, do: config_or_env(:db, "SURREALDB_DB")

  defp config_or_env(key, env_var) do
    Application.get_env(:surrealdb, key) || System.get_env(env_var) ||
      raise("COUND NOT LOAD #{env_var} from ENV or [:surrealdb, :#{key}] from config.exs!")
  end
end
