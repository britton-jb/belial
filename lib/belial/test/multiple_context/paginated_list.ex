defmodule Belial.Test.MultipleContext.PaginatedList do
  @moduledoc """
  Adds a test helper for paginated_list functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  defp fn_desc(context, plural) do
    "FUNCTION: #{context}.paginated_list_#{plural}/2\n"
  end

  def test(context, schema, plural) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    inserted = factory.insert(resource_atom)
    test_list_inserted(context, schema, plural, inserted)
    test_list_inserted_filtered_by_map(context, schema, plural)
  end

  defp test_list_inserted(context, schema, plural, inserted) do
    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(inserted, primary_key)

    actual =
      context
      |> apply(:"paginated_list_#{plural}", [])
      |> Map.get(:entries)
      |> List.last()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context, plural)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )
  end

  defp test_list_inserted_filtered_by_map(context, schema, plural) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    first = factory.insert(resource_atom)
    _second = factory.insert(resource_atom)

    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(first, primary_key)

    entries =
      context
      |> apply(:"paginated_list_#{plural}", [%{primary_key => Map.get(first, primary_key)}])
      |> Map.get(:entries)

    ExUnit.Assertions.assert(
      length(entries) == 1,
      "#{fn_desc(context, plural)}RETURNED MULTIPLE ENTRIES"
    )

    actual =
      entries
      |> List.last()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context, plural)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )

    entries =
      context
      |> apply(:"paginated_list_#{plural}", [%{primary_key => [Map.get(first, primary_key)]}])
      |> Map.get(:entries)

    ExUnit.Assertions.assert(
      length(entries) == 1,
      "#{fn_desc(context, plural)}RETURNED MULTIPLE ENTRIES"
    )

    actual =
      entries
      |> List.last()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context, plural)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )
  end
end
