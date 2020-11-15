defmodule Graphd.RepoTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Graphd.{TestHelper, TestRepo, User}
  alias Graphd.DataType.Geo

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

    test "create with password type predicate" do
      {_user, uid} =
        create_user(%User{name: "John", age: 19, password: "some-pass"})

      assert {:ok,
              %User{
                uid: ^uid,
                name: "John",
                age: 19,
                password: nil
              }} = TestRepo.get(uid)
    end

    test "create with password type predicate (using changesets)" do
      changeset =
        Changeset.cast(
          %User{},
          %{name: "John", age: 19, password: "secret"},
          [:name, :age, :password]
        )

      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok,
              %User{
                uid: ^uid,
                name: "John",
                age: 19,
                password: nil
              }} = TestRepo.get(uid)
    end

    test "create with geo type predicate" do
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

    test "create with geo type predicate (using changesets)" do
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

    test "create with a list primitive type predicate" do
      {_user, uid} = create_user(%User{name: "Mike", tags: ["one", "two"]})

      assert {:ok, %User{uid: ^uid, name: "Mike", tags: ["one", "two"]}} =
               TestRepo.get(uid)
    end

    test "create with a list primitive type predicate (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Alice", tags: ["abc", "def"]}, [:name, :tags])
      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Alice", tags: tags}} = TestRepo.get(uid)
      assert is_list(tags)
      assert MapSet.new(tags) == MapSet.new(["abc", "def"])
    end

    test "create with a geo list predicate" do
      {_user, uid} = create_user(%User{name: "Mike", destinations: [%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}]})

      assert {:ok, %User{uid: ^uid, name: "Mike", destinations: [%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}]}} =
               TestRepo.get(uid)
    end

    test "create with a geo list predicate (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Alice", destinations: [%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}]}, [:name, :destinations])
      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Alice", destinations: destinations}} = TestRepo.get(uid)
      assert is_list(destinations)
      assert MapSet.new(destinations) == MapSet.new([%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}])
    end

    test "create including edge nodes" do
      {referrer, _} = create_user(%User{name: "Evan"})
      {_user, uid} = create_user(%User{name: "Mike", age: 53, referrer: referrer})

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, referrer: ^referrer}} =
               TestRepo.get(uid)
    end

    test "create including edge nodes (using changesets)" do
      {referrer, _} = create_user(%User{name: "Dean"})

      changeset =
        Changeset.cast(%User{}, %{name: "Mike", age: 53, referrer: referrer}, [
          :name,
          :age,
          :referrer
        ])

      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, referrer: ^referrer}} =
               TestRepo.get(uid)
    end

    test "create including a list of edge nodes" do
      {friend, _} = create_user(%User{name: "Evan"})
      {_user, uid} = create_user(%User{name: "Mike", age: 53, friends: [friend]})

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, friends: [^friend]}} =
               TestRepo.get(uid)
    end

    test "create including a list of edge nodes (using changesets)" do
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

    test "updating a list of strings to insert a new value" do
      {_user, uid} = create_user(%User{name: "Paul", age: 17, tags: ["one", "two", "three"]})

      updated_user = %User{uid: uid, name: "Paul", age: 17, tags: ["four"]}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, tags: ["one", "two", "three", "four"]}} =
               TestRepo.get(uid)
    end

    test "updating a list of strings to insert a new value (using changesets)" do
      {user, uid} = create_user(%User{name: "Paul", age: 17, tags: ["one", "two", "three"]})

      changeset = Changeset.cast(user, %{tags: ["four"]}, [:tags])

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, tags: ["one", "two", "three", "four"]}} =
               TestRepo.get(uid)
    end
  end

  describe "delete/2" do
    test "deleting the exact object deletes the whole thing not just a predicate or edge" do
      {user, uid} = create_user(%User{name: "Norman", age: 52})

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(user)
      assert {:ok, nil} = TestRepo.get(uid)
    end

    test "deleting clears exactly matching" do
      {_user, uid} = create_user(%User{name: "Norman", age: 52})

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(%User{uid: uid, age: 52})
      assert {:ok, %User{age: nil, name: "Norman", uid: ^uid}} = TestRepo.get(uid)
    end

    test "deleting a list of strings to remove a value" do
      {_user, uid} = create_user(%User{name: "Paul", age: 17, tags: ["a", "b", "c"]})

       assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(%User{uid: uid, tags: ["b"]})

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, tags: tags}} =
               TestRepo.get(uid)
      assert MapSet.new(tags) == MapSet.new(["a", "c"])
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

    test "updating a list to remove all items sets the list to nil" do
      {friend1, _} = create_user(%User{name: "Deidre"})
      {friend2, _} = create_user(%User{name: "Mick"})
      {_user, uid} = create_user(%User{name: "Frank", friends: [friend1, friend2]})

      deletions = %User{uid: uid, friends: [friend1, friend2]}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list's contents to [] clears the list (using changesets)" do
      {friend, _} = create_user(%User{name: "Deidre"})
      {user, uid} = create_user(%User{name: "Frank", age: 14, friends: [friend]})

      changeset = Changeset.cast(user, %{friends: []}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list's contents to nil clears the list (using changesets)" do
      {friend, _} = create_user(%User{name: "Deidre"})
      {user, uid} = create_user(%User{name: "Frank", friends: [friend]})

      changeset = Changeset.cast(user, %{friends: nil}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list to delete an item" do
      {friend1, _} = create_user(%User{name: "Deidre"})
      {friend2, _} = create_user(%User{name: "Mick"})
      {_user, uid} = create_user(%User{name: "Frank", friends: [friend1, friend2]})

      deletions = %User{uid: uid, friends: [friend2]}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: [^friend1]}} = TestRepo.get(uid)
    end

    test "updating a list to delete an item (using changesets)" do
      {friend1, _} = create_user(%User{name: "Deidre"})
      {friend2, _} = create_user(%User{name: "Mick"})
      {user, uid} = create_user(%User{name: "Frank", friends: [friend1, friend2]})

      changeset = Changeset.cast(user, %{friends: [friend2]}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: [^friend2]}} = TestRepo.get(uid)
    end

    test "complex update modifying some values, and deleting some list items while inserting others (using changesets)" do
      {friend1, _} = create_user(%User{name: "Deidre"})
      {friend2, _} = create_user(%User{name: "Mick"})
      {user, uid} = create_user(%User{name: "Frank", tags: ["a", "b", "two"], friends: [friend1, friend2]})

      changeset = Changeset.cast(user, %{name: "Frankie-boy", tags: ["one", "two"], location: %Geo{lat: 15.5, lon: 10.2}, referrer: friend1, friends: [friend2]}, [:name, :tags, :referrer, :friends, :location])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frankie-boy", tags: ["one", "two"], location: %Geo{lat: 15.5, lon: 10.2}, referrer: friend1, friends: [^friend2]}} = TestRepo.get(uid)
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

  describe "checkpass/3" do
    test "with correct credentials" do
      {_user, uid} = create_user(%User{email: "correct-pwd@email.com", password: "super-secret"})

      assert {:ok, ^uid} =
               TestRepo.checkpass(%User{email: "correct-pwd@email.com"}, %User{
                 password: "super-secret"
               })
    end

    test "with wrong credentials" do
      {_user, _uid} = create_user(%User{email: "wrong-pwd@email.com", password: "super-secret"})

      assert {:error, :no_match} =
               TestRepo.checkpass(%User{email: "wrong-pwd@email.com"}, %User{
                 password: "wrong-secret"
               })
    end

    test "with no users found with the reference field" do
      assert {:error, :no_match} =
               TestRepo.checkpass(%User{email: "unknown@email.com"}, %User{
                 password: "whatev"
               })
    end

    test "with multiple users found with the reference field" do
      {_user, _uid1} = create_user(%User{email: "duplicate@email.com", password: "super-secret"})
      {_user, _uid2} = create_user(%User{email: "duplicate@email.com", password: "other-secret"})

      assert {:error, :multiple} =
               TestRepo.checkpass(%User{email: "duplicate@email.com"}, %User{
                 password: "super-secret"
               })
    end
  end

  describe "get_by/1" do
    test "when not found" do
      assert {:ok, nil} = TestRepo.get_by(%User{email: "not-found"})
    end

    test "when multiple records are found" do
      name = "Simon the Great"
      {_user, uid1} = create_user(%User{name: name})

      {_user, uid2} = create_user(%User{name: name})

      assert uid1 != uid2

      assert {:ok, list} = TestRepo.get_by(%User{name: name})
      assert is_list(list)
      assert 2 == length(list)
    end

    test "when one record is found" do
      name = "Singularity"
      {_user, _uid} = create_user(%User{name: name})

      assert {:ok, list} = TestRepo.get_by(%User{name: name})
      assert is_list(list)
      assert 1 == length(list)
    end
  end

  describe "one_by/1" do
    test "when not found" do
      assert {:ok, nil} = TestRepo.one_by(%User{email: "not-found"})
    end

    test "when multiple records are found" do
      name = "Nigel the Bold"
      {_user, uid1} = create_user(%User{name: name})
      {_user, uid2} = create_user(%User{name: name})
      assert uid1 != uid2

      assert {:error, :more_than_one_record_found} = TestRepo.one_by(%User{name: name})
    end

    test "when one record is found" do
      name = "Unique"
      {user, _uid} = create_user(%User{name: name})

      assert {:ok, ^user} = TestRepo.one_by(%User{name: name})
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
