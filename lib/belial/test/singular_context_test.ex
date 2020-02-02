defmodule Belial.Test.SingularContext do
  @moduledoc """
  Test helper for all CRUD functions on SingularContext
  """

  alias Belial.Test.{ContextFuntions, SingularContext}

  @functions ContextFuntions.names()

  @spec test(module, module, [ContextFuntions.t()]) :: Macro.t()
  def test(context, schema, functions \\ @functions) do
    if Enum.member?(functions, :list) do
      SingularContext.List.test(context, schema)
    end

    if Enum.member?(functions, :paginated_list) do
      SingularContext.PaginatedList.test(context, schema)
    end

    if Enum.member?(functions, :get!) do
      SingularContext.GetBang.test(context, schema)
    end

    if Enum.member?(functions, :get_by!) do
      SingularContext.GetByBang.test(context, schema)
    end

    if Enum.member?(functions, :get) do
      SingularContext.Get.test(context, schema)
    end

    if Enum.member?(functions, :get_by) do
      SingularContext.GetBy.test(context, schema)
    end

    if Enum.member?(functions, :change) do
      SingularContext.Change.test(context, schema)
    end

    if Enum.member?(functions, :create) do
      SingularContext.Create.test(context, schema)
    end

    if Enum.member?(functions, :update) do
      SingularContext.Update.test(context, schema)
    end

    if Enum.member?(functions, :delete) do
      SingularContext.Delete.test(context, schema)
    end
  end
end
