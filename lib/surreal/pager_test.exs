defmodule Surreal.PagerTest do
  use ExUnit.Case
  use MnemeDefaults
  alias Surreal.Pager

  describe "do_metadata - per_page: 1" do
    test "page: 1, per_page: 1, total: 10" do
      meta = Pager.do_metadata(1, 1, 10)

      auto_assert(
        %{
          curr_page: 1,
          first_idx: 1,
          has_next: true,
          has_prev: false,
          last_idx: 1,
          next_page: 2,
          prev_page: 0,
          total_count: 10,
          total_pages: 10
        } <- meta
      )
    end

    test "page: 9, per_page: 1, total: 10" do
      meta = Pager.do_metadata(9, 1, 10)

      auto_assert(
        %{
          curr_page: 9,
          first_idx: 9,
          has_next: true,
          has_prev: true,
          last_idx: 9,
          next_page: 10,
          prev_page: 8,
          total_count: 10,
          total_pages: 10
        } <- meta
      )
    end

    test "page: 10, per_page: 1, total: 10" do
      meta = Pager.do_metadata(10, 1, 10)

      auto_assert(
        %{
          curr_page: 10,
          first_idx: 10,
          has_next: false,
          has_prev: true,
          last_idx: 10,
          next_page: 11,
          prev_page: 9,
          total_count: 10,
          total_pages: 10
        } <- meta
      )
    end

    test "page: 11, per_page: 1, total: 10" do
      meta = Pager.do_metadata(11, 1, 10)

      auto_assert(
        %{
          curr_page: 11,
          first_idx: 11,
          has_next: false,
          has_prev: true,
          last_idx: 10,
          next_page: 12,
          prev_page: 10,
          total_count: 10,
          total_pages: 10
        } <- meta
      )
    end
  end

  describe "do_metadata - per_page: 2" do
    test "page: 1, per_page: 2, total: 10" do
      meta = Pager.do_metadata(1, 2, 10)

      auto_assert(
        %{
          curr_page: 1,
          first_idx: 1,
          has_next: true,
          has_prev: false,
          last_idx: 2,
          next_page: 2,
          prev_page: 0,
          total_count: 10,
          total_pages: 5
        } <- meta
      )
    end

    test "page: 4, per_page: 2, total: 10" do
      meta = Pager.do_metadata(4, 2, 10)

      auto_assert(
        %{
          curr_page: 4,
          first_idx: 7,
          has_next: true,
          has_prev: true,
          last_idx: 8,
          next_page: 5,
          prev_page: 3,
          total_count: 10,
          total_pages: 5
        } <- meta
      )
    end

    test "page: 5, per_page: 1, total: 10" do
      meta = Pager.do_metadata(5, 2, 10)

      auto_assert(
        %{
          curr_page: 5,
          first_idx: 9,
          has_next: false,
          has_prev: true,
          last_idx: 10,
          next_page: 6,
          prev_page: 4,
          total_count: 10,
          total_pages: 5
        } <- meta
      )
    end

    test "page: 6, per_page: 2, total: 10" do
      meta = Pager.do_metadata(6, 2, 10)

      auto_assert(
        %{
          curr_page: 6,
          first_idx: 11,
          has_next: false,
          has_prev: true,
          last_idx: 10,
          next_page: 7,
          prev_page: 5,
          total_count: 10,
          total_pages: 5
        } <- meta
      )
    end
  end
end
