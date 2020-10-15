# 0.5.1

* fix and enhance support for custom ecto types (see example `Graphd.Geo` in tests)
* fix a types diff not handled proparly in `Graphd.Repo` in alter_schema
* enahnce decoding/encoding in `Graphd.Repo` to return errors
* enhance `Repo.all` to accept query parameters.
  To enable `Repo.all` automatically detect types and converts to types, please include at least `dgraph.type`.
  Recommended query returns:

    ```
    uid
    dgraph.type
    expand(_all_)
    ```


# 0.5.0

* enahnce `mutate` API to support multiple mutations and set and delete combined
* do not sent invalid changeset data to DGraph
* fix creation of geo locations with `return_json: true` option
* add support for `best_effort` and `read_only` options for query

Backwards-incompatible changes:

* `Graphd.mutate` changed. Before: `Graphd.mutate(pid, %{query: query, condition: condition}, mutation, opts)`,
  now this changed to `Graphd.mutate(pid, %{query: query}, %{cond: condition, set: mutation}, opts)`. It allows
  now to combine `set` and `delete` in the same mutation and do multiple mutations in one:
    `Graphd.mutate(pid, %{query: query}, %{cond: condition, set: set, delete: delete}, opts)`
    `Graphd.mutate(pid, %{query: query}, [mutaion1, mutation2])`
* `Graphd.set` now doesn't accept `condition` in a query, `Graphd.mutate` should be used instead.
* `Graphd.mutate`, `Graphd.delete`, `Graphd.set` doesn't return uids or json directly, but adds it to a map:
  `%{uids: uids, json: json}` and additionally it has has key `queries` to return queries, which additionally
  were used for this mutation. This allows to get everything back, what DGraph returns.

# 0.4.1

* check dgraph 1.1.1 is supported
* fix upserts for http protocol

# 0.4.0

* Add support for conditions in upsert
* Add support for returning structs in Repo.all

Backwards-incompatible changes:

* `Graphd.mutate(pid, query, mutation, opts)` is now `Graphd.mutate(pid, %{query: query}, mutation, opts)`,
  additionally `Graphd.mutate(pid, %{query: query, condition: condition}, mutation, opts)`
* `Repo.all` defined via `Graphd.Repo` - could return structs(if type is defined) instead of pure jsons

# 0.3.2

* Rename dgraph.type to be without prefix `type.` as it do not needed anymore

# 0.3.1

* Add http support for DGraph `1.1.0`

# 0.3.0

As dgraph has breaking API change, this version supports DGraph only in version `1.1.0`, use
graphd in version `0.2.1` for using with DGraph `1.0.X`.

* support DGraph `1.1.0` (only for `grpc` at the moment)

# 0.2.1

* add support for upcoming `upsert` functionallity (only for `grpc`)
* fix dependency missconfiguration in `v0.2.0`

# 0.2.0

* fix leaking of gun connections on timeouts
* add `transport` option, which specifies if `grpc` or `http` transport should be used
* make `grpc` dependencies optional, so you can choose based on transport the dependencies

# 0.1.3

* add support to alter table in the same format (json) as it queried. Now you can use output of
  `Graphd.query_schema` in `Graphd.alter`.

Example of usage:

```
Graphd.alter(conn, [%{
  "index" => true,
  "predicate" => "user.name",
  "tokenizer" => ["term"],
  "type" => "string"
}])
```

* add initial basic language integrated features on top of dgraph adapter:
  * add `Graphd.Node` to define schemas
  * add `Graphd.Repo` to define something like `Ecto.Repo`, but specific for Dgraph with custom API
  * `Graphd.Repo` supports `Ecto.Changeset` (and `Graphd.Node` schemas supports `Ecto.Changeset`),
  ecto is optional

Example usage:

```
defmodule User do
  use Graphd.Node

  schema "user" do
    field :name, :string, index: ["term"]
    field :age, :integer
    field :owns, :uid
  end
end

defmodule Repo do
  use Graphd.Repo, otp_app: :test, modules: [User]
end

%User{uid: uid} = Repo.mutate!(%User{name: "Alice", age: 29})
%User{name: "Alice"} = Repo.get!(uid)
```

Casting of nodes to structs happens automatically, but you need to either specify module in
`modules` or register them once after `Repo` is started with `Repo.register(User)` to be
available for `Repo`.

To get `User` schema, can be `User.__schema__(:alter)` used or `Repo.snapshot` for all fields or
or `Repo.alter_schema()` to directly migrate/alter schema for `Repo`.

`Ecto.Changeset` works with `Graphd.Node` and `Graphd.Repo`.

Example usage:

```
changeset = Ecto.Changeset.cast(%User{}, %{"name" => "Alice", "age" => 20}, [:name, :age])
Repo.mutate(changeset)
```

# 0.1.2

* add timeout on grpc calls
* ensure client reconnection works on dgraph unavailibility
* optimize json encoding/decoding, fetch json library from environment on connection start

# 0.1.1

* fix adding default options by including as supervisor

# 0.1.0

First release!
