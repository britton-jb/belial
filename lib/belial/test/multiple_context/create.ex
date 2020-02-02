defmodule Belial.Test.MultipleContext.Create do
  @moduledoc """
  Adds a test helper for create functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  defp fn_desc(context, singular) do
    "FUNCTION: #{context}.create_#{singular}/1"
  end

  def test(context, schema, singular) do
    test_create_with_valid_params(context, schema, singular)
    test_create_with_invalid_params(context, singular)
  end

  defp test_create_with_valid_params(context, schema, singular) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    create_return =
      apply(context, :"create_#{singular}", [factory.params_with_assocs(resource_atom)])

    ExUnit.Assertions.assert(
      {:ok, %^schema{}} = create_return,
      "#{fn_desc(context, singular)} failed to create correctly"
    )
  end

  defp test_create_with_invalid_params(context, singular) do
    create_return = apply(context, :"create_#{singular}", [%{}])

    ExUnit.Assertions.assert(
      {:error, %Ecto.Changeset{}} = create_return,
      "#{fn_desc(context, singular)} created correctly when failure was expected"
    )
  end
end
