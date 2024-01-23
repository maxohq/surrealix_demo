defmodule Surreal.ResultTest do
  use ExUnit.Case
  use MnemeDefaults

  @ok_result_list %{"status" => "OK", "time" => "408.125µs", "result" => [%{"id" => "user:1", "name" => "Jack"}]}
  @ok_result_value %{"status" => "OK", "time" => "408.125µs", "result" => 1000}
  @error_result %{
    "result" => "Cannot perform addition with 'NONE' and 'NONE'",
    "status" => "ERR",
    "time" => "20.5µs"
  }

  def ok_top_result_single(inner) do
    {:ok, %{"id" => "xxx", "result" => [inner]}}
  end

  def ok_top_result_multi(inner) when is_list(inner) do
    {:ok, %{"id" => "xxx", "result" => inner}}
  end

  def error_top_result(_inner) do
    {:error,
     %{
       "error" => %{
         "code" => -32000,
         "message" =>
           "There was a problem with the database: Parse error: Failed to parse query at line 1 column 10 expected FROM\n  |\n1 | select * rom jiraproject;\n  |         ^ \n"
       },
       "id" => "xxx"
     }}
  end

  describe "from_raw_query" do
    test "list - 1 item" do
      raw = ok_top_result_single(@ok_result_list)
      a = Surreal.Result.from_raw_query(raw)
      auto_assert({:ok, ok: [%{"id" => "user:1", "name" => "Jack"}]} <- a)
    end

    test "list - multiple items" do
      raw = ok_top_result_multi([@ok_result_list, @ok_result_list, @ok_result_value])
      a = Surreal.Result.from_raw_query(raw)
      auto_assert({:ok, ok: [%{"id" => "user:1", "name" => "Jack"}], ok: [%{"id" => "user:1", "name" => "Jack"}], ok: 1000} <- a)
    end

    test "list - multiple items - with errors" do
      raw = ok_top_result_multi([@ok_result_list, @error_result, @ok_result_value])
      a = Surreal.Result.from_raw_query(raw)

      auto_assert(
        {:ok, ok: [%{"id" => "user:1", "name" => "Jack"}], error: "Cannot perform addition with 'NONE' and 'NONE'", ok: 1000} <- a
      )
    end

    test "value" do
      raw = ok_top_result_single(@ok_result_value)
      a = Surreal.Result.from_raw_query(raw)
      auto_assert({:ok, ok: 1000} <- a)
    end

    test "top result error" do
      raw = error_top_result([])

      auto_assert(
        {:error,
         %{
           "code" => -32000,
           "message" => """
           There was a problem with the database: Parse error: Failed to parse query at line 1 column 10 expected FROM
             |
           1 | select * rom jiraproject;
             |         ^ 
           """
         }} <- Surreal.Result.from_raw_query(raw)
      )
    end
  end

  describe "from_raw_query!" do
    test "list - 1 item" do
      raw = ok_top_result_single(@ok_result_list)
      a = Surreal.Result.from_raw_query!(raw)
      auto_assert([[%{"id" => "user:1", "name" => "Jack"}]] <- a)
    end

    test "list - multiple items" do
      raw = ok_top_result_multi([@ok_result_list, @ok_result_list, @ok_result_value])
      a = Surreal.Result.from_raw_query!(raw)
      auto_assert([[%{"id" => "user:1", "name" => "Jack"}], [%{"id" => "user:1", "name" => "Jack"}], 1000] <- a)
    end

    test "list - multiple items - with errors - raises!" do
      raw = ok_top_result_multi([@ok_result_list, @error_result, @ok_result_value])

      auto_assert_raise(
        RuntimeError,
        "ERROR for query 1 : Cannot perform addition with 'NONE' and 'NONE'",
        fn ->
          Surreal.Result.from_raw_query!(raw)
        end
      )
    end

    test "value" do
      raw = ok_top_result_single(@ok_result_value)
      a = Surreal.Result.from_raw_query!(raw)
      auto_assert([1000] <- a)
    end

    test "top result error" do
      raw = error_top_result([])

      auto_assert_raise(
        RuntimeError,
        "{\"code\":-32000,\"message\":\"There was a problem with the database: Parse error: Failed to parse query at line 1 column 10 expected FROM\\n  |\\n1 | select * rom jiraproject;\\n  |         ^ \\n\"}",
        Surreal.Result.from_raw_query!(raw)
      )
    end
  end
end
