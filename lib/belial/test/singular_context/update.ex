defmodule Belial.Test.SingularContext.Update do
  @moduledoc """
  Adds a test helper for update functions defined by the SingularContext
  """
  require ExUnit.Assertions

  defp fn_desc(context) do
    "FUNCTION: #{context}.update/2"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()
    test_update_with_valid_params(context, schema, factory, resource_atom)
  end

  defp test_update_with_valid_params(context, schema, factory, resource_atom) do
    update_return =
      resource_atom
      |> factory.insert()
      |> context.update(%{})

    ExUnit.Assertions.assert(
      {:ok, %^schema{}} = update_return,
      "#{fn_desc(context)} failed to update correctly"
    )
  end
end
