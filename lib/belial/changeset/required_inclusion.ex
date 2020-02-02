defmodule Belial.Changeset.RequiredInclusion do
  @moduledoc """
  Required Inclusion changeset
  """

  @spec validate_required_inclusion(Ecto.Changeset.t(), [atom]) :: Ecto.Changeset.t()
  def validate_required_inclusion(%Ecto.Changeset{} = changeset, fields) do
    assoc_id_fields = Enum.map(fields, &elem(&1, 1))

    if Enum.any?(assoc_id_fields, &Belial.Changeset.field_present?(changeset, &1)) do
      changeset
    else
      Ecto.Changeset.add_error(
        changeset,
        hd(assoc_id_fields),
        "One of these fields must be present: #{Enum.join(assoc_id_fields, ", ")}",
        validation: :required_inclusion
      )
    end
  end
end
