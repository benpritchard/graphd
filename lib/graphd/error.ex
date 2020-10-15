defmodule Graphd.Error do
  @moduledoc """
  Dgraph or connection error are wrapped in Graphd.Error.
  """
  defexception [:reason, :action]

  @type t :: %Graphd.Error{}

  @impl true
  def message(%{action: action, reason: reason}) do
    "#{action} failed with #{inspect(reason)}"
  end
end
