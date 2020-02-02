defmodule Belial.Test.SingularContext.List do
  @moduledoc """
  Adds a test helper for list functions defined by the SingularContext
  """
  require ExUnit.Assertions

  defp fn_desc(context) do
    "FUNCTION: #{context}.list/1\n"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    inserted = factory.insert(resource_atom)
    test_listing_inserted(context, schema, inserted)
  end

  defp test_listing_inserted(context, schema, inserted) do
    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(inserted, primary_key)

    actual =
      context.list()
      |> List.first()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(expected)}"
    )
  end
end
