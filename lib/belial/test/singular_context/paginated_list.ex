defmodule Belial.Test.SingularContext.PaginatedList do
  @moduledoc """
  Adds a test helper for paginated_list functions defined by the SingularContext
  """
  require ExUnit.Assertions

  defp fn_desc(context) do
    "FUNCTION: #{context}.paginated_list/2\n"
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
      context.paginated_list()
      |> Map.get(:entries)
      |> List.last()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(expected)}"
    )
  end
end
