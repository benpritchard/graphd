alias Graphd.Api

defmodule Api.Dgraph.Stub do
  @moduledoc false
  use GRPC.Stub, service: Api.Dgraph.Service
end
