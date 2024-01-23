defmodule Maxo.MapTransform do
  # from https://github.com/olafura/map_transform/blob/master/lib/map_transform.ex
  @moduledoc """
  This is a simple library that can transform one map into another through
  mapping rules.
  """

  @type path :: nonempty_list(term)
  @type mapping :: {path, path} | {path, path, (term -> term)}

  @doc """
  Transform one map into another.


  ## Format for mappings

  For the paths is the standard that `get_in/2` and `put_in/2` use.
  For example to get data from `c` in `%{a: %{b: %{c: 1}}}` you would provide
  `[:a, :b, :c]` as the path.

  Then we'll use these paths in the mapping in a list of tuples where:

      {from_path, to_path}
      {from_path, to_path, &transform_function/1}


  ## Example

  Basic

      iex> mapping = [
      ...>   {[:a, :b, :c], [:abc]}
      ...> ]
      ...> source = %{a: %{b: %{c: 1}}}
      ...> transform(source, mapping)
      %{abc: 1}


  String keys and using a transform function

      iex> mapping = [
      ...>   {["a", "b", "c"], [:abc], &String.to_integer/1}
      ...> ]
      ...> source = %{"a" => %{"b" => %{"c" => "1"}}}
      ...> transform(source, mapping)
      %{abc: 1}


  Any nesting

      iex> mapping = [
      ...>   {[:a, :b, :c], [:foo, :bar]}
      ...> ]
      ...> source = %{a: %{b: %{c: 1}}}
      ...> transform(source, mapping)
      %{foo: %{bar: 1}}

  """
  @spec transform(map, [mapping]) :: map
  def transform(source, mapping) do
    base_map = base_map_from_mapping(mapping)

    mapping
    |> Enum.reduce(base_map, &do_transform(&1, &2, source))
  end

  defp do_transform({from_path, to_path}, acc, source) do
    do_transform({from_path, to_path, & &1}, acc, source)
  end

  defp do_transform({from_path, to_path, function}, acc, source) do
    put_in(acc, to_path, source |> get_in(from_path) |> function.())
  end

  defp base_map_from_mapping(mapping) do
    mapping
    |> Enum.map(&elem(&1, 1))
    |> base_map()
  end

  defp base_map(paths) do
    paths
    |> Enum.reduce(%{}, &do_base_map/2)
  end

  defp do_base_map([], _acc) do
    nil
  end

  defp do_base_map([last], acc) do
    Map.put(acc, last, nil)
  end

  defp do_base_map([key | rest], acc) do
    Map.put(acc, key, do_base_map(rest, %{}))
  end
end
