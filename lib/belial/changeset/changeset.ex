defmodule Belial.Changeset do
  @moduledoc """
  Useful changesets that can be shared across data types
  """
  alias Belial.Changeset.{
    ExclusiveBelongsTo,
    RequiredInclusion,
    SingleRequiredField
  }

  alias Ecto.Changeset

  @doc """
  Validates exclusive_belongs_to fields are included and excluded properly
  """
  @spec validate_exclusive_belongs_to(Changeset.t(), [atom]) :: Changeset.t()
  defdelegate validate_exclusive_belongs_to(changeset, fields), to: ExclusiveBelongsTo

  @spec validate_exclusive_belongs_to(Changeset.t(), [atom], atom) :: Changeset.t()
  defdelegate validate_exclusive_belongs_to(changeset, fields, join_id), to: ExclusiveBelongsTo

  @doc """
  Validates at least one of the required fields is included
  """
  @spec validate_required_inclusion(Changeset.t(), [atom]) :: Changeset.t()
  defdelegate validate_required_inclusion(changeset, fields), to: RequiredInclusion

  @doc """
  Validates only one of the required fields is included
  """
  @spec validate_single_required_field(Changeset.t(), [atom]) :: Changeset.t()
  defdelegate validate_single_required_field(changeset, fields), to: SingleRequiredField

  @doc """
  Verifies a field not nil or empty string in a changeset
  """
  @spec field_present?(Changeset.t(), atom) :: boolean
  def field_present?(changeset, field) do
    value = Changeset.get_field(changeset, field)
    not is_nil(value) && value != ""
  end
end
