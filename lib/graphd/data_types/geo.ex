defmodule Graphd.DataType.Geo do
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
