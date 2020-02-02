defmodule Belial.Test.UniqueConstraint do
  @moduledoc """
  Adds a test helper for unique constraints
  """
  # credo:disable-for-this-file Credo.Check.Readability.Specs
  alias Belial.Test.ErrorsOn
  require ExUnit.Assertions

  @default_error_message "has already been taken"

  @doc """
  Takes in an ExMachina factory module, an atom representing the ExMachina
  factory to use, one of the following respresenations of fields to uniq by
  and an error message, which defaults to #{@default_error_message}

  Valid representations:
  Single atom: :field
  Single assoc as tuple: {:assoc, :assoc_fk}
  List of atoms: [:first, :second]
  List of assoc tuples: [{:assoc1, :assoc1_fk}, {:assoc2, :assoc2_fk}]
  Mixed lists: [{:assoc, :assoc_fk}, :second]
  Lists of lists, useful for exclusive_belongs_to type relationships:
    [
      [{:assoc1, :assoc1_fk}, {:assoc2, :assoc2_fk}],
      [{:assoc1, :assoc1_fk}, {:assoc3, :assoc3_fk}]
    ]
  """
  def test(module, fields, error_message \\ @default_error_message)

  def test(_module, [], _error_message), do: nil

  def test(module, fields, error_message) do
    first = module.__test_factory().insert(module.__test_resource_atom())

    duplicated_params =
      module.__test_factory().params_with_assocs(
        module.__test_resource_atom(),
        Map.from_struct(first)
      )

    duplicated = module.changeset(struct!(module), duplicated_params)

    error_field = get_error_field(fields)
    expected = %{error_field => [error_message]}

    actual =
      case module.__test_repo().insert(duplicated) do
        {:error, changeset} ->
          changeset
          |> ErrorsOn.transform()

        unexpected ->
          unexpected
      end

    ExUnit.Assertions.assert(
      actual == expected,
      "ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(expected)}"
    )
  end

  defp get_error_field(field) when is_atom(field), do: field
  defp get_error_field({_assoc, assoc_id}), do: assoc_id
  defp get_error_field([{field, _} | _tail]), do: field
  defp get_error_field([[{field, _} | _inner_tail] | _tail]), do: field
  defp get_error_field([field | _tail]), do: field
end
