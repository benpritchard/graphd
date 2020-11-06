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

defmodule Graphd.User do
  use Graphd.Node

  schema "user" do
    field :email, :string, index: ["exact"]
    field :name, :string, index: ["term"]
    field :password, :password
    field :nickname, :string
    field :age, :integer
    has_many :friends, :uid
    field :location, :geo
    has_many :destinations, :geo
    field :referrer, :uid
    field :cache, :any, virtual: true
    has_many :tags, :string
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
