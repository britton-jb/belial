defmodule Belial.Test.DefaultValue do
  @moduledoc """
  Adds a test helper for default values on fields
  """
  # credo:disable-for-this-file Credo.Check.Readability.Specs
  require ExUnit.Assertions

  def test(schema_module, default_field_map) do
    actual =
      schema_module
      |> struct!()
      |> Map.take(Map.keys(default_field_map))
      |> Map.values()

    expected = Map.values(default_field_map)

    ExUnit.Assertions.assert(
      actual == expected,
      "ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(expected)}"
    )
  end
end
