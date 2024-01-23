defmodule Maxo.Maybe do
  @moduledoc """
  Implementation of the Maybe monad, inspired by Rust's Option type.
  """

  @typedoc "Describe an empty Maybe monad."
  @type nothing :: :nothing

  @typedoc "Describe a Maybe monad containing some value."
  @type some :: {:some, any()}

  @typedoc "Describe a Maybe monad."
  @type t :: nothing() | some()

  @typedoc "Describe an Ok result."
  @type ok :: {:ok, any()}

  @typedoc "Describe an Error result."
  @type error :: {:error, any()}

  @typedoc "Describe a Result monad."
  @type result :: ok() | error()

  @doc "Returns an empty Maybe monad."
  @spec nothing() :: nothing()
  def nothing(), do: :nothing

  @doc "Encaspulate a value into a Maybe monad."
  @spec some(any()) :: some()
  def some(v), do: {:some, v}

  @doc """
  Check if a value is an empty Maybe monad.

      iex> Maxo.Maybe.nothing() |> Maxo.Maybe.is_nothing()
      true

      iex> Maxo.Maybe.some(1) |> Maxo.Maybe.is_nothing()
      false

      iex> 1 |> Maxo.Maybe.is_nothing()
      false
  """
  defguard is_nothing(v) when v == :nothing

  @doc """
  Check if a value is a non-empty Maybe monad.

      iex> Maxo.Maybe.nothing() |> Maxo.Maybe.is_some()
      false

      iex> Maxo.Maybe.some(1) |> Maxo.Maybe.is_some()
      true

      iex> 1 |> Maxo.Maybe.is_some()
      false
  """
  defguard is_some(v) when is_tuple(v) and elem(v, 0) == :some

  @doc """
  Check if a value is a Maybe monad.

      iex> Maxo.Maybe.nothing() |> Maxo.Maybe.is_maybe()
      true

      iex> Maxo.Maybe.some(1) |> Maxo.Maybe.is_maybe()
      true

      iex> 1 |> Maxo.Maybe.is_maybe()
      false
  """
  defguard is_maybe(v) when is_nothing(v) or is_some(v)

  @doc """
  Get the value of a Maybe monad or raise an exception if it were empty.

      iex> Maxo.Maybe.some(1) |> Maxo.Maybe.unwrap!()
      1
      iex> Maxo.Maybe.nothing() |> Maxo.Maybe.unwrap!()
      ** (ArgumentError) trying to unwrap an empty Maybe monad
  """
  @spec unwrap!(t()) :: any()
  def unwrap!({:some, value}), do: value

  def unwrap!(:nothing) do
    raise ArgumentError, message: "trying to unwrap an empty Maybe monad"
  end

  @doc """
  Get the value of a Maybe monad or a default value if it were empty.

      iex> Maxo.Maybe.some(1) |> Maxo.Maybe.unwrap_or(2)
      1
      iex> Maxo.Maybe.nothing() |> Maxo.Maybe.unwrap_or(2)
      2
  """
  @spec unwrap_or(t(), any()) :: any()
  def unwrap_or(:nothing, default_value), do: default_value
  def unwrap_or({:some, value}, _default_value), do: value

  @doc """
  Get the value of a Maybe monad or compute a default value if it were empty.

      iex> Maxo.Maybe.some(1) |> Maxo.Maybe.unwrap_or_else(fn -> 2 end)
      1
      iex> Maxo.Maybe.nothing() |> Maxo.Maybe.unwrap_or_else(fn -> 2 end)
      2
  """
  @spec unwrap_or_else(t(), (-> any())) :: any()
  def unwrap_or_else(:nothing, default_func), do: default_func.()
  def unwrap_or_else({:some, value}, _default_func), do: value

  @doc """
  Returns the Maybe monad contained in a Maybe monad, or nothing.

      iex> Maxo.Maybe.some(Maxo.Maybe.some(1))
      ...>   |> Maxo.Maybe.flatten()
      {:some, 1}

      iex> Maxo.Maybe.some(Maxo.Maybe.nothing())
      ...>   |> Maxo.Maybe.flatten()
      :nothing

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.flatten()
      :nothing
  """
  @spec flatten(t()) :: t()
  def flatten(:nothing), do: :nothing
  def flatten({:some, mval}) when is_maybe(mval), do: mval

  @doc """
  Boolean AND operation on 2 Maybe monads which returns the right one.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.and_other(Maxo.Maybe.some(2))
      {:some, 2}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.and_other(Maxo.Maybe.some(2))
      :nothing

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.and_other(Maxo.Maybe.nothing())
      :nothing
  """
  @spec and_other(t(), t()) :: t()
  def and_other(:nothing, _), do: :nothing
  def and_other({:some, _}, other_mval), do: other_mval

  @doc """
  Maps the value of a non-empty Maybe monad to a new Maybe monad.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.and_then(fn n -> Maxo.Maybe.some(n + 1) end)
      {:some, 2}

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.and_then(fn _ -> :nothing end)
      :nothing

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.and_then(fn n -> Maxo.Maybe.some(n + 1) end)
      :nothing
  """
  @spec and_then(t(), (any() -> t())) :: t()
  def and_then(:nothing, _), do: :nothing
  def and_then({:some, val}, func), do: func.(val)

  @doc """
  Boolean OR operation on 2 Maybe monads which returns the left one.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.or_other(Maxo.Maybe.some(2))
      {:some, 1}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.or_other(Maxo.Maybe.some(2))
      {:some, 2}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.or_other(Maxo.Maybe.nothing())
      :nothing
  """
  @spec or_other(t(), t()) :: t()
  def or_other(:nothing, other_mval), do: other_mval
  def or_other({:some, _} = mval, _), do: mval

  @doc """
  Returns the Maybe monad or execute a function returing a Maybe monad.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.or_else(fn -> Maxo.Maybe.some(2) end)
      {:some, 1}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.or_else(fn -> Maxo.Maybe.some(2) end)
      {:some, 2}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.or_else(fn -> Maxo.Maybe.nothing() end)
      :nothing
  """
  @spec or_else(t(), (-> t())) :: t()
  def or_else(:nothing, func), do: func.()
  def or_else({:some, _} = mval, _), do: mval

  @doc """
  Boolean XOR operation on 2 Maybe monad which returns some value if and only if
  one of them is non empty.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.xor_other(Maxo.Maybe.some(2))
      :nothing

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.xor_other(Maxo.Maybe.nothing())
      :nothing

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.xor_other(Maxo.Maybe.nothing())
      {:some, 1}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.xor_other(Maxo.Maybe.some(2))
      {:some, 2}
  """
  @spec xor_other(t(), t()) :: t()
  def xor_other(:nothing, :nothing), do: :nothing
  def xor_other({:some, _}, {:some, _}), do: :nothing
  def xor_other({:some, val}, :nothing), do: {:some, val}
  def xor_other(:nothing, {:some, val}), do: {:some, val}

  @doc """
  Apply a function to the value of a Maybe monad.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.map(fn n -> n + 1 end)
      {:some, 2}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.map(fn n -> n + 1 end)
      :nothing
  """
  @spec map(t(), (any() -> any())) :: t()
  def map(:nothing, _), do: :nothing
  def map({:some, val}, func), do: {:some, func.(val)}

  @doc """
  Return the default result for an empty Maybe monad, or Apply a function to
  its value and return the result.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.map_or(3, fn n -> n + 1 end)
      2

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.map_or(3, fn n -> n + 1 end)
      3
  """
  @spec map_or(t(), any(), (any() -> any())) :: any()
  def map_or(:nothing, default_val, _), do: default_val
  def map_or({:some, val}, _, func), do: func.(val)

  @doc """
  Compute the default result for an empty Maybe monad, or Apply a function to
  its value and return the result.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.map_or_else(fn -> 3 end, fn n -> n + 1 end)
      2

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.map_or_else(fn -> 3 end, fn n -> n + 1 end)
      3
  """
  @spec map_or_else(t(), (-> any()), (any() -> any())) :: any()
  def map_or_else(:nothing, default_func, _), do: default_func.()
  def map_or_else({:some, val}, _, func), do: func.(val)

  @doc """
  Returns the Maybe monad only if predicate returns true for its contained
  value.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.filter(fn n -> n > 0 end)
      {:some, 1}

      iex> Maxo.Maybe.some(-1)
      ...>   |> Maxo.Maybe.filter(fn n -> n > 0 end)
      :nothing

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.filter(fn n -> n > 0 end)
      :nothing
  """
  @spec filter(t(), (any() -> boolean())) :: t()
  def filter(:nothing, _), do: :nothing

  def filter({:some, val}, predicate) do
    if predicate.(val) do
      {:some, val}
    else
      :nothing
    end
  end

  @doc """
  Transform a Maybe monad into a Result monad, turning nothing into an error.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.ok_or(:no_value)
      {:ok, 1}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.ok_or(:no_value)
      {:error, :no_value}
  """
  @spec ok_or(t(), any()) :: result()
  def ok_or(:nothing, err), do: {:error, err}
  def ok_or({:some, val}, _), do: {:ok, val}

  @doc """
  Transform a Maybe monad into a Result monad turning nothing into a computed
  error.

      iex> Maxo.Maybe.some(1)
      ...>   |> Maxo.Maybe.ok_or_else(fn -> :no_value end)
      {:ok, 1}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.ok_or_else(fn -> :no_value end)
      {:error, :no_value}
  """
  @spec ok_or_else(t(), any()) :: result()
  def ok_or_else(:nothing, err_func), do: {:error, err_func.()}
  def ok_or_else({:some, val}, _), do: {:ok, val}

  @doc """
  Transform a Maybe monad containing a Result monad to a Result monad containing
  a Maybe monad.

      iex> Maxo.Maybe.some({:ok, 1})
      ...>   |> Maxo.Maybe.transpose()
      {:ok, {:some, 1}}

      iex> Maxo.Maybe.some(:ok)
      ...>   |> Maxo.Maybe.transpose()
      {:ok, {:some, nil}}

      iex> Maxo.Maybe.some({:error, :no_value})
      ...>   |> Maxo.Maybe.transpose()
      {:error, :no_value}

      iex> Maxo.Maybe.nothing()
      ...>   |> Maxo.Maybe.transpose()
      {:ok, :nothing}
  """
  @spec transpose(t()) :: result()
  def transpose(:nothing), do: {:ok, :nothing}
  def transpose({:some, :ok}), do: {:ok, {:some, nil}}
  def transpose({:some, {:ok, val}}), do: {:ok, {:some, val}}
  def transpose({:some, {:error, reason}}), do: {:error, reason}
end
