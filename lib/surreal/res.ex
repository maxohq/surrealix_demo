defmodule Surreal.Res do
  @moduledoc """
  Module to unwrap the response from SurrealDB
  """
  alias Maxo.Result

  def first_res(result) do
    first(result) |> res()
  end

  def first(result) do
    at(result, 0)
  end

  def at({:error, error}, _idx) do
    {:error, error}
  end

  def at({:ok, %{"result" => result}}, idx) when is_list(result) do
    {:ok, Enum.at(result, idx)}
  end

  def res({:ok, %{"result" => nil}}) do
    {:ok, nil}
  end

  def res({:ok, %{"result" => result}}) do
    {:ok, result}
  end

  def res({:error, error}) do
    {:error, error}
  end

  def ok({:ok, val}), do: val

  def as({:ok, %{"result" => result}}, struct_module) when is_list(result) do
    Enum.map(result, fn x ->
      convert!(struct_module, x)
    end)
    |> Result.ok()
  end

  def as({:ok, %{"result" => result}}, struct_module) when is_map(result) do
    convert!(struct_module, result) |> Result.ok()
  end

  # we have a result, but it is nil! (when deleting non-existing records)
  def as({:ok, %{"result" => result}}, _struct_module) when is_nil(result) do
    Result.ok(result)
  end

  # we have a plain value without result, just convert to struct
  def as({:ok, value}, struct_module) do
    Result.ok(convert!(struct_module, value))
  end

  def as({:error, error}, _struct_module), do: {:error, error}

  defp convert!(struct_module, value) do
    cond do
      has_function(struct_module, :__table__, 0) -> convert_constructor(struct_module, value)
      has_function(struct_module, :__schema__, 1) -> convert_ecto(struct_module, value)
      true -> raise "NOT POSSIBLE TO MAP #{struct_module}"
    end
  end

  defp convert_constructor(struct_module, value) do
    struct_module.make!(value)
  end

  defp convert_ecto(struct_module, value) do
    attr_list = ecto_fields(struct_module)

    Ecto.Changeset.cast(struct(struct_module), value, attr_list)
    |> Map.put(:action, :insert)
    |> Ecto.Changeset.apply_action(:insert)
    |> Result.unwrap!()
  end

  defp ecto_fields(module) do
    module.__schema__(:dump) |> Map.keys()
  end

  defp has_function(mod, fun, arity) do
    Kernel.function_exported?(mod, fun, arity)
  end
end
