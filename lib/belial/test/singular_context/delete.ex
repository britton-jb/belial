defmodule Belial.Test.SingularContext.Delete do
  @moduledoc """
  Adds a test helper for delete functions defined by the SingularContext
  """
  require ExUnit.Assertions

  defp fn_desc(context) do
    "FUNCTION: #{context}.delete/1"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    test_delete_with_valid_params(context, schema, factory, resource_atom)
  end

  defp test_delete_with_valid_params(context, schema, factory, resource_atom) do
    delete_return =
      resource_atom
      |> factory.insert()
      |> context.delete()

    ExUnit.Assertions.assert(
      {:ok, %^schema{}} = delete_return,
      "#{fn_desc(context)} failed to delete correctly"
    )
  end
end
