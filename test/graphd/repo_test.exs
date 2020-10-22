defmodule Graphd.RepoTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Graphd.{Geo, TestHelper, TestRepo, User}

  setup_all do
    {:ok, pid} = TestRepo.start_link(TestHelper.opts())
    TestRepo.drop_all()
    TestRepo.register(User)
    TestRepo.alter_schema()
    %{pid: pid}
  end

  describe "set/2" do
    test "create with primitive type predicate" do
      {_user, uid} = create_user(%User{name: "Alice", age: 25})

      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = TestRepo.get(uid)
    end

    test "create with primitive type predicate (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Alice", age: 25}, [:name, :age])
      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = TestRepo.get(uid)
    end

    test "create with custom type predicate" do
      {_user, uid} =
        create_user(%User{name: "John", age: 19, location: %Geo{lat: -33.8688, lon: 151.2093}})

      assert {:ok,
              %User{
                uid: ^uid,
                name: "John",
                age: 19,
                location: %Geo{lat: -33.8688, lon: 151.2093}
              }} = TestRepo.get(uid)
    end

    test "create with custom type predicate (using changesets)" do
      changeset =
        Changeset.cast(
          %User{},
          %{name: "John", age: 19, location: %Geo{lat: -33.8688, lon: 151.2093}},
          [:name, :age, :location]
        )

      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok,
              %User{
                uid: ^uid,
                name: "John",
                age: 19,
                location: %Geo{lat: -33.8688, lon: 151.2093}
              }} = TestRepo.get(uid)
    end

    test "create including edge nodes" do
      {friend, _} = create_user(%User{name: "Evan"})
      {_user, uid} = create_user(%User{name: "Mike", age: 53, friends: [friend]})

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, friends: [^friend]}} =
               TestRepo.get(uid)
    end

    test "create including edge nodes (using changesets)" do
      {friend, _} = create_user(%User{name: "Dean"})

      changeset =
        Changeset.cast(%User{}, %{name: "Mike", age: 53, friends: [friend]}, [
          :name,
          :age,
          :friends
        ])

      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, friends: [^friend]}} =
               TestRepo.get(uid)
    end

    test "update predicates with new values" do
      {_user, uid} =
        create_user(%User{name: "Peter", age: 17, location: %Geo{lat: 15.5, lon: 10.2}})

      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.get(uid)

      updated_user = %User{uid: uid, name: "Fred", age: 21, location: %Geo{lat: 15.5, lon: 10.2}}
      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)

      assert {:ok, %User{uid: ^uid, name: "Fred", age: 21, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.get(uid)
    end

    test "update predicates with new values (using changesets)" do
      {user, uid} =
        create_user(%User{name: "Peter", age: 17, location: %Geo{lat: 15.5, lon: 10.2}})

      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.get(uid)

      changeset =
        Changeset.cast(
          user,
          %{name: "Fred", age: 21, location: %Geo{lat: 15.5, lon: 10.2}},
          [
            :name,
            :age,
            :location
          ]
        )

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)

      assert {:ok, %User{uid: ^uid, name: "Fred", age: 21, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.get(uid)
    end

    test "update while omitting some values does not modify or delete it" do
      {_user, uid} = create_user(%User{name: "Pearl", age: 13})

      assert {:ok, %User{uid: ^uid, name: "Pearl", age: 13}} = TestRepo.get(uid)

      updated_user = %User{uid: uid, age: 21}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)
      assert {:ok, %User{uid: ^uid, name: "Pearl", age: 21}} = TestRepo.get(uid)
    end

    test "update while omitting some values does not modify or delete it (using changesets)" do
      {user, uid} = create_user(%User{name: "Pearl", age: 13})

      assert {:ok, %User{uid: ^uid, name: "Pearl", age: 13}} = TestRepo.get(uid)

      changeset =
        Changeset.cast(
          user,
          %{age: 21},
          [:age]
        )

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)
      assert {:ok, %User{uid: ^uid, name: "Pearl", age: 21}} = TestRepo.get(uid)
    end

    test "updating predicate with nil value does not modify or delete it" do
      {_user, uid} = create_user(%User{name: "Peter", age: 17})

      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17}} = TestRepo.get(uid)

      updated_user = %User{uid: uid, name: "Peter", age: nil}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)
      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17}} = TestRepo.get(uid)
    end

    test "updating predicate with nil value does not modify or delete it (using changesets)" do
      {user, uid} = create_user(%User{name: "Peter", age: 17})

      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17}} = TestRepo.get(uid)

      changeset =
        Changeset.cast(
          user,
          %{age: nil},
          [:age]
        )

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)
      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17}} = TestRepo.get(uid)
    end

    test "updating edge to add a new value inserts the new value into the list" do
      {friend1, _} = create_user(%User{name: "Jane"})
      {friend2, _} = create_user(%User{name: "Louise"})
      {_user, uid} = create_user(%User{name: "Paul", age: 17, friends: [friend1]})

      updated_user = %User{uid: uid, name: "Paul", age: 17, friends: [friend2]}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, friends: [^friend1, ^friend2]}} =
               TestRepo.get(uid)
    end

    test "updating edge to add a new value inserts the new value into the list (using changesets)" do
      {friend1, _} = create_user(%User{name: "Jane"})
      {friend2, _} = create_user(%User{name: "Louise"})
      {user, uid} = create_user(%User{name: "Paul", age: 17, friends: [friend1]})

      changeset = Changeset.cast(user, %{friends: [friend2]}, [:friends])

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, friends: [^friend1, ^friend2]}} =
               TestRepo.get(uid)
    end
  end

  describe "delete/2" do
    test "deleting deletes the whole thing not just a predicate or edge" do
      {user, uid} = create_user(%User{name: "Norman", age: 52})

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(user)
      assert {:ok, nil} = TestRepo.get(uid)
    end
  end

  describe "update/2" do
    test "updating a value" do
      {_user, uid} = create_user(%User{name: "Indie", age: 42})

      mutations = %User{uid: uid, age: 43}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{mutations: mutations})
      assert {:ok, %User{uid: ^uid, name: "Indie", age: 43}} = TestRepo.get(uid)
    end

    test "updating a value (using changesets)" do
      {user, uid} = create_user(%User{name: "Indie", age: 42})

      changeset = Changeset.cast(user, %{age: 43}, [:age])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Indie", age: 43}} = TestRepo.get(uid)
    end

    test "updating a value to nil" do
      {_user, uid} = create_user(%User{name: "Indie", nickname: "Genius"})

      deletions = %User{uid: uid, nickname: "Genius"}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Indie", nickname: nil}} = TestRepo.get(uid)
    end

    test "updating a value to nil (using changesets)" do
      {user, uid} = create_user(%User{name: "Indie", nickname: "Genius"})

      changeset = Changeset.cast(user, %{nickname: nil}, [:nickname])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Indie", nickname: nil}} = TestRepo.get(uid)
    end

    test "updating one value and niling another" do
      {_user, uid} = create_user(%User{name: "Jones", nickname: "Mother", age: 84})

      mutations = %User{uid: uid, nickname: "Old Mother"}
      deletions = %User{uid: uid, age: 84}

      assert {:ok, %{queries: %{}, uids: %{}}} =
               TestRepo.update(%{mutations: mutations, deletions: deletions})

      assert {:ok, %User{uid: ^uid, name: "Jones", nickname: "Old Mother", age: nil}} =
               TestRepo.get(uid)
    end

    test "updating one value and niling another (using changesets)" do
      {user, uid} = create_user(%User{name: "Jones", nickname: "Mother", age: 84})

      changeset = Changeset.cast(user, %{nickname: "Old Mother", age: nil}, [:age, :nickname])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)

      assert {:ok, %User{uid: ^uid, name: "Jones", nickname: "Old Mother", age: nil}} =
               TestRepo.get(uid)
    end

    test "updating a single edge node to nil" do
      {friend, _} = create_user(%User{name: "Deidre"})
      {_user, uid} = create_user(%User{name: "Frank", friends: [friend]})

      deletions = %User{uid: uid, friends: [friend]}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list's contents (using changesets) does not work" do
      {friend, _} = create_user(%User{name: "Deidre"})
      {user, uid} = create_user(%User{name: "Frank", friends: [friend]})

      changeset = Changeset.cast(user, %{friends: []}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: [^friend]}} = TestRepo.get(uid)
    end

    test "niling a list's contents (using changesets) does work" do
      {friend, _} = create_user(%User{name: "Deidre"})
      {user, uid} = create_user(%User{name: "Frank", friends: [friend]})

      changeset = Changeset.cast(user, %{friends: nil}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating one of multiple edge nodes to nil" do
      {friend1, _} = create_user(%User{name: "Deidre"})
      {friend2, _} = create_user(%User{name: "Mick"})
      {_user, uid} = create_user(%User{name: "Frank", friends: [friend1, friend2]})

      deletions = %User{uid: uid, friends: [friend2]}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: [friend1]}} = TestRepo.get(uid)
    end
  end

  describe "create/2" do
    test "creating a record" do
      user = %User{name: "Ben", email: "ben@email.com"}

      assert {:ok, %User{uid: uid}} = TestRepo.create(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    end

    test "creating a record with a node-edge" do
      {friend, _} = create_user(%User{name: "Deidre"})
      user = %User{name: "Ben", email: "ben@email.com", friends: [friend]}

      assert {:ok, %User{uid: uid}} = TestRepo.create(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    end

    test "creating a record (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Ben", email: "ben@email.com"}, [:name, :email])

      assert {:ok, %User{uid: uid}} = TestRepo.create(changeset)
      assert uid != nil
      assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    end

    test "creating a record fails when uid is passed" do
      {user, _uid} = create_user(%User{name: "Ben", email: "ben@email.com"})

      assert {:error, _} = TestRepo.create(user)
    end

    test "creating a record fails when uid is passed (using changesets)" do
      {user, _uid} = create_user(%User{name: "Ben", email: "ben@email.com"})
      changeset = Changeset.cast(user, %{name: "Ben", email: "ben@email.com"}, [:name, :email])

      assert {:error, _} = TestRepo.create(changeset)
    end
  end

  describe "schema operations" do
    test "basic crud operations" do
      user = %User{name: "Alice", age: 25}
      assert {:ok, %User{uid: uid}} = TestRepo.set(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = TestRepo.get(uid)
      assert %User{uid: ^uid, name: "Alice", age: 25} = TestRepo.get!(uid)

      assert {:ok, %{"uid_get" => [%User{uid: ^uid, name: "Alice", age: 25}]}} =
               TestRepo.all("{uid_get(func: uid(#{uid})) {uid dgraph.type expand(_all_)}}")

      assert {:ok, %{"uid_get" => [%{"uid" => _, "user.age" => 25, "user.name" => "Alice"}]}} =
               TestRepo.all("{uid_get(func: uid(#{uid})) {uid expand(_all_)}}")

      invalid_changeset = Ecto.Changeset.cast(%User{}, %{name: 20, age: "Bernard"}, [:name, :age])
      assert {:error, %Ecto.Changeset{valid?: false}} = TestRepo.set(invalid_changeset)

      valid_changeset = Ecto.Changeset.cast(%User{}, %{name: "Bernard", age: 20}, [:name, :age])
      assert {:ok, %{uid: uid2}} = TestRepo.set(valid_changeset)

      assert uid != nil
      assert uid2 != nil
      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(%{uid: uid})
      assert {:ok, nil} = TestRepo.get(uid)
      assert %{queries: %{}, uids: %{}} = TestRepo.delete!(%{uid: uid2})
      assert {:ok, nil} = TestRepo.get(uid2)
    end

    test "using custom types" do
      changes = %{name: "John", age: 30, location: %{lat: 15.5, lon: 10.2}}
      changeset = Changeset.cast(%User{}, changes, [:name, :age, :location])

      assert {:ok, %User{uid: uid, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.set(changeset)

      assert {:ok, %User{location: %Geo{lat: 15.5, lon: 10.2}}} = TestRepo.get(uid)
    end
  end

  defp create_user(%User{} = user) do
    assert {:ok, %User{uid: uid}} = TestRepo.set(user)
    assert uid != nil
    assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    {created_user, uid}
  end
end
