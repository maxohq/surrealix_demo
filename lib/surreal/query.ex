defmodule Surreal.Query do
  # - https://www.openmymind.net/Elixir-Without-Ecto-Dynamic-Queries/
  alias __MODULE__

  defstruct from: [],
            select: nil,
            group: nil,
            order: nil,
            limit: nil,
            start: nil,
            fetch: nil,
            op: " and ",
            where: nil,
            values: %{},
            value_count: 0

  def new() do
    %Query{}
  end

  # first select we add shouldn't be prefixed with a comma
  def select(%{select: nil} = q, select), do: %Query{q | select: [select]}
  # subsequent selects should be prefixed with a comma
  def select(q, select), do: %Query{q | select: [q.select, ", ", select]}

  def from(q, from), do: %Query{q | from: [q.from, " ", from]}

  # first group we add shouldn't be prefixed with a comma
  def group(%{group: nil} = q, group), do: %Query{q | group: [group]}
  # subsequent groups should be prefixed with a comma
  def group(q, group), do: %Query{q | group: [q.group, ", ", group]}

  # first order we add shouldn't be prefixed with a comma
  def order(%{order: nil} = q, order), do: %Query{q | order: [order]}
  # subsequent orders should be prefixed with a comma
  def order(q, order), do: %Query{q | order: [q.order, ", ", order]}

  def limit(q, limit), do: %Query{q | limit: limit}

  def start(q, start), do: %Query{q | start: start}

  # first fetch we add shouldn't be prefixed with a comma
  def fetch(%{fetch: nil} = q, fetch), do: %Query{q | fetch: [fetch]}
  # subsequent fetchs should be prefixed with a comma
  def fetch(q, fetch), do: %Query{q | fetch: [q.fetch, ", ", fetch]}

  def exclude(q, key) do
    default = new() |> Map.get(key)
    Map.put(q, key, default)
  end

  # for things like Query.where(q, "deleted is null")
  def where(q, predicate), do: add_where(q, predicate)

  def where(q, left, :eq, value) do
    {q, placeholder} = add_value(q, value)
    add_where(q, [left, " = ", placeholder])
  end

  def where(q, left, :ne, value) do
    {q, placeholder} = add_value(q, value)
    add_where(q, [left, " != ", placeholder])
  end

  def where(q, left, :gt, value) do
    {q, placeholder} = add_value(q, value)
    add_where(q, [left, " > ", placeholder])
  end

  def where(q, left, :gte, value) do
    {q, placeholder} = add_value(q, value)
    add_where(q, [left, " >= ", placeholder])
  end

  def where(q, left, :lt, value) do
    {q, placeholder} = add_value(q, value)
    add_where(q, [left, " < ", placeholder])
  end

  def where(q, left, :lte, value) do
    {q, placeholder} = add_value(q, value)
    add_where(q, [left, " <= ", placeholder])
  end

  def where_or(q, fun), do: where_fun(q, fun, " or ")
  def where_and(q, fun), do: where_fun(q, fun, " and ")

  defp where_fun(q, fun, op) do
    restore_op = q.op

    existing =
      case q.where do
        nil -> []
        where -> [where, q.op]
      end

    q = fun.(%Query{q | op: op, where: nil})
    %Query{q | op: restore_op, where: [existing, "(", q.where, ")"]}
  end

  # Adds the value to our query and returns the placeholder (e.g. $1) to use
  # in the SQL. We're only using this for where, but it can be used in any
  # part of the query where we want to inject a value/placeholder.
  def add_value(q, value) do
    count = q.value_count + 1
    values = Map.put(q.values, varname(count), value)
    q = %Query{q | values: values, value_count: count}
    {q, placeholder(count)}
  end

  defp add_where(%{where: nil} = q, predicate), do: %Query{q | where: [predicate]}
  defp add_where(q, predicate), do: %Query{q | where: [q.where, q.op, predicate]}

  def to_sql(q) do
    ## https://docs.surrealdb.com/docs/surrealql/statements/select
    sql = ["select ", q.select || "*", " from", q.from]

    ### WHERE
    sql =
      case q.where do
        nil -> sql
        where -> [sql, " where ", where]
      end

    ### GROUP
    sql =
      case q.group do
        nil -> sql
        group -> [sql, " group ", group]
      end

    ### ORDER
    sql =
      case q.order do
        nil -> sql
        order -> [sql, " order by ", order]
      end

    ### LIMIT
    sql =
      case q.limit do
        nil ->
          sql

        limit ->
          [sql, " limit ", "#{limit}"]
      end

    ### START
    sql =
      case q.start do
        nil ->
          sql

        start ->
          [sql, " start ", "#{start}"]
      end

    ### FETCH
    sql =
      case q.fetch do
        nil -> sql
        fetch -> [sql, " fetch ", fetch]
      end

    {sql, q.values}
  end

  def to_raw_sql(q) do
    {sql, vars} = to_sql(q)
    sql = sql |> :erlang.iolist_to_binary()
    {sql, vars}
  end

  # pre-generate 100 placehoders, so we end up with;
  #   defp placeholder(1), do: "$1"
  #   defp placeholder(2), do: "$2"
  #   defp placeholder(100), do: "$100"
  for i <- 1..100 do
    s = "$v#{i}"
    defp placeholder(unquote(i)), do: unquote(s)
  end

  # fall back to dynamically creating a placeholder
  defp placeholder(i), do: "$v#{i}"

  # pre-generate 100 varnames, same as placeholder, just without the `$` char
  for i <- 1..100 do
    s = "v#{i}"
    defp varname(unquote(i)), do: unquote(s)
  end

  # fall back to dynamically creating a varname
  defp varname(i), do: "v#{i}"
end
