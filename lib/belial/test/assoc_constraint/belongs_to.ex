defmodule Belial.Test.AssocConstraint.BelongsTo do
  @moduledoc """
  Adds a test helper for `Ecto.Association.BelongsTo` assoc constraints
  """
  alias Belial.Test.ErrorsOn

  @arbitrary_fk_value 999_999
  @assoc_constraint_messages MapSet.new(["can't be blank", "does not exist"])

  def test(module, list_or_atom, changeset_fn \\ :changeset)
  def test(_, [], _), do: nil

  def test(module, [head | tail], changeset_fn) do
    test(module, head, changeset_fn)
    test(module, tail, changeset_fn)
  end

  def test(module, assoc_atom, changeset_fn) do
    do_test(module.__schema__(:association, assoc_atom), changeset_fn)
  end

  defp do_test(
         %Ecto.Association.BelongsTo{owner: owner, field: field} = ecto_assoc,
         changeset_fn
       ) do
    params =
      owner.__test_resource_atom()
      |> owner.__test_factory.params_with_assocs()
      |> Map.merge(%{
        ecto_assoc.owner_key => @arbitrary_fk_value
      })

    changeset = apply(owner, changeset_fn, [struct!(owner), params])

    case owner.__test_repo.insert(changeset) do
      {:error, invalid_changeset} ->
        actual_mapset =
          invalid_changeset
          |> ErrorsOn.transform()
          |> Map.get(field, %{})
          |> MapSet.new()

        @assoc_constraint_messages
        |> MapSet.intersection(actual_mapset)
        |> Enum.any?()
        |> ExUnit.Assertions.assert(
          "ACTUAL:   #{inspect(invalid_changeset.errors)} \nEXPECTED: #{
            inspect(@assoc_constraint_messages |> MapSet.to_list() |> Enum.join(" OR "))
          }"
        )

      _actual ->
        ExUnit.Assertions.assert(
          false,
          "Failing assoc: #{inspect(field)} on #{inspect(owner)} \nCHANGESET: #{
            inspect(changeset)
          }\nASSOC: #{inspect(ecto_assoc)}"
        )
    end
  end
end
