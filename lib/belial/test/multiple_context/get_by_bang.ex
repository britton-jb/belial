defmodule Belial.Test.MultipleContext.GetByBang do
  @moduledoc """
  Adds a test helper for get_by! functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  @arbitrary_high_id 999_999

  defp fn_desc(context, singular) do
    "FUNCTION: #{context}.get_#{singular}_by!/1\n"
  end

  def test(context, schema, singular) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    inserted = factory.insert(resource_atom)
    test_getting_inserted(context, schema, singular, inserted)
    test_getting_nonexistant(context, schema, singular)
  end

  defp test_getting_inserted(context, schema, singular, inserted) do
    primary_key = Belial.Schema.get_primary_key(schema)
    expected = Map.get(inserted, primary_key)

    actual =
      context
      |> apply(:"get_#{singular}_by!", [%{primary_key => expected}])
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context, singular)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )
  end

  defp test_getting_nonexistant(context, schema, singular) do
    primary_key = Belial.Schema.get_primary_key(schema)

    try do
      apply(context, :"get_#{singular}_by!", [%{primary_key => @arbitrary_high_id}])
    rescue
      _ in Ecto.NoResultsError ->
        ExUnit.Assertions.assert(true)

      error in _ ->
        %actual{} = error
        expected = Ecto.NoResultsError

        ExUnit.Assertions.flunk(
          "#{fn_desc(context, singular)} ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
        )
    end
  end
end
