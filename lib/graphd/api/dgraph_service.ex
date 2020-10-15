alias Graphd.Api

defmodule Api.Dgraph.Service do
  @moduledoc false
  use GRPC.Service, name: "api.Dgraph"

  rpc(:Login, Api.LoginRequest, Api.Response)
  rpc(:Query, Api.Request, Api.Response)
  rpc(:Alter, Api.Operation, Api.Payload)
  rpc(:CommitOrAbort, Api.TxnContext, Api.TxnContext)
  rpc(:CheckVersion, Api.Check, Api.Version)
end
