defmodule Surreal.QueryTest do
  use ExUnit.Case, async: true
  use MnemeDefaults
  alias Surreal.Query

  test "builds a simple query" do
    Query.new()
    |> Query.from("users")
    |> assert_query("select * from users")

    Query.new()
    |> Query.select("u.id, c.name")
    |> Query.select("u.created")
    |> Query.from("users u")
    |> Query.from("join clients c on u.client_id = c.id")
    |> assert_query("""
      select u.id, c.name, u.created
      from users u join clients c on u.client_id = c.id
    """)
  end

  test "group (by)" do
    Query.new()
    |> Query.from("x")
    |> Query.group("id")
    |> assert_query("select * from x group id")

    Query.new()
    |> Query.from("x")
    |> Query.group("1, id having count(*) > 1")
    |> assert_query("select * from x group 1, id having count(*) > 1")
  end

  test "order by" do
    Query.new()
    |> Query.from("x")
    |> Query.order("id desc")
    |> assert_query("select * from x order by id desc")
  end

  test "limit" do
    Query.new()
    |> Query.from("x")
    |> Query.where("status", :eq, "normal")
    |> Query.limit(5)
    |> assert_query("select * from x where status = $v1 limit 5", %{"v1" => "normal"})
  end

  test "start" do
    Query.new()
    |> Query.from("x")
    |> Query.limit(5)
    |> Query.start(5)
    |> assert_query("select * from x limit 5 start 5")
  end

  test "fetch" do
    Query.new()
    |> Query.from("x")
    |> Query.select("id, parent.*")
    |> Query.fetch("parent")
    |> assert_query("select id, parent.* from x fetch parent")
  end

  describe "where" do
    test "numeric comparison" do
      Query.new()
      |> Query.from("x")
      |> Query.where("a", :lte, 1)
      |> Query.where("b", :gte, 2)
      |> Query.where("c", :gt, 3)
      |> Query.where("d", :lt, 4)
      |> Query.where("e", :eq, 5)
      |> assert_query("select * from x where a <= $v1 and b >= $v2 and c > $v3 and d < $v4 and e = $v5", %{
        "v1" => 1,
        "v2" => 2,
        "v3" => 3,
        "v4" => 4,
        "v5" => 5
      })
    end

    test "mixed comparions" do
      Query.new()
      |> Query.from("x")
      |> Query.where("status", :eq, "normal")
      |> assert_query("select * from x where status = $v1", %{"v1" => "normal"})

      Query.new()
      |> Query.from("x")
      |> Query.where("deleted is null")
      |> Query.where("type", :ne, "monkey")
      |> Query.where("power", :gt, 9000)
      |> assert_query(
        """
        select * from x
        where deleted is null
          and type != $v1
          and power > $v2
        """,
        %{"v1" => "monkey", "v2" => 9000}
      )
    end
  end

  test "filter groups" do
    Query.new()
    |> Query.from("x")
    |> Query.where("a", :eq, 1)
    |> Query.where_or(fn q ->
      q
      |> Query.where("b", :lt, 2)
      |> Query.where("c", :gt, 3)
      |> Query.where_and(fn q ->
        q |> Query.where("d", :ne, 4) |> Query.where("e", :eq, 5)
      end)
    end)
    |> Query.where("f", :ne, 6)
    |> assert_query(
      """
      select * from x
      where a = $v1
        and (b < $v2 or c > $v3 or (d != $v4 and e = $v5))
        and f != $v6
      """,
      %{"v1" => 1, "v2" => 2, "v3" => 3, "v4" => 4, "v5" => 5, "v6" => 6}
    )
  end

  defp assert_query(q, expected_sql, expected_values \\ %{}) do
    {sql, values} = Query.to_sql(q)

    # normalize the spaces
    actual_sql =
      sql
      |> :erlang.iolist_to_binary()
      |> String.replace(~r/\s+/, " ")

    # normalize the spaces
    expected_sql =
      expected_sql
      |> String.replace(~r/\s+/, " ")
      |> String.trim()

    assert actual_sql == expected_sql
    assert values == expected_values
  end
end
