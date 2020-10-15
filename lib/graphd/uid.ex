defmodule Graphd.UID do
  use Ecto.Type
  defstruct uid: nil

  @impl true
  def type(), do: :uid

  @impl true
  def cast(maps) when is_list(maps), do: {:ok, maps}
  def cast(map) when is_map(map), do: {:ok, map}
  def cast(_), do: :error

  @doc """
  Here for completenesses sake, but be aware that this is by-passed by
  the Repo module so we can let it pass the full correctly typed node
  object (eg %User{}) back through rather than just pulling out the uid
  because that's very useful!
  """
  @impl true
  def load(maps) when is_list(maps) do
    {:ok, Enum.map(maps, fn map -> %__MODULE__{uid: Map.get(map, "uid")} end)}
  end

  def load(%{"uid" => uid}) do
    {:ok, %__MODULE__{uid: uid}}
  end

  @doc """
  Takes either a list of Node object maps or a single Node object map
  and strips out everything but the uid. This prevents us from setting
  values on the linked node accidentally (or on purpose).
  """
  @impl true
  def dump(maps) when is_list(maps) do
    {:ok, Enum.map(maps, fn map -> %{uid: Map.get(map, :uid)} end)}
  end

  def dump(%__MODULE__{uid: uid}) do
    {:ok, %{uid: uid}}
  end

  def dump(""), do: {:ok, nil}
  def dump(nil), do: {:ok, nil}
  def dump(_), do: :error
end
