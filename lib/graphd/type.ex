defmodule Graphd.Type do
  @moduledoc false

  @type request :: term
  @type json_lib :: module

  @callback describe(Graphd.Query.t(), Keyword.t()) :: Graphd.Query.t()
  @callback encode(Graphd.Query.t(), map, Keyword.t()) :: struct
  @callback decode(Graphd.Query.t(), term, Keyword.t()) :: term

  @callback execute(module(), GRPC.Channel.t(), request, json_lib, opts :: Keyword.t()) ::
              {:ok, struct} | {:error, GRPC.RPCError.t()}

  @doc """
  Execute request
  """
  @spec execute(module(), GRPC.Channel.t(), Graphd.Query.t(), struct, Keyword.t()) ::
          {:ok, struct} | {:error, GRPC.RPCError.t()}
  def execute(adapter, channel, %{type: type, json: json_lib} = _query, request, opts),
    do: type.execute(adapter, channel, request, json_lib, opts)

  @doc """
  Describe query according to options
  """
  @spec describe(Graphd.Query.t(), Keyword.t()) :: struct
  def describe(%{type: type} = query, opts), do: type.describe(query, opts)

  @doc """
  Encode query according to options
  """
  @spec encode(Graphd.Query.t(), map, Keyword.t()) :: struct
  def encode(%{type: type} = query, parameters, opts), do: type.encode(query, parameters, opts)

  @doc """
  Decode query according to options
  """
  @spec decode(Graphd.Query.t(), struct, Keyword.t()) :: term
  def decode(%{type: type} = query, result, opts), do: type.decode(query, result, opts)
end
