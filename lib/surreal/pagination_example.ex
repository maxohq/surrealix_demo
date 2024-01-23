defmodule Surreal.PaginationExample do
  alias Surreal.Query
  alias Surreal.Repo

  def run(opts \\ []) do
    Query.new()
    |> Query.from("jiraissue")
    |> Query.select("id, updated")
    |> Query.order("id desc")
    |> TokenOperator.maybe(opts, :limit, &maybe_set_limit/2, defaults: [limit: 5])
    |> TokenOperator.maybe(opts, :paginate, &maybe_paginate/2, defaults: [paginate: false, page: 1, per_page: 20])
  end

  defp maybe_set_limit(query, %{limit: limit}) do
    Query.limit(query, limit)
  end

  defp maybe_paginate(query, %{paginate: true, page: page, per_page: per_page}) do
    Surreal.Pager.paginate(query, page, per_page)
  end

  defp maybe_paginate(query, _opts) do
    Repo.all!(query)
  end
end
