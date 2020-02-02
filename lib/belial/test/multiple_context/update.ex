defmodule Belial.Test.MultipleContext.Update do
  @moduledoc """
  Adds a test helper for update functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  defp fn_desc(context, singular) do
    "FUNCTION: #{context}.update_#{singular}/1"
  end

  def test(context, schema, singular) do
    test_update_with_valid_params(context, schema, singular)
  end

  defp test_update_with_valid_params(context, schema, singular) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    update_return = apply(context, :"update_#{singular}", [factory.insert(resource_atom), %{}])

    ExUnit.Assertions.assert(
      {:ok, %^schema{}} = update_return,
      "#{fn_desc(context, singular)} failed to update correctly"
    )
  end
end
