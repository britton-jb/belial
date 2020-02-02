defmodule Belial.Test.AssocConstraint.Has do
  @moduledoc """
  Adds a test helper for `Ecto.Association.Has` assoc constraints
  """
  require ExUnit.Assertions

  @expected {:constraint, :foreign}

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
         %Ecto.Association.Has{
           owner: owner,
           owner_key: owner_key,
           field: field,
           related: related,
           related_key: related_key
         } = ecto_assoc,
         changeset_fn
       ) do
    inserted_owner = owner.__test_factory().insert(owner.__test_resource_atom())

    related_field =
      :associations
      |> related.__schema__()
      |> Enum.map(&related.__schema__(:association, &1))
      |> Enum.find(&(&1.related == owner))
      |> Map.get(:field)

    _inserted_related =
      related.__test_factory().insert(
        related.__test_resource_atom(),
        "#{related_key}": Map.get(inserted_owner, owner_key),
        "#{related_field}": inserted_owner
      )

    changeset = apply(owner, changeset_fn, [inserted_owner, %{}])

    case owner.__test_repo.delete(changeset) do
      {:error, %Ecto.Changeset{errors: errors} = unexpected_changeset} ->
        actual =
          errors
          |> Keyword.get(field)
          |> elem(1)
          |> List.first()

        fk_constraint_error? = actual == @expected

        ExUnit.Assertions.assert(
          fk_constraint_error?,
          "ACTUAL:   #{inspect(actual)} \nEXPECTED: #{inspect(@expected)}
          \nFailing assoc: #{inspect(ecto_assoc.field)} on #{inspect(ecto_assoc.owner)} \nCHANGESET: #{
            inspect(unexpected_changeset)
          }\nASSOC: #{inspect(ecto_assoc)}"
        )

      _actual ->
        ExUnit.Assertions.assert(
          false,
          "Failing assoc: #{inspect(ecto_assoc.field)} on #{inspect(ecto_assoc.owner)} \nCHANGESET: #{
            inspect(changeset)
          }\nASSOC: #{inspect(ecto_assoc)}"
        )
    end
  end
end
