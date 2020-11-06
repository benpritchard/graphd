defmodule Graphd.DataType.UID do
  use Ecto.Type
  defstruct uid: nil

  @impl true
  def type(), do: :uid

  @impl true
  def cast(map) when is_map(map), do: {:ok, map}
  def cast(_), do: :error

  @impl true
  def load(%{"uid" => uid}) do
    {:ok, %__MODULE__{uid: uid}}
  end

  def load(_), do: :error

  @doc """
  Takes either a Node object map
  and strips out everything but the uid. This prevents us from setting
  values on the linked node accidentally (or on purpose).
  """
  @impl true
  def dump(%{uid: uid}) do
    {:ok, %{uid: uid}}
  end

  def dump(""), do: {:ok, nil}
  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error
end
