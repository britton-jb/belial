defmodule Belial.Test.ExclusiveBelongsTo do
  @moduledoc """
  Adds a test helper for exclusive belongs_to associations that I've setup
  """
  # credo:disable-for-this-file Credo.Check.Readability.Specs
  require ExUnit.Assertions

  def test(module, list_of_potential_assocs, changeset_fn \\ :changeset) do
    assert_invalid_when_all_assocs_nil(module, list_of_potential_assocs, changeset_fn)
    assert_invalid_when_all_assocs_set(module, list_of_potential_assocs, changeset_fn)
    assert_valid_when_all_assocs_set(module, list_of_potential_assocs, changeset_fn)
  end

  defp assert_invalid_when_all_assocs_nil(module, list_of_potential_assocs, changeset_fn) do
    schema_struct = struct!(module)

    all_assocs_nil =
      Enum.reduce(list_of_potential_assocs, %{}, fn assoc, acc ->
        Map.put(acc, elem(assoc, 1), nil)
      end)

    all_assocs_nil_changeset = apply(module, changeset_fn, [schema_struct, all_assocs_nil])

    ExUnit.Assertions.refute(
      all_assocs_nil_changeset.valid?,
      "changeset valid, though all assocs are nil"
    )

    proper_error? =
      Enum.any?(all_assocs_nil_changeset.errors, fn {_key, tuple} ->
        elem(tuple, 1) == [validation: :required_inclusion]
      end)

    ExUnit.Assertions.assert(proper_error?, "all assocs are nil, but no expected error present")
  end

  defp assert_invalid_when_all_assocs_set(module, list_of_potential_assocs, changeset_fn) do
    schema_struct = struct!(module)

    all_assocs_set =
      Enum.reduce(list_of_potential_assocs, %{}, fn assoc, acc ->
        inserted_assoc = module.__test_factory().insert(elem(assoc, 0))
        inserted_assoc_primary_key = Belial.Schema.get_primary_key(inserted_assoc.__struct__)
        Map.put(acc, elem(assoc, 1), Map.get(inserted_assoc, inserted_assoc_primary_key))
      end)

    all_assocs_set_changeset = apply(module, changeset_fn, [schema_struct, all_assocs_set])

    ExUnit.Assertions.refute(
      all_assocs_set_changeset.valid?,
      "changeset valid, though all assocs are set"
    )

    proper_error? =
      Enum.any?(all_assocs_set_changeset.errors, fn {_key, tuple} ->
        elem(tuple, 1) == [validation: :single_required_field]
      end)

    ExUnit.Assertions.assert(proper_error?, "all assocs are set, but no expected error present")
  end

  defp assert_valid_when_all_assocs_set(module, list_of_potential_assocs, changeset_fn) do
    schema_struct = struct!(module)

    single_assoc =
      list_of_potential_assocs
      |> List.first()
      |> elem(0)
      |> module.__test_factory().insert()

    single_assoc_primary_key = Belial.Schema.get_primary_key(single_assoc.__struct__)

    single_assoc_fk =
      list_of_potential_assocs
      |> List.first()
      |> elem(1)

    params =
      module.__test_resource_atom()
      |> module.__test_factory().params_with_assocs()
      |> Map.merge(%{single_assoc_fk => Map.get(single_assoc, single_assoc_primary_key)})

    single_assoc_changeset = apply(module, changeset_fn, [schema_struct, params])

    ExUnit.Assertions.assert(
      single_assoc_changeset.valid?,
      "changeset invalid, though it should be valid"
    )
  end
end
