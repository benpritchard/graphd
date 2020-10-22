defmodule Graphd.TestHelper do
  @graphd_adapter :"#{System.get_env("GRAPHD_ADAPTER", "grpc")}"
  @offset String.to_integer(System.get_env("GRAPHD_PORT_OFFSET", "2"))

  def opts() do
    case @graphd_adapter do
      :http -> [transport: :http, port: 8080 + @offset]
      :grpc -> [transport: :grpc, port: 9080 + @offset]
    end
  end

  def drop_all(pid) do
    Graphd.alter(pid, %{drop_all: true})
  end

  def adapter(), do: @graphd_adapter
end

defmodule Graphd.Geo do
  use Ecto.Type
  defstruct lon: 0.0, lat: 0.0

  @impl true
  def type(), do: :geo

  @impl true
  def cast(%{lat: lat, lon: lon}), do: {:ok, %__MODULE__{lat: lat, lon: lon}}
  def cast(_), do: :error

  @impl true
  def load(%{"type" => "Point", "coordinates" => [lat, lon]}) do
    {:ok, %__MODULE__{lat: lat, lon: lon}}
  end

  @impl true
  def dump(%__MODULE__{lat: lat, lon: lon}) do
    {:ok, %{"type" => "Point", "coordinates" => [lat, lon]}}
  end

  def dump(_), do: :error
end

defmodule Graphd.User do
  use Graphd.Node

  schema "user" do
    field(:email, :string, index: ["exact"])
    field(:name, :string, index: ["term"])
    field(:nickname, :string)
    field(:age, :integer)
    field(:friends, Graphd.UID)
    field(:location, Graphd.Geo)
    field(:cache, :any, virtual: true)
  end
end

defmodule Graphd.TestRepo do
  use Graphd.Repo, otp_app: :graphd, modules: [Graphd.User]
end

to_skip =
  case Graphd.TestHelper.adapter() do
    :http -> [:grpc]
    :grpc -> [:http]
  end

{:ok, _} = Application.ensure_all_started(:grpc)
ExUnit.start(exclude: [:skip | to_skip])
