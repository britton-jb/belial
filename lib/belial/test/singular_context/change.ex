defmodule Belial.Test.SingularContext.Change do
  @moduledoc """
  Adds a test helper for change functions defined by the SingularContext
  """
  require ExUnit.Assertions

  defp fn_desc(context) do
    "FUNCTION: #{context}.change/1"
  end

  def test(context, schema) do
    ExUnit.Assertions.assert(
      %Ecto.Changeset{} = context.change(struct!(schema)),
      "#{fn_desc(context)} failed to create an ecto changeset"
    )
  end
end
