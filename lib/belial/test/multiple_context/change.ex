defmodule Belial.Test.MultipleContext.Change do
  @moduledoc """
  Adds a test helper for change functions defined by the MultipleContext
  """
  require ExUnit.Assertions

  defp fn_desc(context, singular) do
    "FUNCTION: #{context}.change_#{singular}/1"
  end

  def test(context, schema, singular) do
    ExUnit.Assertions.assert(
      %Ecto.Changeset{} = apply(context, :"change_#{singular}", [struct!(schema)]),
      "#{fn_desc(context, singular)} failed to create an ecto changeset"
    )
  end
end
