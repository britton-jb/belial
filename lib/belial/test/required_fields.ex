defmodule Belial.Test.RequiredFields do
  @moduledoc """
  Adds a test helper for required fields
  """
  # credo:disable-for-this-file Credo.Check.Readability.Specs
  require ExUnit.Assertions

  def test(
        schema_module,
        required_fields,
        changeset_fn \\ :changeset,
        error_message \\ "can't be blank"
      )

  def test(schema_module, required_fields, changeset_fn, error_message)
      when is_atom(changeset_fn) do
    errors =
      schema_module
      |> apply(changeset_fn, [struct!(schema_module), %{}])
      |> Map.get(:errors)
      |> Keyword.take(required_fields)

    expected_errors =
      Enum.map(required_fields, fn field ->
        {field, {error_message, [validation: :required]}}
      end)

    ExUnit.Assertions.assert(
      errors == expected_errors,
      "ACTUAL:   #{inspect(errors)} \nEXPECTED: #{inspect(expected_errors)}"
    )
  end

  def test(schema_module, required_fields, non_default_error_message, _) do
    test(schema_module, required_fields, :changeset, non_default_error_message)
  end
end
