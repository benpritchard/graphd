defmodule Graphd.Node do
  @moduledoc """
  Simple high level API for accessing graphs

  ## Usage

    defmodule Shared do
      use Graphd.Node

      shared do
        field :id, :string, index: ["term"]
        field :name, :string, index: ["term"]
      end
    end

    defmodule User do
      use Graphd.Node, depends_on: Shared

      schema "user" do
        field :id, :auto
        field :name, :auto
      end
    end

    defmodule User do
      use Graphd.Node

      schema "user" do
        field :id, :auto, depends_on: Shared
        field :name, :string, index: ["term"]
        field :age, :integer
        field :cache, :any, virtual: true
        field :owns, :uid
      end
    end

  Dgraph types:

      * `:integer`
      * `:float`
      * `:string`
      * `:geo`
      * `:datetime`
      * `:uid`
      * `:auto` - special type, which can be used for `depends_on`

  ## Reflection

  Any schema module will generate the `__schema__` function that can be
  used for runtime introspection of the schema:

  * `__schema__(:source)` - Returns the source as given to `schema/2`;
  * `__schema__(:fields)` - Returns a list of all non-virtual field names;
  * `__schema__(:alter)` - Returns a generated alter schema

  * `__schema__(:field, field)` - Returns the name of field in database for field in a struct and
    vice versa;

  * `__schema__(:type, field)` - Returns the type of the given non-virtual field;

  Additionally it generates `Ecto` compatible `__changeset__` for using with `Ecto.Changeset`.

  """

  alias Graphd.Field

  defmacro __using__(opts) do
    depends_on = Keyword.get(opts, :depends_on, nil)

    quote do
      @depends_on unquote(depends_on)

      import Graphd.Node, only: [shared: 1, schema: 2]
    end
  end

  defmacro schema(name, block) do
    prepare = prepare_block(name, block)
    postprocess = postprocess()

    quote do
      unquote(prepare)
      unquote(postprocess)
    end
  end

  defmacro shared(block) do
    prepare = prepare_block(nil, block)
    postprocess = postprocess()

    quote do
      @depends_on __MODULE__
      unquote(prepare)
      unquote(postprocess)
    end
  end

  defp prepare_block(name, block) do
    quote do
      @name unquote(name)
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :fields_struct, accumulate: true)
      Module.register_attribute(__MODULE__, :fields_data, accumulate: true)
      Module.register_attribute(__MODULE__, :depends_on_modules, accumulate: true)

      import Graphd.Node
      unquote(block)
    end
  end

  defp postprocess() do
    quote unquote: false do
      defstruct [:uid | @fields_struct]

      fields = Enum.reverse(@fields)
      source = @name
      alter = Graphd.Node.__schema_alter___(__MODULE__, source)

      def __schema__(:source), do: unquote(source)
      def __schema__(:fields), do: unquote(fields)
      def __schema__(:alter), do: unquote(Macro.escape(alter))
      def __schema__(:depends_on), do: unquote(Graphd.Node.__depends_on_modules__(__MODULE__))

      for %Graphd.Field{name: name, db_name: db_name, type: type, unique: unique, required: required} <- @fields_data do
        def __schema__(:type, unquote(name)), do: unquote(type)
        def __schema__(:field, unquote(name)), do: unquote(db_name)
        def __schema__(:field, unquote(db_name)), do: {unquote(name), unquote(type)}
        def __schema__(:unique, unquote(name)), do: unquote(unique)
        def __schema__(:required, unquote(name)), do: unquote(required)
      end

      def __schema__(:type, _), do: nil
      def __schema__(:field, _), do: nil
      def __schema__(:unique, _), do: false
      def __schema__(:required, _), do: false

      unique_fields = Graphd.Node.__unique_fields__(@fields_data)
      def __schema__(:unique_fields), do: unquote(Macro.escape(unique_fields))

      required_fields = Graphd.Node.__required_fields__(@fields_data)
      def __schema__(:required_fields), do: unquote(Macro.escape(required_fields))

      changeset = Graphd.Node.__gen_changeset__(@fields_data)
      def __changeset__(), do: unquote(Macro.escape(changeset))
    end
  end

  @doc false
  def __schema_alter___(module, source) do
    preds =
      module
      |> Module.get_attribute(:fields_data)
      |> Enum.flat_map(&List.wrap(&1.alter))
      |> Enum.reverse()

    type_fields =
      module
      |> Module.get_attribute(:fields_data)
      |> Enum.map(fn fdata ->
        %{
          "name" => fdata.db_name,
          "type" => db_type(fdata.type)
        }
      end)

    type = %{"name" => source, "fields" => type_fields}

    %{
      "types" => List.wrap(type),
      "schema" => preds
    }
  end

  @doc false
  def __depends_on_modules__(module) do
    depends_on_module = module |> Module.get_attribute(:depends_on) |> List.wrap()
    :lists.usort(depends_on_module ++ Module.get_attribute(module, :depends_on_modules))
  end

  @doc false
  def __unique_fields__(fields) do
    for %Graphd.Field{name: name, unique: unique} <- fields, unique != false, into: [], do: name
  end

  @doc false
  def __required_fields__(fields) do
    for %Graphd.Field{name: name, required: required} <- fields, required != false, into: [], do: name
  end

  @doc false
  def __gen_changeset__(fields) do
    for %Graphd.Field{name: name, type: type, opts: opts} <- fields, into: %{}, do: {name, ecto_type(type, opts[:list])}
  end

  defp ecto_type(type, list) do
    typ = do_ecto_type(type)

    case list do
      true -> {:array, typ}
      _ -> typ
    end
  end

  defp do_ecto_type(:datetime), do: :utc_datetime
  defp do_ecto_type(type), do: type

  defmacro field(name, type, opts \\ []) do
    quote do
      Graphd.Node.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts), @depends_on)
    end
  end

  defmacro has_many(name, type, opts \\ []) do
    quote do
      Graphd.Node.__field__(__MODULE__, unquote(name), unquote(type), [list: true] ++ unquote(opts), @depends_on)
    end
  end

  @doc false
  def __field__(module, name, type, opts, depends_on) do
    type =
      case type do
        :uid -> Graphd.DataType.UID
        :geo -> Graphd.DataType.Geo
        :password -> Graphd.DataType.Password
        _ -> type
      end

    schema_name = Module.get_attribute(module, :name)
    Module.put_attribute(module, :fields_struct, {name, opts[:default]})

    unless opts[:virtual] do
      Module.put_attribute(module, :fields, name)

      {db_name, type, alter} = db_field(name, type, opts, schema_name, module, depends_on)
      {unique, opts} = Keyword.pop(opts, :unique, false)
      {required, opts} = Keyword.pop(opts, :required, false)
      field = %Field{name: name, type: type, db_name: db_name, unique: unique, required: required, alter: alter, opts: opts}
      Module.put_attribute(module, :fields_data, field)
    end
  end

  defp db_field(name, type, opts, schema_name, module, depends_on) do
    if depends_on = opts[:depends_on] || depends_on do
      put_attribute_if_not_exists(module, :depends_on_modules, depends_on)

      with {:error, error} <- Code.ensure_compiled(depends_on),
           do: raise("Module `#{depends_on}` not available, error: #{error}")

      field_name = Atom.to_string(name)

      if module == depends_on do
        {field_name, type, alter_field(field_name, type, opts)}
      else
        {field_name, depends_on.__schema__(:type, name), nil}
      end
    else
      field_name = "#{schema_name}.#{name}"
      {field_name, type, alter_field(field_name, type, opts)}
    end
  end

  defp put_attribute_if_not_exists(module, key, value) do
    unless module |> Module.get_attribute(key) |> Enum.member?(value),
      do: Module.put_attribute(module, key, value)
  end

  defp alter_field(field_name, type, opts) do
    basic_alter = %{
      "predicate" => field_name,
      "type" => db_type(type, opts[:list])
    }

    opts |> Enum.flat_map(&gen_opt(&1, type)) |> Enum.into(basic_alter)
  end

  @types_mapping [
    integer: "int",
    float: "float",
    string: "string",
    geo: "geo",
    datetime: "datetime",
    uid: "uid",
    password: "password"
  ]

  for {type, dgraph_type} <- @types_mapping do
    defp primitive_type(unquote(type)), do: unquote(dgraph_type)
  end

  @primitive_types Keyword.keys(@types_mapping)
  def primitive_type?(type), do: type in @primitive_types

  defp db_type(type, list \\ nil) do
    typ = if primitive_type?(type), do: primitive_type(type), else: primitive_type(type.type)

    case list do
      true -> "[#{typ}]"
      _ -> typ
    end
  end

  @ignore_keys [:default, :depends_on, :list, :unique, :required]
  defp gen_opt({key, _value}, _type) when key in @ignore_keys, do: []
  defp gen_opt({:index, true}, type), do: [{"index", true}, {"tokenizer", [db_type(type)]}]

  defp gen_opt({:index, tokenizers}, :string) when is_list(tokenizers),
    do: [{"index", true}, {"tokenizer", tokenizers}]

  defp gen_opt({key, value}, _type), do: [{Atom.to_string(key), value}]
end
