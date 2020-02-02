defmodule Belial.Test.SingularContext.GetByBang do
  @moduledoc """
  Adds a test helper for get_by! functions defined by the SingularContext
  """
  require ExUnit.Assertions

  @arbitrary_high_id 999_999

  defp fn_desc(context) do
    "FUNCTION: #{context}.get_by!/1\n"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()
    inserted = factory.insert(resource_atom)
    primary_key = Belial.Schema.get_primary_key(schema)

    test_getting_inserted(context, inserted, primary_key)
    test_getting_nonexistant(context, primary_key)
  end

  defp test_getting_inserted(context, inserted, primary_key) do
    expected = Map.get(inserted, primary_key)

    actual =
      %{primary_key => expected}
      |> context.get_by!()
      |> Map.get(primary_key)

    ExUnit.Assertions.assert(
      actual == expected,
      "#{fn_desc(context)}ACTUAL:   #{inspect(actual)} \nEXPECTED: #{expected}"
    )
  end

  defp test_getting_nonexistant(context, primary_key) do
    try do
      context.get_by!(%{primary_key => @arbitrary_high_id})
    rescue
      _ in Ecto.NoResultsError ->
        ExUnit.Assertions.assert(true)

      error in _ ->
        %struct{} = error

        ExUnit.Assertions.flunk(
          "#{fn_desc(context)}Expected Ecto.NoResultsError, received #{struct}"
        )
    end
  end
end
