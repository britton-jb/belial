defmodule Belial.Test.SingularContext.GetBy do
  @moduledoc """
  Adds a test helper for get_by functions defined by the SingularContext
  """
  require ExUnit.Assertions

  @arbitrary_high_id 999_999

  defp fn_desc(context) do
    "FUNCTION: #{context}.get_by/1\n"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    inserted = factory.insert(resource_atom)
    test_getting_inserted(context, schema, inserted)
    test_getting_nonexistant(context, schema)
  end

  defp test_getting_inserted(context, schema, inserted) do
    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(inserted, primary_key)

    actual =
      %{primary_key => expected}
      |> context.get_by!()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(expected)}"
    )
  end

  defp test_getting_nonexistant(context, schema) do
    primary_key = Belial.Schema.get_primary_key(schema)
    actual = context.get_by(%{primary_key => @arbitrary_high_id})
    expected = nil

    ExUnit.Assertions.assert(
      is_nil(actual),
      "#{fn_desc(context)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected} \nfor #{
        primary_key
      } == #{@arbitrary_high_id}"
    )
  end
end
