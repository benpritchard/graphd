defmodule Graphd.Repo do
  @moduledoc """
  Ecto-like repository, which allows to embed the schema

    defmodule Repo do
      use Graphd.Repo, otp_app: :my_app, modules: [User]
    end

    config :my_app, Repo,
      hostname: "localhost",
      port: 3306
  """
  alias Graphd.{Error, Node, Repo.Meta, Utils}

  @type conn :: DBConnection.conn()
  @type query :: iodata
  @type query_map :: %{:query => query, optional(:vars) => map}
  @type statement :: iodata | map
  @type mutation :: %{
          optional(:cond) => iodata,
          optional(:set) => statement(),
          optional(:delete) => statement()
        }
  @type mutations :: [mutation]
  @type update_set :: %{
          optional(:mutations) => statement(),
          optional(:deletions) => statement()
        }
  @type changeset :: Ecto.Changeset.t()

  @doc """

  """
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts], location: :keep do
      @name opts[:name] || __MODULE__
      @meta_name :"#{@name}.Meta"
      @otp_app opts[:otp_app]
      @modules opts[:modules] || []

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        start_opts = %{
          module: __MODULE__,
          otp_app: @otp_app,
          name: @name,
          meta_name: @meta_name,
          modules: @modules,
          opts: opts
        }

        Graphd.Repo.Sup.start_link(start_opts)
      end

      def set(node, opts \\ []), do: Graphd.Repo.set(@name, node, opts)
      def set!(node, opts \\ []), do: Graphd.Repo.set!(@name, node, opts)

      def create(node, opts \\ []), do: Graphd.Repo.create(@name, node, opts)
      def create!(node, opts \\ []), do: Graphd.Repo.create!(@name, node, opts)

      def update(node, opts \\ []),
        do: Graphd.Repo.update(@name, node, meta(), opts)

      def delete(node, opts \\ []), do: Graphd.Repo.delete(@name, node, opts)
      def delete!(node, opts \\ []), do: Graphd.Repo.delete!(@name, node, opts)

      def get(uid), do: Graphd.Repo.get(@name, meta(), uid)
      def get!(uid), do: Graphd.Repo.get!(@name, meta(), uid)

      def get_by(%{} = by), do: Graphd.Repo.get_by(@name, meta(), by)

      def checkpass(%{} = reference, %{} = password),
        do: Graphd.Repo.checkpass(@name, reference, password)

      def all(query, params \\ %{}), do: Graphd.Repo.all(@name, query, params, meta())

      def meta(), do: Graphd.Repo.Meta.get(@meta_name)
      def register(modules), do: Graphd.Repo.Meta.register(@meta_name, modules)
      def snapshot(), do: Graphd.Repo.snapshot(@meta_name)
      def alter_schema(snapshot \\ snapshot()), do: Graphd.Repo.alter_schema(@name, snapshot)

      def stop(timeout \\ 5000), do: Supervisor.stop(@name, :normal, timeout)

      def drop_data(), do: Graphd.Repo.drop_data(@name)
      def drop_all(), do: Graphd.Repo.drop_all(@name)
    end
  end

  @doc false
  def child_spec(%{module: module, otp_app: otp_app, name: name, opts: opts}) do
    opts = Keyword.merge(opts, Application.get_env(otp_app, module, []))
    Graphd.child_spec([{:name, name} | opts])
  end

  @doc """
  Build or update lookup map from module list
  """
  def build_lookup_map(lookup_map \\ %{}, modules) do
    for module <- List.wrap(modules), reduce: lookup_map do
      acc ->
        case source(module) do
          nil -> acc
          source -> Map.put(acc, source, module)
        end
    end
  end

  @doc """
  Query all. It automatically tries to decode values inside of a query. To make it work, you
  need to expand the results it like this: `uid dgraph.type expand(_all_)`
  """
  @spec all(conn, query, map, %{lookup: any}) :: {:ok, map} | {:error, Graphd.Error.t() | term}
  def all(conn, query, params, %{lookup: lookup} = _meta \\ %{lookup: %{}}) do
    with {:ok, data} <- Graphd.query(conn, query, params), do: decode(data, lookup, false)
  end

  @doc """
  The same as `create/2`, but return result of sucessful operation or raises.
  """
  @spec create!(conn, map | changeset, keyword) :: map | no_return
  def create!(conn, data, opts) do
    case create(conn, data, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Create a node.
  """
  @spec create(conn, map | changeset, keyword) ::
          {:error, changeset | Error.t() | term} | {:ok, map}
  def create(_conn, %{__struct__: Ecto.Changeset, valid?: false} = changeset, _opts),
    do: {:error, changeset}

  def create(conn, %{__struct__: Ecto.Changeset, valid?: true} = changeset, opts) do
    %{data: %{__struct__: struct} = data, changes: changes} = changeset

    with {:ok, new_data} <-
           create(conn, Map.merge(changes, %{__struct__: struct, uid: Map.get(data, :uid)}), opts) do
      {:ok, Map.merge(data, new_data)}
    end
  end

  def create(conn, %{uid: uid} = data, opts) do
    case uid do
      nil -> set(conn, data, opts)
      _ -> {:error, %{reason: :uid_present}}
    end
  end

  @doc """
  The same as `mutate/2`, but return result of sucessful operation or raises.
  """
  @spec set!(conn, map | changeset, keyword) :: map | no_return
  def set!(conn, data, opts) do
    case set(conn, data, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Mutate data.
  """
  @spec set(conn, map | changeset, keyword) ::
          {:error, changeset | Error.t() | term} | {:ok, map}
  def set(_conn, %{__struct__: Ecto.Changeset, valid?: false} = changeset, _opts),
    do: {:error, changeset}

  def set(conn, %{__struct__: Ecto.Changeset, valid?: true} = changeset, opts) do
    %{data: %{__struct__: struct} = data, changes: changes} = changeset

    with {:ok, new_data} <-
           set(conn, Map.merge(changes, %{__struct__: struct, uid: Map.get(data, :uid)}), opts) do
      {:ok, Map.merge(data, new_data)}
    end
  end

  def set(conn, data, opts) do
    data_with_ids = Utils.add_blank_ids(data, :uid)

    case encode(data_with_ids) do
      {:error, error} ->
        {:error, %Error{action: :set, reason: error}}

      encoded_data ->
        with {:ok, %{uids: ids_map}} <- Graphd.set(conn, %{}, encoded_data, opts) do
          {:ok, Utils.replace_ids(data_with_ids, ids_map, :uid)}
        end
    end
  end

  # @spec update(any, map, any, any) :: {:error, <<_::456>> | Graphd.Error.t()} | map
  @doc """
  Update data. Requires the record to exist.
  """
  @spec update(conn, changeset | update_set, %{lookup: any}, keyword) ::
          {:error, Error.t() | term} | {:ok, map}

  def update(conn, %{__struct__: Ecto.Changeset, valid?: true} = changeset, meta, opts) do
    %{data: %{__struct__: struct} = data, changes: changes} = changeset
    mutations = Map.merge(changes, %{__struct__: struct, uid: Map.get(data, :uid)})

    nil_changes =
      Enum.reduce(changes, %{}, fn {k, v}, acc ->
        cond do
          is_nil(v) -> Map.put(acc, k, "")
          true -> acc
        end
      end)

    deletions =
      cond do
        is_map(nil_changes) && Enum.count(nil_changes) > 0 ->
          Map.merge(
            nil_changes,
            %{
              __struct__: struct,
              uid: Map.get(data, :uid)
            }
          )

        true ->
          nil
      end

    update(conn, %{mutations: mutations, deletions: deletions}, meta, opts)
  end

  def update(
        conn,
        %{
          mutations: %{uid: uid, __struct__: type} = mutations,
          deletions: %{uid: uid, __struct__: type} = deletions
        },
        meta,
        opts
      )
      when not is_nil(uid) do
    case {encode(mutations), encode(deletions)} do
      {{:error, m_error}, {:error, d_error}} ->
        {:error, %Error{action: :update, reason: "mutations: #{m_error}; deletions: #{d_error}"}}

      {{:error, m_error}, _} ->
        {:error, %Error{action: :update, reason: m_error}}

      {_, {:error, d_error}} ->
        {:error, %Error{action: :update, reason: d_error}}

      {encoded_mutations, encoded_deletions} ->
        do_update(conn, uid, encoded_mutations, encoded_deletions, meta, opts)
    end
  end

  def update(conn, %{mutations: %{uid: uid} = mutations}, meta, opts) when not is_nil(uid) do
    case encode(mutations) do
      {:error, error} ->
        {:error, %Error{action: :update, reason: error}}

      encoded_mutations ->
        do_update(conn, uid, encoded_mutations, nil, meta, opts)
    end
  end

  def update(conn, %{deletions: %{uid: uid} = deletions}, meta, opts) when not is_nil(uid) do
    case encode(deletions) do
      {:error, error} ->
        {:error, %Error{action: :update, reason: error}}

      encoded_deletions ->
        do_update(conn, uid, nil, encoded_deletions, meta, opts)
    end
  end

  def update(_conn, _mutations, _meta, _opts),
    do: {:error, "incorrect update update params provided"}

  @spec do_update(conn, String.t(), nil | map, nil | map, %{lookup: any}, keyword) ::
          {:error, Error.t() | term} | {:ok, map}
  defp do_update(_conn, _uid, nil, nil, _meta, _opts),
    do: {:error, "both mutations and deletions are nil - what's the point??"}

  defp do_update(
         conn,
         uid,
         mutations,
         deletions,
         %{lookup: _lookup} = _meta,
         opts
       ) do
    query = %{
      query: ~s|query var($uid: string) { v as var(func: uid($uid)) {uid}}|,
      vars: %{"$uid" => uid}
    }

    data =
      %{}
      |> maybe_put(:delete, maybe_put(maybe_pop(deletions, "dgraph.type"), "uid", "uid(v)"))
      |> maybe_put(:set, maybe_put(mutations, "uid", "uid(v)"))

    Graphd.mutate(conn, query, [data], opts)
  end

  @spec maybe_put(nil | map, any, any) :: nil | map
  defp maybe_put(nil, _key, _value), do: nil
  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @spec maybe_pop(nil | map, any) :: nil | map
  defp maybe_pop(nil, _key), do: nil

  defp maybe_pop(map, key) do
    {_, new_map} = Map.pop(map, key)
    new_map
  end

  @doc """
  Delete data.
  """
  @spec delete(conn, any, keyword) :: {:error, changeset | Error.t() | term} | {:ok, map}
  def delete(conn, data, _opts) do
    case encode(data) do
      {:error, error} ->
        {:error, %Error{action: :delete, reason: error}}

      encoded_data ->
        Graphd.delete(conn, encoded_data)
    end
  end

  @doc """
  The same as `delete/2`, but return result of sucessful operation or raises.
  """
  @spec delete!(conn, map, keyword) :: map | no_return
  def delete!(conn, data, opts) do
    case delete(conn, data, opts) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @spec encode(map, boolean) :: map | {:error, any}
  def encode(data, preserve_nils \\ false)

  def encode(%{__struct__: struct} = data, preserve_nils) do
    data
    |> Map.from_struct()
    |> Map.to_list()
    |> encode_kv(%{}, struct, preserve_nils)
  end

  def encode(data, _preserve_nils) when is_list(data), do: encode_list(data, [])
  def encode(data, _preserve_nils), do: data

  @spec encode_kv(maybe_improper_list, map, atom, boolean) :: map | {:error, any}
  defp encode_kv(kva, map, struct, preserve_nils)
  defp encode_kv([], map, _struct, _preserve_nils), do: map

  defp encode_kv([{_key, nil} | kv], map, struct, false),
    do: encode_kv(kv, map, struct, false)

  defp encode_kv([{:uid, value} | kv], map, struct, preserve_nils) do
    map = Map.merge(map, %{"uid" => value, "dgraph.type" => source(struct)})
    encode_kv(kv, map, struct, preserve_nils)
  end

  defp encode_kv([{key, value} | kv], map, struct, preserve_nils) do
    {field_name, type} = {field(struct, key), type(struct, key)}

    cond do
      field_name == nil ->
        encode_kv(kv, map, struct, preserve_nils)

      Node.primitive_type?(type) ->
        map = Map.put(map, field_name, encode(value))
        encode_kv(kv, map, struct, preserve_nils)

      true ->
        case type.dump(value) do
          {:ok, data} -> encode_kv(kv, Map.put(map, field_name, data), struct, preserve_nils)
          :error -> {:error, {:dump_error, key, type, value}}
        end
    end
  end

  defp encode_list([], list), do: Enum.reverse(list)

  defp encode_list([value | values], list) do
    case encode(value) do
      {:error, error} -> {:error, error}
      data -> encode_list(values, [data | list])
    end
  end

  @compile {:inline, field: 2}
  @spec type(atom, any) :: any
  def type(struct, key), do: struct.__schema__(:type, key)
  @compile {:inline, field: 2}
  @spec field(any, any) :: any
  def field(_struct, "uid"), do: {:uid, :string}
  def field(struct, key), do: struct.__schema__(:field, key)
  @compile {:inline, source: 1}
  @spec source(atom) :: any
  def source(struct), do: struct.__schema__(:source)

  @doc """
  The same as `get/3`, but return result or raises.
  """
  @spec get!(conn, %{lookup: any}, String.t()) :: map | no_return
  def get!(conn, meta, uid) do
    case get(conn, meta, uid) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Get by uid
  """
  @spec get(conn, %{lookup: any}, String.t()) :: {:error, Error.t() | term} | {:ok, map | nil}
  def get(conn, %{lookup: lookup}, uid) do
    statement = [
      "{uid_get(func: uid(",
      uid,
      ")) {uid dgraph.type expand(_all_){uid dgraph.type expand(_all_)}}}"
    ]

    with {:ok, %{"uid_get" => nodes}} <- Graphd.query(conn, statement) do
      case nodes do
        [%{"uid" => _} = map] when map_size(map) <= 2 ->
          {:ok, nil}

        [map] ->
          with {:error, error} <- decode(map, lookup),
               do: {:error, %Error{action: :get, reason: error}}
      end
    end
  end

  @doc """
  Get by field
  """
  @spec get_by(conn, %{lookup: any}, map) :: {:error, Error.t() | term} | {:ok, map | nil}
  def get_by(conn, %{lookup: lookup}, %{} = data) do
    [{field, value} | _] = Map.to_list(encode(data))

    statement =
      "query all($a: string) {all(func: eq(#{field}, $a)) {uid dgraph.type expand(_all_) {uid dgraph.type expand(_all_)}}}"

    with {:ok, %{"all" => nodes}} <- Graphd.query(conn, statement, %{"$a" => value}) do
      case nodes do
        [map] ->
          with {:error, error} <- decode(map, lookup),
               do: {:error, %Error{action: :get, reason: error}}

        _ ->
          {:ok, nil}
      end
    end
  end

  @doc """
  Check password
  """
  @spec checkpass(conn, map, map) ::
          {:error, :no_match | :multiple | any} | {:ok, String.t()}
  def checkpass(conn, %{} = reference, %{} = password) do
    [{reference_field, value} | _] = Map.to_list(encode(reference))
    [{password_field, password} | _] = Map.to_list(encode(password))
    statement = "query checkpass($v: string, $p: string) {
      checkpass(func: eq(#{reference_field}, $v)) {
        uid
        match: checkpwd(#{password_field}, $p)
      }
    }"

    with {:ok, %{"checkpass" => result}} <-
           Graphd.query(conn, statement, %{"$v" => value, "$p" => password}) do
      case result do
        list when is_list(list) and length(list) > 1 -> {:error, :multiple}
        list when is_list(list) and length(list) < 1 -> {:error, :no_match}
        [%{"uid" => uid, "match" => true}] -> {:ok, uid}
        [%{"match" => false}] -> {:error, :no_match}
      end
    else
      error -> {:error, error}
    end
  end

  @doc """
  Decode resulting map to a structure.
  """
  @spec decode(map | list, any, boolean) :: {:ok, map} | list | {:error, any}
  def decode(map, lookup, strict? \\ true) do
    with %{} = map <- do_decode(map, lookup, strict?), do: {:ok, map}
  end

  defp do_decode(map, lookup, strict?) when is_map(map) and is_map(lookup) do
    with %{"dgraph.type" => [type_string]} <- map,
         type when type != nil <- Map.get(lookup, type_string) do
      do_decode_map(map, type, lookup, strict?)
    else
      _ ->
        cond do
          strict? -> {:error, {:untyped, map}}
          true -> do_decode_untyped_map(map, lookup)
        end
    end
  end

  defp do_decode(list, lookup, strict?) when is_list(list) and is_map(lookup) do
    for value <- list, do: do_decode(value, lookup, strict?)
  end

  defp do_decode(value, _lookup, _strict?), do: value

  defp do_decode_map(map, type, lookup, strict?) when is_map(map) and is_atom(type) do
    Enum.reduce_while(map, type.__struct__(), fn {key, value}, struct ->
      case do_decode_field(struct, field(type, key), value, lookup, strict?) do
        {:error, error} -> {:halt, {:error, error}}
        updated_struct -> {:cont, updated_struct}
      end
    end)
  end

  defp do_decode_untyped_map(map, lookup) do
    Enum.reduce_while(map, %{}, fn {key, values}, acc ->
      case do_decode(values, lookup, false) do
        {:error, error} -> {:halt, {:error, error}}
        values -> {:cont, Map.put(acc, key, values)}
      end
    end)
  end

  defp do_decode_field(struct, {field_name, Graphd.UID = field_type}, value, lookup, strict?)
       when is_list(value) do
    case decode(value, lookup, strict?) do
      loaded_values when is_list(loaded_values) ->
        Map.put(struct, field_name, loaded_values)

      {:error, _} ->
        {:error, {:load_error, field_name, field_type, value}}
    end
  end

  defp do_decode_field(struct, {field_name, field_type}, value, lookup, strict?) do
    case Ecto.Type.load(field_type, value) do
      {:ok, loaded_value} ->
        if Node.primitive_type?(field_type) do
          Map.put(struct, field_name, do_decode(loaded_value, lookup, strict?))
        else
          Map.put(struct, field_name, loaded_value)
        end

      :error ->
        {:error, {:load_error, field_name, field_type, value}}
    end
  end

  defp do_decode_field(struct, nil, _value, _lookup, _strict?), do: struct

  @doc """
  Alter schema for modules
  """
  @spec alter_schema(conn, any) :: {:error, Graphd.Error.t() | term} | {:ok, non_neg_integer}
  def alter_schema(conn, snapshot) do
    with {:ok, sch} <- Graphd.query_schema(conn), do: do_alter_schema(conn, sch, snapshot)
  end

  defp do_alter_schema(conn, %{"schema" => schema, "types" => types}, snapshot) do
    delta = %{
      "schema" => snapshot["schema"] -- schema,
      "types" => delta_types(snapshot["types"], types)
    }

    delta_l = length(delta["schema"]) + length(delta["types"])

    case delta do
      %{"schema" => [], "types" => []} -> {:ok, 0}
      alter -> with {:ok, _} <- Graphd.alter(conn, %{schema: alter}), do: {:ok, delta_l}
    end
  end

  defp do_alter_schema(conn, sch, snapshot) do
    do_alter_schema(conn, Map.put_new(sch, "types", []), snapshot)
  end

  defp delta_types([], _existing_types), do: []

  defp delta_types([type_spec | types], existing_types) do
    if type_exist?(type_spec, existing_types) do
      delta_types(types, existing_types)
    else
      [type_spec | delta_types(types, existing_types)]
    end
  end

  defp type_exist?(%{"name" => name, "fields" => fields}, existing_types) do
    case Enum.find(existing_types, &(Map.get(&1, "name") == name)) do
      nil ->
        false

      %{"fields" => existing_fields} ->
        MapSet.equal?(fields_set(fields), fields_set(existing_fields))
    end
  end

  defp fields_set(fields),
    do: fields |> Enum.map(fn %{"name" => name} -> name end) |> MapSet.new()

  @doc """
  Generate snapshot for running meta process
  """
  @spec snapshot(any) :: any
  def snapshot(meta) do
    %{modules: modules} = Meta.get(meta)

    modules
    |> MapSet.to_list()
    |> List.wrap()
    |> expand_modules()
    |> Enum.map(& &1.__schema__(:alter))
    |> Enum.reduce(%{"types" => [], "schema" => []}, fn mod_sch, acc ->
      %{
        "types" => Enum.concat(acc["types"], mod_sch["types"]),
        "schema" => Enum.concat(acc["schema"], mod_sch["schema"])
      }
    end)
  end

  defp expand_modules(modules) do
    Enum.reduce(modules, modules, fn module, modules ->
      depends_on_modules = module.__schema__(:depends_on)
      Enum.reduce(depends_on_modules, modules, &if(Enum.member?(&2, &1), do: &2, else: [&1 | &2]))
    end)
  end

  @doc """
  Drop all data from database. Use with caution, as it deletes all data in the database.
  """
  @spec drop_data(conn) :: {:ok, map} | {:error, Graphd.Error.t() | term}
  def drop_data(conn) do
    Graphd.alter(conn, %{drop_op: :DATA})
  end

  @doc """
  Drop everything from database. Use with caution, as it deletes everything in database.
  """
  @spec drop_all(conn) :: {:ok, map} | {:error, Graphd.Error.t() | term}
  def drop_all(conn) do
    Graphd.alter(conn, %{drop_all: true})
  end
end
