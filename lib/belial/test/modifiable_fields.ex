defmodule Belial.Test.ModifiableFields do
  @moduledoc """
  Adds a test helper for tests which fields can be modified by a changeset
  """
  require ExUnit.Assertions
  @modifiable_fields_module Application.get_env(:belial, :modifiable_fields)
  @error_message "
  Must define a :belail :modifiable_field_module in config.exs or pass it into
  Belial.Test.ModifiableFields.test/4
  "

  @spec test(module, [atom], module, atom) :: Macro.t()
  def test(
        module,
        expected_fields,
        passed_modifiable_fields_module \\ nil,
        changeset_fn_atom \\ :changeset
      ) do
    using_modifiable_field_module =
      case {is_nil(passed_modifiable_fields_module), is_nil(@modifiable_fields_module)} do
        {true, true} -> raise @error_message
        {true, false} -> @modifiable_fields_module
        {false, _} -> passed_modifiable_fields_module
      end

    params =
      :fields
      |> module.__schema__()
      |> Enum.reduce(%{}, fn field, acc ->
        modifiable_value =
          using_modifiable_field_module.change_value_for_field(module.__schema__(:type, field))

        Map.put(
          acc,
          field,
          modifiable_value
        )
      end)

    changed_fields =
      module
      |> apply(changeset_fn_atom, [struct!(module), params])
      |> Map.get(:changes)
      |> Map.keys()
      |> MapSet.new()

    actual =
      expected_fields
      |> MapSet.new()
      |> MapSet.difference(changed_fields)

    expected = MapSet.new()

    ExUnit.Assertions.assert(
      actual == expected,
      "ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(expected)}"
    )
  end
end
