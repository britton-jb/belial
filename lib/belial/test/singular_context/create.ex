defmodule Belial.Test.SingularContext.Create do
  @moduledoc """
  Adds a test helper for create functions defined by the SingularContext
  """
  require ExUnit.Assertions

  defp fn_desc(context) do
    "FUNCTION: #{context}.create/1"
  end

  def test(context, schema) do
    factory = schema.__test_factory()
    resource_atom = schema.__test_resource_atom()

    test_create_with_valid_params(context, schema, factory, resource_atom)
    test_create_with_invalid_params(context)
  end

  defp test_create_with_valid_params(context, schema, factory, resource_atom) do
    create_return =
      resource_atom
      |> factory.params_with_assocs()
      |> context.create()

    ExUnit.Assertions.assert(
      {:ok, %^schema{}} = create_return,
      "#{fn_desc(context)} failed to create correctly"
    )
  end

  defp test_create_with_invalid_params(context) do
    create_return = context.create(%{})

    ExUnit.Assertions.assert(
      {:error, %Ecto.Changeset{}} = create_return,
      "#{fn_desc(context)} created correctly when failure was expected"
    )
  end
end
