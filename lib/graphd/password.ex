defmodule Graphd.Password do
  use Ecto.Type

  @impl true
  def type(), do: :password

  @impl true
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_), do: :error

  @impl true
  def load(value) when is_binary(value), do: {:ok, value}
  def load(_), do: :error

  @impl true
  def dump(value) when is_binary(value), do: {:ok, value}
  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error
end
