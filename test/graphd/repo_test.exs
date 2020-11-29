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
      {_user, uid} = create_user(%User{name: "Alice", age: 25, email: random_email()})

      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = TestRepo.get(uid)
    end

    test "create with primitive type predicate (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Alice", age: 25, email: random_email()}, [:name, :age, :email])
      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Alice", age: 25}} = TestRepo.get(uid)
    end

    test "create with password type predicate" do
      {_user, uid} =
        create_user(%User{name: "John", age: 19, password: "some-pass", email: random_email()})

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
          %{name: "John", age: 19, password: "secret", email: random_email()},
          [:name, :age, :password, :email]
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
        create_user(%User{name: "John", age: 19, email: random_email(), location: %Geo{lat: -33.8688, lon: 151.2093}})

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
          %{name: "John", age: 19, email: random_email(), location: %Geo{lat: -33.8688, lon: 151.2093}},
          [:name, :age, :email, :location]
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
      {_user, uid} = create_user(%User{name: "Mike", email: random_email(), tags: ["one", "two"]})

      assert {:ok, %User{uid: ^uid, name: "Mike", tags: ["one", "two"]}} =
               TestRepo.get(uid)
    end

    test "create with a list primitive type predicate (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Alice", email: random_email(), tags: ["abc", "def"]}, [:name, :email, :tags])
      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Alice", tags: tags}} = TestRepo.get(uid)
      assert is_list(tags)
      assert MapSet.new(tags) == MapSet.new(["abc", "def"])
    end

    test "create with a geo list predicate" do
      {_user, uid} = create_user(%User{name: "Mike", email: random_email(), destinations: [%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}]})

      assert {:ok, %User{uid: ^uid, name: "Mike", destinations: [%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}]}} =
               TestRepo.get(uid)
    end

    test "create with a geo list predicate (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Alice", email: random_email(), destinations: [%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}]}, [:name, :email, :destinations])
      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Alice", destinations: destinations}} = TestRepo.get(uid)
      assert is_list(destinations)
      assert MapSet.new(destinations) == MapSet.new([%Geo{lat: -33.8688, lon: 151.2093}, %Geo{lat: -36.8875, lon: 149.9059}])
    end

    test "create including edge nodes" do
      {referrer, _} = create_user(%User{name: "Evan", email: random_email()})
      {_user, uid} = create_user(%User{name: "Mike", email: random_email(), age: 53, referrer: referrer})

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, referrer: ^referrer}} =
               TestRepo.get(uid)
    end

    test "create including edge nodes (using changesets)" do
      {referrer, _} = create_user(%User{name: "Dean", email: random_email()})

      changeset =
        Changeset.cast(%User{}, %{name: "Mike", age: 53, email: random_email(), referrer: referrer}, [
          :name,
          :age,
          :email,
          :referrer
        ])

      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, referrer: ^referrer}} =
               TestRepo.get(uid)
    end

    test "create including a list of edge nodes" do
      {friend, _} = create_user(%User{name: "Evan", email: random_email()})
      {_user, uid} = create_user(%User{name: "Mike", email: random_email(), age: 53, friends: [friend]})

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, friends: [^friend]}} =
               TestRepo.get(uid)
    end

    test "create including a list of edge nodes (using changesets)" do
      {friend, _} = create_user(%User{name: "Dean", email: random_email()})

      changeset =
        Changeset.cast(%User{}, %{name: "Mike", email: random_email(), age: 53, friends: [friend]}, [
          :name,
          :age,
          :email,
          :friends
        ])

      assert {:ok, %User{uid: uid}} = TestRepo.set(changeset)
      assert uid != nil

      assert {:ok, %User{uid: ^uid, name: "Mike", age: 53, friends: [^friend]}} =
               TestRepo.get(uid)
    end

    test "update predicates with new values" do
      {_user, uid} =
        create_user(%User{name: "Peter", email: random_email(), age: 17, location: %Geo{lat: 15.5, lon: 10.2}})

      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.get(uid)

      updated_user = %User{uid: uid, name: "Fred", age: 21, location: %Geo{lat: 15.5, lon: 10.2}}
      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)

      assert {:ok, %User{uid: ^uid, name: "Fred", age: 21, location: %Geo{lat: 15.5, lon: 10.2}}} =
               TestRepo.get(uid)
    end

    test "update predicates with new values (using changesets)" do
      {user, uid} =
        create_user(%User{name: "Peter", email: random_email(), age: 17, location: %Geo{lat: 15.5, lon: 10.2}})

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
      {_user, uid} = create_user(%User{name: "Pearl", email: random_email(), age: 13})

      assert {:ok, %User{uid: ^uid, name: "Pearl", age: 13}} = TestRepo.get(uid)

      updated_user = %User{uid: uid, age: 21}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)
      assert {:ok, %User{uid: ^uid, name: "Pearl", age: 21}} = TestRepo.get(uid)
    end

    test "update while omitting some values does not modify or delete it (using changesets)" do
      {user, uid} = create_user(%User{name: "Pearl", email: random_email(), age: 13})

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
      {_user, uid} = create_user(%User{name: "Peter", email: random_email(), age: 17})

      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17}} = TestRepo.get(uid)

      updated_user = %User{uid: uid, name: "Peter", age: nil}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)
      assert {:ok, %User{uid: ^uid, name: "Peter", age: 17}} = TestRepo.get(uid)
    end

    test "updating predicate with nil value does not modify or delete it (using changesets)" do
      {user, uid} = create_user(%User{name: "Peter", email: random_email(), age: 17})

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
      {friend1, _} = create_user(%User{name: "Jane", email: random_email()})
      {friend2, _} = create_user(%User{name: "Louise", email: random_email()})
      {_user, uid} = create_user(%User{name: "Paul", email: random_email(), age: 17, friends: [friend1]})

      updated_user = %User{uid: uid, name: "Paul", age: 17, friends: [friend2]}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, friends: [^friend1, ^friend2]}} =
               TestRepo.get(uid)
    end

    test "updating edge to add a new value inserts the new value into the list (using changesets)" do
      {friend1, _} = create_user(%User{name: "Jane", email: random_email()})
      {friend2, _} = create_user(%User{name: "Louise", email: random_email()})
      {user, uid} = create_user(%User{name: "Paul", email: random_email(), age: 17, friends: [friend1]})

      changeset = Changeset.cast(user, %{friends: [friend2]}, [:friends])

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, friends: [^friend1, ^friend2]}} =
               TestRepo.get(uid)
    end

    test "updating a list of strings to insert a new value" do
      {_user, uid} = create_user(%User{name: "Paul", email: random_email(), age: 17, tags: ["one", "two", "three"]})

      updated_user = %User{uid: uid, name: "Paul", age: 17, tags: ["four"]}

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(updated_user)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, tags: ["one", "two", "three", "four"]}} =
               TestRepo.get(uid)
    end

    test "updating a list of strings to insert a new value (using changesets)" do
      {user, uid} = create_user(%User{name: "Paul", email: random_email(), age: 17, tags: ["one", "two", "three"]})

      changeset = Changeset.cast(user, %{tags: ["four"]}, [:tags])

      assert {:ok, %User{uid: ^uid}} = TestRepo.set(changeset)

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, tags: ["one", "two", "three", "four"]}} =
               TestRepo.get(uid)
    end
  end

  describe "delete/2" do
    test "deleting the exact object deletes the whole thing not just a predicate or edge" do
      {user, uid} = create_user(%User{name: "Norman", email: random_email(), age: 52})

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(user)
      assert {:ok, nil} = TestRepo.get(uid)
    end

    test "deleting clears exactly matching" do
      {_user, uid} = create_user(%User{name: "Norman", email: random_email(), age: 52})

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(%User{uid: uid, age: 52})
      assert {:ok, %User{age: nil, name: "Norman", uid: ^uid}} = TestRepo.get(uid)
    end

    test "deleting a list of strings to remove a value" do
      {_user, uid} = create_user(%User{name: "Paul", email: random_email(), age: 17, tags: ["a", "b", "c"]})

       assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.delete(%User{uid: uid, tags: ["b"]})

      assert {:ok, %User{uid: ^uid, name: "Paul", age: 17, tags: tags}} =
               TestRepo.get(uid)
      assert MapSet.new(tags) == MapSet.new(["a", "c"])
    end
  end

  describe "update/2" do
    test "updating a value" do
      {_user, uid} = create_user(%User{name: "Indie", email: random_email(), age: 42})

      mutations = %User{uid: uid, age: 43}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{mutations: mutations})
      assert {:ok, %User{uid: ^uid, name: "Indie", age: 43}} = TestRepo.get(uid)
    end

    test "updating a value (using changesets)" do
      {user, uid} = create_user(%User{name: "Indie", email: random_email(), age: 42})

      changeset = Changeset.cast(user, %{age: 43}, [:age])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Indie", age: 43}} = TestRepo.get(uid)
    end

    test "updating a value to nil" do
      {_user, uid} = create_user(%User{name: "Indie", email: random_email(), nickname: "Genius"})

      deletions = %User{uid: uid, nickname: "Genius"}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Indie", nickname: nil}} = TestRepo.get(uid)
    end

    test "updating a value to nil (using changesets)" do
      {user, uid} = create_user(%User{name: "Indie", email: random_email(), nickname: "Genius"})

      changeset = Changeset.cast(user, %{nickname: nil}, [:nickname])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Indie", nickname: nil}} = TestRepo.get(uid)
    end

    test "updating one value and niling another" do
      {_user, uid} = create_user(%User{name: "Jones", email: random_email(), nickname: "Mother", age: 84})

      mutations = %User{uid: uid, nickname: "Old Mother"}
      deletions = %User{uid: uid, age: 84}

      assert {:ok, %{queries: %{}, uids: %{}}} =
               TestRepo.update(%{mutations: mutations, deletions: deletions})

      assert {:ok, %User{uid: ^uid, name: "Jones", nickname: "Old Mother", age: nil}} =
               TestRepo.get(uid)
    end

    test "updating one value and niling another (using changesets)" do
      {user, uid} = create_user(%User{name: "Jones", email: random_email(), nickname: "Mother", age: 84})

      changeset = Changeset.cast(user, %{nickname: "Old Mother", age: nil}, [:age, :nickname])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)

      assert {:ok, %User{uid: ^uid, name: "Jones", nickname: "Old Mother", age: nil}} =
               TestRepo.get(uid)
    end

    test "updating a list to remove all items sets the list to nil" do
      {friend1, _} = create_user(%User{name: "Deidre", email: random_email()})
      {friend2, _} = create_user(%User{name: "Mick", email: random_email()})
      {_user, uid} = create_user(%User{name: "Frank", email: random_email(), friends: [friend1, friend2]})

      deletions = %User{uid: uid, friends: [friend1, friend2]}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list's contents to [] clears the list (using changesets)" do
      {friend, _} = create_user(%User{name: "Deidre", email: random_email()})
      {user, uid} = create_user(%User{name: "Frank", email: random_email(), age: 14, friends: [friend]})

      changeset = Changeset.cast(user, %{friends: []}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list's contents to nil clears the list (using changesets)" do
      {friend, _} = create_user(%User{name: "Deidre", email: random_email()})
      {user, uid} = create_user(%User{name: "Frank", email: random_email(), friends: [friend]})

      changeset = Changeset.cast(user, %{friends: nil}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: nil}} = TestRepo.get(uid)
    end

    test "updating a list to delete an item" do
      {friend1, _} = create_user(%User{name: "Deidre", email: random_email()})
      {friend2, _} = create_user(%User{name: "Mick", email: random_email()})
      {_user, uid} = create_user(%User{name: "Frank", email: random_email(), friends: [friend1, friend2]})

      deletions = %User{uid: uid, friends: [friend2]}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{deletions: deletions})
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: [^friend1]}} = TestRepo.get(uid)
    end

    test "updating a list to delete an item (using changesets)" do
      {friend1, _} = create_user(%User{name: "Deidre", email: random_email()})
      {friend2, _} = create_user(%User{name: "Mick", email: random_email()})
      {user, uid} = create_user(%User{name: "Frank", email: random_email(), friends: [friend1, friend2]})

      changeset = Changeset.cast(user, %{friends: [friend2]}, [:friends])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frank", friends: [^friend2]}} = TestRepo.get(uid)
    end

    test "complex update modifying some values, and deleting some list items while inserting others (using changesets)" do
      {friend1, _} = create_user(%User{name: "Deidre", email: random_email()})
      {friend2, _} = create_user(%User{name: "Mick", email: random_email()})
      {user, uid} = create_user(%User{name: "Frank", email: random_email(), tags: ["a", "b", "two"], friends: [friend1, friend2]})

      changeset = Changeset.cast(user, %{name: "Frankie-boy", tags: ["one", "two"], location: %Geo{lat: 15.5, lon: 10.2}, referrer: friend1, friends: [friend2]}, [:name, :tags, :referrer, :friends, :location])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, name: "Frankie-boy", tags: ["one", "two"], location: %Geo{lat: 15.5, lon: 10.2}, referrer: friend1, friends: [^friend2]}} = TestRepo.get(uid)
    end



    test "updating a record violating unique constraints" do
      email = random_email()

      # arrange
      {_user, existing_uid} = create_user(%User{email: email})
      {_user, update_uid} = create_user(%User{email: random_email()})

      # act & assert
      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^existing_uid}]}}} = TestRepo.update(%{mutations: %User{uid: update_uid, email: email}})
    end

    test "updating a record violating unique constraints (using changesets)" do
      email = random_email()

      # arrange
      {_user, existing_uid} = create_user(%User{email: email})
      {update_user, _uid} = create_user(%User{email: random_email()})

      changeset = Changeset.cast(update_user, %{email: email}, [:email])

      # act & assert
      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^existing_uid}]}}} = TestRepo.update(changeset)
    end

    test "can update a record with a unique field being set" do
      {_user, uid} = create_user(%User{email: random_email()})

      email = random_email()

      mutations = %User{uid: uid, email: email}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{mutations: mutations})
      assert {:ok, %User{uid: ^uid, email: ^email}} = TestRepo.get(uid)
    end

    test "can update a record with a unique field being set (using changesets)" do
      {user, uid} = create_user(%User{email: random_email()})

      email = random_email()

      changeset = Changeset.cast(user, %{email: email}, [:email])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, email: ^email}} = TestRepo.get(uid)
    end

    test "can update a record with multiple unique fields being set" do
      {_user, uid} = create_user(%User{email: random_email(), phone: random_string(10)})

      email = random_email()
      phone = random_string(10)

      mutations = %User{uid: uid, email: email, phone: phone}

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(%{mutations: mutations})
      assert {:ok, %User{uid: ^uid, email: ^email, phone: ^phone}} = TestRepo.get(uid)
    end

    test "can update a record with multiple unique fields being set (using changesets)" do
      {user, uid} = create_user(%User{email: random_email(), phone: random_string(10)})

      email = random_email()
      phone = random_string(10)

      changeset = Changeset.cast(user, %{email: email, phone: phone}, [:email ,:phone])

      assert {:ok, %{queries: %{}, uids: %{}}} = TestRepo.update(changeset)
      assert {:ok, %User{uid: ^uid, email: ^email, phone: ^phone}} = TestRepo.get(uid)
    end

    test "when one unique value already exists, the whole update is rolled back" do
      email = random_email()

      {_user, existing_uid} = create_user(%User{email: email})
      {_user, uid} = create_user(%User{email: random_email()})

      mutations = %User{uid: uid, email: email, phone: random_string(10)}

      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^existing_uid}]}}} = TestRepo.update(%{mutations: mutations})
    end

    test "when one unique value already exists, the whole update is rolled back (using changesets)" do
      email = random_email()
      phone = random_string(10)

      {_user, existing_uid} = create_user(%User{email: email})
      {user, _uid} = create_user(%User{email: random_email()})

      changeset = Changeset.cast(user, %{email: email, phone: phone}, [:email ,:phone])

      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^existing_uid}]}}} = TestRepo.update(changeset)
    end

    test "update fails when required field is included in deletion" do
      email = random_email()

      {_user, uid} = create_user(%User{email: email})

      deletions = %User{uid: uid, email: email}

      assert {:error, {:reason, :required_field_missing, [:email]}} = TestRepo.update(%{deletions: deletions})
    end

    test "update fails when required field is nilled (using changesets)" do
      email = random_email()

      {user, _uid} = create_user(%User{email: email})

      changeset = Changeset.cast(user, %{email: nil}, [:email])

      assert {:error, {:reason, :required_field_missing, [:email]}} = TestRepo.update(changeset)
    end
  end

  describe "create/2" do
    test "creating a record" do
      user = %User{name: "Ben", email: random_email()}

      assert {:ok, %User{uid: uid}} = TestRepo.create(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    end

    test "creating a record with a node-edge" do
      {friend, _} = create_user(%User{name: "Deidre", email: random_email()})
      user = %User{name: "Jon", email: "jon@email.com", friends: [friend]}

      assert {:ok, %User{uid: uid}} = TestRepo.create(user)
      assert uid != nil
      assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    end

    test "creating a record (using changesets)" do
      changeset = Changeset.cast(%User{}, %{name: "Ben", email: random_email()}, [:name, :email])

      assert {:ok, %User{uid: uid}} = TestRepo.create(changeset)
      assert uid != nil
      assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    end

    test "creating a record fails when uid is passed" do
      {user, _uid} = create_user(%User{name: "Ian", email: random_email()})

      assert {:error, _} = TestRepo.create(user)
    end

    test "creating a record fails when uid is passed (using changesets)" do
      {user, _uid} = create_user(%User{name: "Chris", email: random_email()})
      changeset = Changeset.cast(user, %{name: "Pete", email: random_email()}, [:name, :email])

      assert {:error, %{reason: :uid_present}} = TestRepo.create(changeset)
    end

    test "creating a record with unique constraints" do
      email = random_email()

      # arrange
      {_user, uid} = create_user(%User{email: email})

      # act & assert
      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^uid}]}}} = TestRepo.create(%User{email: email})
    end

    test "creating a record with unique constraints (using changesets)" do
      email = random_email()

      # arrange
      {_user, uid} = create_user(%User{email: email, nickname: "Mate"})

      changeset = Changeset.cast(%User{}, %{email: email, tags: ["one", "two"]}, [:email, :tags])

      # act & assert
      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^uid}]}}} = TestRepo.create(changeset)
    end

    test "can create a record with a unique field being set" do
      email = random_email()

      assert {:ok, %User{uid: uid, email: ^email}} = TestRepo.create(%User{email: email})
      assert uid != nil
    end

    test "can create a record with a unique field being set (using changesets)" do
      email = random_email()

      changeset = Changeset.cast(%User{}, %{email: email}, [:email])

      assert {:ok, %User{uid: uid, email: ^email}} = TestRepo.create(changeset)
      assert uid != nil
    end

    test "can create a record with multiple unique fields being set" do
      email = random_email()
      phone = random_string(10)

      assert {:ok, %User{uid: uid, email: ^email, phone: ^phone}} = TestRepo.create(%User{email: email, phone: phone})
      assert uid != nil
    end

    test "can create a record with multiple unique fields being set (using changesets)" do
      email = random_email()
      phone = random_string(10)

      changeset = Changeset.cast(%User{}, %{email: email, phone: phone}, [:email ,:phone])

      assert {:ok, %User{uid: uid, email: ^email, phone: ^phone}} = TestRepo.create(changeset)
      assert uid != nil
    end

    test "when one unique value already exists, the whole thing is rolled back" do
      email = random_email()
      phone = random_string(10)

      {_user, uid} = create_user(%User{email: email})

      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^uid}], "user.phone" => []}}} = TestRepo.create(%User{email: email, phone: phone})
    end

    test "when one unique value already exists, the whole thing is rolled back (using changesets)" do
      email = random_email()
      phone = random_string(10)

      {_user, uid} = create_user(%User{email: email})
      changeset = Changeset.cast(%User{}, %{email: email, phone: phone}, [:email ,:phone])

      assert {:error, {:reason, :already_exists, %{"user.email" => [%{"uid" => ^uid}], "user.phone" => []}}} = TestRepo.create(changeset)
    end

    test "fails when required field is missing" do
      assert {:error, {:reason, :required_field_missing, [:email]}} = TestRepo.create(%User{name: "Fred"})
    end

    test "fails when required field is missing (using changesets)" do
      phone = random_string(10)
      changeset = Changeset.cast(%User{}, %{phone: phone}, [:phone])

      assert {:error, {:reason, :required_field_missing, [:email]}} = TestRepo.create(changeset)
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
  end

  describe "get_by/1" do
    test "when not found" do
      assert {:ok, nil} = TestRepo.get_by(%User{email: "not-found"})
    end

    test "when multiple records are found" do
      name = "Simon the Great"
      {_user, uid1} = create_user(%User{name: name, email: random_email()})

      {_user, uid2} = create_user(%User{name: name, email: random_email()})

      assert uid1 != uid2

      assert {:ok, list} = TestRepo.get_by(%User{name: name})
      assert is_list(list)
      assert 2 == length(list)
    end

    test "when one record is found" do
      name = "Singularity"
      {_user, _uid} = create_user(%User{name: name, email: random_email()})

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
      {_user, uid1} = create_user(%User{name: name, email: random_email()})
      {_user, uid2} = create_user(%User{name: name, email: random_email()})
      assert uid1 != uid2

      assert {:error, :more_than_one_record_found} = TestRepo.one_by(%User{name: name})
    end

    test "when one record is found" do
      name = "Unique"
      {user, _uid} = create_user(%User{name: name, email: random_email()})

      assert {:ok, ^user} = TestRepo.one_by(%User{name: name})
    end
  end

  defp create_user(%User{} = user) do
    assert {:ok, %User{uid: uid}} = TestRepo.set(user)
    assert uid != nil
    assert {:ok, %User{uid: ^uid} = created_user} = TestRepo.get(uid)
    {created_user, uid}
  end

  def random_email do
    email = :crypto.strong_rand_bytes(8) |> Base.url_encode64 |> binary_part(0, 8)
    "#{email}@email.com"
  end

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
