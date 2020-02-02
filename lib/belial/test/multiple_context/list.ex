defmodule Belial.Test.MultipleContext.List do
  @moduledoc """
  Adds a test helper for list functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  defp fn_desc(context, plural) do
    "FUNCTION: #{context}.list_#{plural}/1\n"
  end

  def test(context, schema, plural) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    inserted = factory.insert(resource_atom)
    test_list_inserted(context, schema, plural, inserted)
  end

  defp test_list_inserted(context, schema, plural, inserted) do
    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(inserted, primary_key)

    actual =
      context
      |> apply(:"list_#{plural}", [])
      |> List.first()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context, plural)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )
  end
end
