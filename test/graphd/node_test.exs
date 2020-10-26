defmodule Graphd.NodeTest do
  use ExUnit.Case

  alias Graphd.User

  describe "schema generation" do
    test "basic" do
      assert "user" == User.__schema__(:source)
      assert :string == User.__schema__(:type, :name)
      assert :integer == User.__schema__(:type, :age)
      assert [:email, :name, :password, :nickname, :age, :friends, :location] == User.__schema__(:fields)
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
                 %{"predicate" => "user.location", "type" => "geo"}
               ],
               "types" => [
                 %{
                   "fields" => [
                     %{"name" => "user.location", "type" => "geo"},
                     %{"name" => "user.friends", "type" => "[uid]"},
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
    end
  end
end
