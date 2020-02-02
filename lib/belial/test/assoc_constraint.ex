defmodule Belial.Test.AssocConstraint do
  @moduledoc """
  Adds a test helper for assoc constraints
  """
  # credo:disable-for-this-file Credo.Check.Readability.Specs
  alias Belial.Test.AssocConstraint.{BelongsTo, Has}
  require ExUnit.Assertions

  def test(module, assoc_atom, changeset_fn \\ :changeset)

  def test(_, [], _), do: nil

  def test(module, [head | tail], changeset_fn) do
    test(module, head, changeset_fn)
    test(module, tail, changeset_fn)
  end

  def test(module, assoc_atom, changeset_fn) do
    forward_to_appropriate_test(module, assoc_atom, changeset_fn)
  end

  def test_all(module, changeset_fn \\ :changeset) do
    Enum.each(module.__schema__(:associations), fn assoc_atom ->
      forward_to_appropriate_test(module, assoc_atom, changeset_fn)
    end)
  end

  defp forward_to_appropriate_test(module, assoc_atom, changeset_fn) do
    case module.__schema__(:association, assoc_atom).__struct__ do
      Ecto.Association.BelongsTo -> BelongsTo.test(module, assoc_atom, changeset_fn)
      Ecto.Association.Has -> Has.test(module, assoc_atom, changeset_fn)
      _ -> nil
    end
  end
end
