defmodule Surreal.PageMeta do
  defstruct first_idx: nil,
            last_idx: nil,
            curr_page: nil,
            prev_page: nil,
            next_page: nil,
            has_next: nil,
            has_prev: nil,
            total_count: nil,
            total_pages: nil
end

defmodule Surreal.Page do
  defstruct data: [], meta: %Surreal.PageMeta{}
end

defmodule Surreal.Pager do
  @moduledoc """
  Barebones query pagination without much abstractions
  """
  import Surreal.Query
  alias Surreal.Repo

  def paginate(query, nil, per_page) do
    paginate(query, 1, per_page)
  end

  def paginate(query, page, per_page) when is_nil(per_page) or per_page == "" do
    paginate(query, page, 50)
  end

  def paginate(query, page, per_page) do
    do_paginate(query, ensure_integer(page), ensure_integer(per_page))
  end

  defp do_paginate(query, page, per_page) do
    results = query(query, page, per_page: per_page)
    count = total_count(query)

    %Surreal.Page{
      data: Enum.slice(results, 0, per_page),
      meta: do_metadata(page, per_page, count)
    }
  end

  def do_metadata(page, per_page, total_count) do
    first = (page - 1) * per_page + 1
    last = Enum.min([page * per_page, total_count])
    has_next = total_count > page * per_page
    has_prev = page > 1
    total_pages = ceil(total_count / per_page)

    %Surreal.PageMeta{
      first_idx: first,
      last_idx: last,
      curr_page: page,
      prev_page: page - 1,
      next_page: page + 1,
      has_next: has_next,
      has_prev: has_prev,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  defp total_count(query) do
    q =
      query
      |> exclude(:select)
      |> exclude(:group)
      |> exclude(:order)
      |> exclude(:limit)
      |> select("count()")
      |> group("all")

    Repo.one!(q) |> Map.get("count")
  end

  def ensure_integer(str) when is_binary(str), do: String.to_integer(str)
  def ensure_integer(int) when is_integer(int), do: int

  defp query(query, page, per_page: per_page) do
    query
    |> limit(per_page)
    |> start(per_page * (page - 1))
    |> Repo.all!()
  end
end
