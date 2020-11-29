defmodule Graphd.Field do
  @type type :: :integer | :float | :string | :geo | :datetime | :uid | :auto

  @type t :: %__MODULE__{
          name: atom(),
          type: type(),
          db_name: String.t(),
          unique: list() | nil,
          required: true | false,
          alter: map() | nil,
          opts: Keyword.t()
        }

  defstruct [:name, :type, :db_name, :unique, :required, :alter, :opts]
end
