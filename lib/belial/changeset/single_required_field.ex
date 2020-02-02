defmodule Belial.Changeset.SingleRequiredField do
  @moduledoc """
  Single Required Field changeset
  """

  @spec validate_single_required_field(Ecto.Changeset.t(), [atom]) :: Ecto.Changeset.t()
  def validate_single_required_field(%Ecto.Changeset{} = changeset, fields) do
    assoc_id_fields = Enum.map(fields, &elem(&1, 1))
    field_count = Enum.count(assoc_id_fields, &Belial.Changeset.field_present?(changeset, &1))

    if field_count == 1 || field_count == 0 do
      changeset
    else
      Ecto.Changeset.add_error(
        changeset,
        hd(assoc_id_fields),
        "Only one of these fields can be present: #{Enum.join(assoc_id_fields, ", ")}",
        validation: :single_required_field
      )
    end
  end
end
