defmodule Surreal.RepoTest do
  use ExUnit.Case, async: true
  import TestSupport
  use MnemeDefaults
  alias Surreal.Repo

  defmodule User do
    def __table__, do: "user"
    @moduledoc false
    use Construct do
      field(:id, :string, default: "")
      field(:name, :string, default: "")
      field(:email, :string, default: "")
    end
  end

  describe "Create" do
    setup [:setup_surrealix]

    test "create with id works" do
      {:ok, rec} = Repo.create(User, 1, %{name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec)
    end

    test "create without id works" do
      {:ok, rec} = Repo.create(User, %{name: "John"})
      assert Map.get(rec, :__struct__) == User
      assert rec.name == "John"
    end

    test "create with conficts works" do
      {:ok, _rec1} = Repo.create(User, 1, %{name: "John"})
      {:error, error} = Repo.create(User, 1, %{name: "John"})

      assert Map.get(error, "error") == %{
               "code" => -32_000,
               "message" => "There was a problem with the database: Database record `user:1` already exists"
             }
    end
  end

  describe "Insert" do
    setup [:setup_surrealix]

    test "insert with single record that has id works" do
      {:ok, rec} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec)
    end

    test "insert with multipe records that have id works" do
      {:ok, rec} = Repo.insert(User, [%{id: 1, name: "John"}, %{id: 2, name: "Mike"}])
      auto_assert([%User{id: "user:1", name: "John"}, %User{id: "user:2", name: "Mike"}] <- rec)
    end

    test "insert with multipe conflicting records that have id works (returns the first created record multiple times)" do
      {:ok, rec} =
        Repo.insert(User, [%{id: 1, name: "John"}, %{id: 1, name: "Mike"}, %{id: 1, name: "Jack"}])

      auto_assert([%User{id: "user:1", name: "John"}, %User{id: "user:1", name: "John"}, %User{id: "user:1", name: "John"}] <- rec)
    end

    test "insert with empty payload works" do
      {:ok, rec} =
        Repo.insert(User, %{})

      assert rec.id != nil
      assert rec.name == ""
      assert rec.email == ""
    end
  end

  describe "Update" do
    setup [:setup_surrealix]

    test "update with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.update(User, 1, %{name: "Jack"})
      auto_assert(%User{id: "user:1", name: "Jack"} <- rec2)
    end

    test "update without ID works (updates ALL records) -> returns updated records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.update(User, %{name: "Mike"})
      auto_assert([%User{id: "user:1", name: "Mike"}, %User{id: "user:2", name: "Mike"}] <- rec)
    end

    test "update with non-existing ID works - creates a new record with that ID" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.update(User, 3, %{name: "Mike"})
      auto_assert(%User{id: "user:3", name: "Mike"} <- rec)
    end
  end

  describe "Merge" do
    setup [:setup_surrealix]

    test "merge with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.merge(User, 1, %{email: "a@foo.com"})
      auto_assert(%User{email: "a@foo.com", id: "user:1", name: "John"} <- rec2)
    end

    test "merge without ID works (updates ALL records) -> returns updated records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.merge(User, %{email: "a@foo.com"})

      auto_assert(
        [
          %User{email: "a@foo.com", id: "user:1", name: "John"},
          %User{email: "a@foo.com", id: "user:2", name: "Jack"}
        ] <- rec
      )
    end

    test "merge with non-existing ID works - creates a new record with that ID" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.merge(User, 3, %{name: "Mike"})
      auto_assert(%User{id: "user:3", name: "Mike"} <- rec)
    end
  end

  describe "Patch" do
    setup [:setup_surrealix]

    test "patch with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.patch(User, 1, [%{op: "replace", path: "/email", value: "a@foo.com"}])
      auto_assert(%User{email: "a@foo.com", id: "user:1", name: "John"} <- rec2)
    end

    test "patch without ID works (updates ALL records) -> returns updated records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.patch(User, [%{op: "replace", path: "/email", value: "b@foo.com"}])

      auto_assert(
        [
          %User{email: "b@foo.com", id: "user:1", name: "John"},
          %User{email: "b@foo.com", id: "user:2", name: "Jack"}
        ] <- rec
      )
    end

    test "patch with non-existing ID fails" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:error, error} =
        Repo.merge(User, 3, [%{op: "replace", path: "/email", value: "b@foo.com"}])

      auto_assert(
        %{
          "code" => -32_000,
          "message" => "There was a problem with the database: Found [NONE] for the id field, but a specific record has been specified"
        } <- Map.get(error, "error")
      )
    end
  end

  describe "Delete" do
    setup [:setup_surrealix]

    test "delete with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.delete(User, 1)
      auto_assert(%User{id: "user:1", name: "John"} <- rec2)
      {:ok, rec3} = Repo.delete(User, 1)
      auto_assert(nil <- rec3)
    end

    test "delete without ID works (deletes ALL records) -> returns deleted records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.delete(User)

      auto_assert([%User{id: "user:1", name: "John"}, %User{id: "user:2", name: "Jack"}] <- rec)

      {:ok, rec2} = Repo.delete(User)
      auto_assert([] <- rec2)
    end

    test "delete with non-existing ID works - returns nil" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.delete(User, 3)
      auto_assert(nil <- rec)
    end
  end

  describe "Select" do
    setup [:setup_surrealix]

    test "select with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.select(User, 1)
      auto_assert(%User{id: "user:1", name: "John"} <- rec2)
    end

    test "select without ID works (selects ALL records) -> be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})
      {:ok, rec} = Repo.select(User)

      auto_assert([%User{id: "user:1", name: "John"}, %User{id: "user:2", name: "Jack"}] <- rec)
    end

    test "select with non-existing ID works - returns nil" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.select(User, 3)
      auto_assert(nil <- rec)
    end
  end

  describe "Query" do
    setup [:setup_surrealix]

    test "query works for lists" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.query(User, "select * from user")
      auto_assert([%User{id: "user:1", name: "John"}] <- rec2)

      {:ok, rec3} = Repo.query(User, "select * from nothing")
      auto_assert([] <- rec3)
    end

    test "query works for updates" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{id: "user:1", name: "John"} <- rec1)

      {:ok, rec2} = Repo.query(User, "update user:1 set name = $name", %{name: "Jack"})
      auto_assert([%User{id: "user:1", name: "Jack"}] <- rec2)
    end
  end
end
