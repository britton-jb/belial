defmodule Belial.Test.SingularContext.GetBang do
  @moduledoc """
  Adds a test helper for get! functions defined by the SingularContext
  """
  require ExUnit.Assertions

  @arbitrary_high_id 999_999

  defp fn_desc(context) do
    "FUNCTION: #{context}.get!/1\n"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    inserted = factory.insert(resource_atom)
    test_getting_inserted(context, schema, inserted)
    test_getting_nonexistant(context)
  end

  defp test_getting_inserted(context, schema, inserted) do
    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(inserted, primary_key)

    actual =
      expected
      |> context.get!()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )
  end

  defp test_getting_nonexistant(context) do
    try do
      context.get!(@arbitrary_high_id)
    rescue
      _ in Ecto.NoResultsError ->
        ExUnit.Assertions.assert(true)

      error in _ ->
        %actual{} = error
        expected = Ecto.NoResultsError

        ExUnit.Assertions.flunk(
          "#{fn_desc(context)} ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
        )
    end
  end
end
