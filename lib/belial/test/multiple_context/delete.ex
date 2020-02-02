defmodule Belial.Test.MultipleContext.Delete do
  @moduledoc """
  Adds a test helper for delete functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  defp fn_desc(context, singular) do
    "FUNCTION: #{context}.delete_#{singular}/1"
  end

  def test(context, schema, singular) do
    test_delete_with_valid_params(context, schema, singular)
  end

  defp test_delete_with_valid_params(context, schema, singular) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    delete_return = apply(context, :"delete_#{singular}", [factory.insert(resource_atom)])

    ExUnit.Assertions.assert(
      {:ok, %^schema{}} = delete_return,
      "#{fn_desc(context, singular)} failed to delete correctly"
    )
  end
end
