defmodule Surreal.Result do
  alias Surreal.Converter

  def from_raw_query!({:error, %{"id" => _id, "error" => error}}) when is_map(error) do
    raise Jason.encode!(error)
  end

  def from_raw_query!({:ok, %{"id" => _id, "result" => result}}) do
    Enum.with_index(result) |> Enum.map(&flatten_subresult!/1)
  end

  def flatten_subresult!({%{"result" => result, "status" => "OK"}, _idx}) do
    result
  end

  def flatten_subresult!({%{"result" => result, "status" => "ERR"}, idx}) do
    raise "ERROR for query #{idx} : #{result}"
  end

  def from_raw_query({:error, %{"id" => _id, "error" => error}}) do
    {:error, error}
  end

  def from_raw_query({:ok, %{"id" => _id, "result" => result}}) do
    {:ok, Enum.map(result, &flatten_subresult/1)}
  end

  def flatten_subresult(%{"result" => result, "status" => "OK"}) do
    {:ok, result}
  end

  def flatten_subresult(%{"result" => result, "status" => "ERR"}) do
    {:error, result}
  end

  def as({:ok, result}, struct_module) when is_list(result) do
    Enum.map(result, fn x ->
      Converter.convert!(struct_module, x)
    end)
    |> ok()
  end

  def as({:ok, result}, struct_module) when is_map(result) do
    Converter.convert!(struct_module, result) |> ok()
  end

  # we have a result, but it is nil! (when deleting non-existing records)
  def as({:ok, result}, _struct_module) when is_nil(result) do
    ok(result)
  end

  # we have a plain value without result, just convert to struct
  def as({:ok, value}, struct_module) do
    ok(Converter.convert!(struct_module, value))
  end

  def as({:error, error}, _struct_module), do: {:error, error}

  # without ok / error tuples
  def as(result, struct_module) when is_map(result) do
    Converter.convert!(struct_module, result)
  end

  def as(result, struct_module) when is_list(result) do
    Enum.map(result, fn x ->
      Converter.convert!(struct_module, x)
    end)
  end

  def ok(res), do: {:ok, res}
end
