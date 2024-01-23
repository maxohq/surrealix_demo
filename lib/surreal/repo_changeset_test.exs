# TODO:

# - insert for list with changesets @done
# - update with changeset (overwrites all other fields?)
# - merge with changeset (merges with them?)

# STRUCT
#     - insert with struct
#     - insert with struct list
#     - update with struct
#     - merge with struct

defmodule Surreal.RepoChangesetTest do
  use ExUnit.Case, async: true
  import TestSupport
  use MnemeDefaults
  alias Surreal.Repo

  defmodule User do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: false}
    schema "user" do
      field(:name, :string, default: "")
      field(:email, :string, default: "")
      timestamps(type: :utc_datetime)
    end

    @doc false
    def changeset(comment, attrs) do
      comment
      |> cast(attrs, [:name, :email, :updated_at, :id])
      |> validate_required([:name, :email])
    end
  end

  describe "Create with changeset" do
    setup [:setup_surrealix]

    test "create with id works" do
      chset = User.changeset(%User{}, %{id: "john", name: "John", email: "a@a.com"})
      {:ok, rec} = Repo.create(chset)
      auto_assert(%User{email: "a@a.com", name: "John"} <- rec)
      assert rec.id == "user:john"
    end

    test "create without id works" do
      chset = User.changeset(%User{}, %{name: "John", email: "a@a.com"})
      {:ok, rec} = Repo.create(chset)
      assert Map.get(rec, :__struct__) == User
      assert rec.name == "John"
    end

    test "create with conficts works" do
      chset = User.changeset(%User{}, %{id: "user:1", name: "John", email: "a@a.com"})
      {:ok, _rec1} = Repo.create(chset)
      {:error, error} = Repo.create(chset)

      assert Map.get(error, "error") == %{
               "code" => -32_000,
               "message" => "There was a problem with the database: Database record `user:1` already exists"
             }
    end
  end

  describe "Insert with changeset" do
    setup [:setup_surrealix]

    test "insert with single record that has id works" do
      chset = User.changeset(%User{}, %{id: "user:1", name: "John", email: "a@a.com"})
      {:ok, rec} = Repo.insert(chset)

      expected = %User{
        id: "user:1",
        name: "John",
        email: "a@a.com"
      }

      assert expected == rec

      {:ok, rec1} = Repo.select(User, 1)
      auto_assert(%User{name: "John"} <- rec1)

      assert rec1.id == "user:1"
    end

    test "insert with multipe records that have id works" do
      chset1 = User.changeset(%User{}, %{id: "user:1", name: "John", email: "a@a.com"})
      chset2 = User.changeset(%User{}, %{id: "user:2", name: "Mike", email: "b@a.com"})
      {:ok, rec} = Repo.insert([chset1, chset2])
      auto_assert([%User{email: "a@a.com", name: "John"}, %User{email: "b@a.com", name: "Mike"}] <- rec)
    end

    test "insert with multipe conflicting records that have id works (returns the first created record multiple times)" do
      {:ok, rec} =
        Repo.insert(User, [%{id: 1, name: "John"}, %{id: 1, name: "Mike"}, %{id: 1, name: "Jack"}])

      auto_assert([%User{name: "John"}, %User{name: "John"}, %User{name: "John"}] <- rec)
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
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.update(User, 1, %{name: "Jack"})
      auto_assert(%User{name: "Jack"} <- rec2)
    end

    test "update without ID works (updates ALL records) -> returns updated records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.update(User, %{name: "Mike"})
      auto_assert([%User{name: "Mike"}, %User{name: "Mike"}] <- rec)
    end

    test "update with non-existing ID works - creates a new record with that ID" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.update(User, 3, %{name: "Mike"})
      auto_assert(%User{name: "Mike"} <- rec)
      auto_assert("user:3" <- rec.id)
    end
  end

  describe "Merge" do
    setup [:setup_surrealix]

    test "merge with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.merge(User, 1, %{email: "a@foo.com"})

      auto_assert(%User{email: "a@foo.com", name: "John"} <- rec2)
      auto_assert("user:1" <- rec2.id)
    end

    test "merge without ID works (updates ALL records) -> returns updated records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.merge(User, %{email: "a@foo.com"})

      auto_assert([%User{email: "a@foo.com", name: "John"}, %User{email: "a@foo.com", name: "Jack"}] <- rec)
    end

    test "merge with non-existing ID works - creates a new record with that ID" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.merge(User, 3, %{name: "Mike"})
      auto_assert(%User{name: "Mike"} <- rec)
    end
  end

  describe "Patch" do
    setup [:setup_surrealix]

    test "patch with ID works" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.patch(User, 1, [%{op: "replace", path: "/email", value: "a@foo.com"}])

      auto_assert(%User{email: "a@foo.com", name: "John"} <- rec2)
    end

    test "patch without ID works (updates ALL records) -> returns updated records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.patch(User, [%{op: "replace", path: "/email", value: "b@foo.com"}])

      auto_assert([%User{email: "b@foo.com", name: "John"}, %User{email: "b@foo.com", name: "Jack"}] <- rec)
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
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.delete(User, 1)
      auto_assert(%User{name: "John"} <- rec2)
      {:ok, rec3} = Repo.delete(User, 1)
      auto_assert(nil <- rec3)
    end

    test "delete without ID works (deletes ALL records) -> returns deleted records, be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})

      {:ok, rec} = Repo.delete(User)

      auto_assert([%User{name: "John"}, %User{name: "Jack"}] <- rec)

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
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.select(User, 1)
      auto_assert(%User{name: "John"} <- rec2)
    end

    test "select without ID works (selects ALL records) -> be careful!" do
      {:ok, _} = Repo.insert(User, %{id: 1, name: "John"})
      {:ok, _} = Repo.insert(User, %{id: 2, name: "Jack"})
      {:ok, rec} = Repo.select(User)

      auto_assert([%User{name: "John"}, %User{name: "Jack"}] <- rec)
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
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.query(User, "select * from user")
      auto_assert([%User{name: "John"}] <- rec2)

      {:ok, rec3} = Repo.query(User, "select * from nothing")
      auto_assert([] <- rec3)
    end

    test "query works for updates" do
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John"})
      auto_assert(%User{name: "John"} <- rec1)

      {:ok, rec2} = Repo.query(User, "update user:1 set name = $name", %{name: "Jack"})
      auto_assert([%User{name: "Jack"}] <- rec2)
    end
  end

  describe "Casting: date" do
    setup [:setup_surrealix]

    test "works for insert / query" do
      now = DateTime.utc_now(:second)
      {:ok, rec1} = Repo.insert(User, %{id: 1, name: "John", updated_at: DateTime.utc_now()})
      assert %User{name: "John", updated_at: ^now} = rec1

      {:ok, rec2} = Repo.query(User, "select * from user")
      assert [%User{name: "John", updated_at: ^now}] = rec2
    end
  end
end
