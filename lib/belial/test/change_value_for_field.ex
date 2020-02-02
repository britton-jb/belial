defmodule Belial.Test.ChangeValueForField do
  @moduledoc """
  Module definition for allowing us to have an
  overridable change value for
  an `Ecto.Schema` field type used by `Belial.Test.ModifiableFields`.
  """

  @doc """
  Allows us to specify a change value for an Ecto.Schema field type.
  """
  defmacro __using__(_opts) do
    quote do
      def change_value_for_field(:id), do: 999
      def change_value_for_field(:naive_datetime), do: DateTime.utc_now()
      def change_value_for_field(:map), do: %{}
      def change_value_for_field(:string), do: "string"

      defoverridable change_value_for_field: 1
    end
  end
end
