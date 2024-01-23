defmodule Surreal.Adapter do
  @moduledoc """
  Ecto Adapter module for SurrealDB (very barebones)

  - adaptation from
    - https://github.com/elixir-sqlite/ecto_sqlite3/blob/main/lib/ecto/adapters/sqlite3.ex
    with much less code (used only for type conversion now)
  """

  alias Surreal.Codec

  def autogenerate(:id), do: nil
  def autogenerate(:embed_id), do: Ecto.UUID.generate()

  def autogenerate(:binary_id) do
    case Application.get_env(:surrealix, :binary_id_type, :string) do
      :string -> Ecto.UUID.generate()
      :binary -> Ecto.UUID.bingenerate()
    end
  end

  ##
  ## Loaders
  ##

  @default_datetime_type :iso8601
  def loaders(:boolean, type) do
    [&Codec.bool_decode/1, type]
  end

  def loaders(:naive_datetime_usec, type) do
    [&Codec.naive_datetime_decode/1, type]
  end

  def loaders(:time, type) do
    [&Codec.time_decode/1, type]
  end

  def loaders(:utc_datetime_usec, type) do
    [&Codec.utc_datetime_decode/1, type]
  end

  def loaders(:utc_datetime, type) do
    [&Codec.utc_datetime_decode/1, type]
  end

  def loaders(:naive_datetime, type) do
    [&Codec.naive_datetime_decode/1, type]
  end

  def loaders(:date, type) do
    [&Codec.date_decode/1, type]
  end

  def loaders({:map, _}, type) do
    [&Codec.json_decode/1, &Ecto.Type.embedded_load(type, &1, :json)]
  end

  def loaders({:array, _}, type) do
    [&Codec.json_decode/1, type]
  end

  def loaders(:map, type) do
    [&Codec.json_decode/1, type]
  end

  def loaders(:float, type) do
    [&Codec.float_decode/1, type]
  end

  def loaders(:decimal, type) do
    [&Codec.decimal_decode/1, type]
  end

  def loaders(:binary_id, type) do
    case Application.get_env(:surrealix, :binary_id_type, :string) do
      :string -> [type]
      :binary -> [Ecto.UUID, type]
    end
  end

  def loaders(:uuid, type) do
    case Application.get_env(:surrealix, :uuid_type, :string) do
      :string -> []
      :binary -> [type]
    end
  end

  def loaders(_, type) do
    [type]
  end

  ##
  ## Dumpers
  ##
  def dumpers(:binary, type) do
    [type, &Codec.blob_encode/1]
  end

  def dumpers(:boolean, type) do
    [type, &Codec.bool_encode/1]
  end

  def dumpers(:decimal, type) do
    [type, &Codec.decimal_encode/1]
  end

  def dumpers(:binary_id, type) do
    case Application.get_env(:surrealix, :binary_id_type, :string) do
      :string -> [type]
      :binary -> [type, Ecto.UUID]
    end
  end

  def dumpers(:uuid, type) do
    case Application.get_env(:surrealix, :uuid_type, :string) do
      :string -> []
      :binary -> [type]
    end
  end

  def dumpers(:time, type) do
    [type, &Codec.time_encode/1]
  end

  def dumpers(:utc_datetime, type) do
    dt_type = Application.get_env(:surrealix, :datetime_type, @default_datetime_type)
    [type, &Codec.utc_datetime_encode(&1, dt_type)]
  end

  def dumpers(:utc_datetime_usec, type) do
    dt_type = Application.get_env(:surrealix, :datetime_type, @default_datetime_type)
    [type, &Codec.utc_datetime_encode(&1, dt_type)]
  end

  def dumpers(:naive_datetime, type) do
    dt_type = Application.get_env(:surrealix, :datetime_type, @default_datetime_type)
    [type, &Codec.naive_datetime_encode(&1, dt_type)]
  end

  def dumpers(:naive_datetime_usec, type) do
    dt_type = Application.get_env(:surrealix, :datetime_type, @default_datetime_type)
    [type, &Codec.naive_datetime_encode(&1, dt_type)]
  end

  def dumpers({:array, _}, type) do
    [type, &Codec.json_encode/1]
  end

  def dumpers({:map, _}, type) do
    [&Ecto.Type.embedded_dump(type, &1, :json), &Codec.json_encode/1]
  end

  def dumpers(:map, type) do
    [type, &Codec.json_encode/1]
  end

  def dumpers(_primitive, type) do
    [type]
  end
end
