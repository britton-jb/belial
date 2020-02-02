defmodule Belial.Web.Absinthe.Scalar.NaiveDatetime do
  use Absinthe.Schema.Notation

  @desc """
  The `NaiveDateTime` scalar type represents a date and time without timezone.
  """
  scalar :naive_datetime, name: "NaiveDateTime" do
    serialize(fn date -> date end)
    parse(&parse_datetime/1)
  end

  @spec parse_datetime(Absinthe.Blueprint.Input.String.t()) ::
          {:ok, NaiveDateTime.t() | nil} | :error
  defp parse_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, datetime} -> {:ok, datetime}
      _error -> :error
    end
  end

  defp parse_datetime(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}

  defp parse_datetime(_), do: :error
end
