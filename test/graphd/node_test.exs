defmodule Graphd.NodeTest do
  use ExUnit.Case

  alias Graphd.User

  describe "schema generation" do
    test "basic" do
      assert "user" == User.__schema__(:source)
      assert :string == User.__schema__(:type, :name)
      assert :integer == User.__schema__(:type, :age)
      assert [:email, :name, :password, :nickname, :age, :friends, :location, :destinations, :referrer, :tags, :phone] == User.__schema__(:fields)
    end

    test "alter" do
      assert %{
               "schema" => [
                 %{
                   "index" => true,
                   "predicate" => "user.email",
                   "tokenizer" => ["exact"],
                   "type" => "string"
                 },
                 %{
                   "index" => true,
                   "predicate" => "user.name",
                   "tokenizer" => ["term"],
                   "type" => "string"
                 },
                 %{"predicate" => "user.password", "type" => "password"},
                 %{"predicate" => "user.nickname", "type" => "string"},
                 %{"predicate" => "user.age", "type" => "int"},
                 %{"predicate" => "user.friends", "type" => "[uid]"},
                 %{"predicate" => "user.location", "type" => "geo"},
                 %{"predicate" => "user.destinations", "type" => "[geo]"},
                 %{"predicate" => "user.referrer", "type" => "uid"},
                 %{"predicate" => "user.tags", "type" => "[string]"},
                 %{"predicate" => "user.phone", "type" => "string", "index" => true, "tokenizer" => ["exact"]}
               ],
               "types" => [
                 %{
                   "fields" => [
                     %{"name" => "user.phone", "type" => "string"},
                     %{"name" => "user.tags", "type" => "string"},
                     %{"name" => "user.referrer", "type" => "uid"},
                     %{"name" => "user.destinations", "type" => "geo"},
                     %{"name" => "user.location", "type" => "geo"},
                     %{"name" => "user.friends", "type" => "uid"},
                     %{"name" => "user.age", "type" => "int"},
                     %{"name" => "user.nickname", "type" => "string"},
                     %{"name" => "user.password", "type" => "password"},
                     %{"name" => "user.name", "type" => "string"},
                     %{"name" => "user.email", "type" => "string"}
                   ],
                   "name" => "user"
                 }
               ]
             } == User.__schema__(:alter)
    end

    test "transformation callbacks" do
      assert "user.name" == User.__schema__(:field, :name)
      assert {:name, :string} == User.__schema__(:field, "user.name")

      assert :string == User.__schema__(:type, :email)

      assert true == User.__schema__(:unique, :email)
      assert false == User.__schema__(:unique, :name)

      assert true == User.__schema__(:required, :email)
      assert false == User.__schema__(:required, :name)

      assert [:phone, :email] == User.__schema__(:unique_fields)

      assert [:email] == User.__schema__(:required_fields)
    end
  end
end
