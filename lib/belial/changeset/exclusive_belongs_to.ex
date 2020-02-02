defmodule Belial.Changeset.ExclusiveBelongsTo do
  @moduledoc """
  Exclusive belongs to changeset validation
  """
  import Ecto.Changeset

  @spec validate_exclusive_belongs_to(Ecto.Changeset.t(), [atom]) :: Ecto.Changeset.t()
  def validate_exclusive_belongs_to(%Ecto.Changeset{} = changeset, fields) do
    assoc_fields = Enum.map(fields, &elem(&1, 0))

    check_constraint_name =
      "#{changeset.data.__meta__.source}_exclusive_belongs_to_#{Enum.join(assoc_fields, "_")}"

    fields
    |> Enum.reduce(changeset, fn {assoc, _assoc_key}, acc_changeset ->
      acc_changeset
      |> assoc_constraint(assoc)
    end)
    |> check_constraint(hd(assoc_fields), name: check_constraint_name)
    |> Belial.Changeset.validate_required_inclusion(fields)
    |> Belial.Changeset.validate_single_required_field(fields)
  end

  @spec validate_exclusive_belongs_to(Ecto.Changeset.t(), [atom], atom) :: Ecto.Changeset.t()
  def validate_exclusive_belongs_to(%Ecto.Changeset{} = changeset, fields, join_id) do
    assoc_fields = Enum.map(fields, &elem(&1, 0))

    check_constraint_name =
      "#{changeset.data.__meta__.source}_exclusive_belongs_to_#{Enum.join(assoc_fields, "_")}"

    fields
    |> Enum.reduce(changeset, fn {assoc, assoc_key}, acc_changeset ->
      unique_constraint_name = "#{changeset.data.__meta__.source}_#{join_id}_#{assoc_key}_index"

      acc_changeset
      |> assoc_constraint(assoc)
      |> unique_constraint(assoc, name: unique_constraint_name)
    end)
    |> check_constraint(hd(assoc_fields), name: check_constraint_name)
    |> Belial.Changeset.validate_required_inclusion(fields)
    |> Belial.Changeset.validate_single_required_field(fields)
  end
end
