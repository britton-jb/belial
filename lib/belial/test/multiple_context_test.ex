defmodule Belial.Test.MultipleContext do
  @moduledoc """
  Test helper for all CRUD functions on MultipleContext
  """

  @type options :: [
          schema: module(),
          singularized: String.t(),
          pluralized: String.t()
        ]

  alias Belial.Test.{ContextFuntions, MultipleContext}

  @functions ContextFuntions.names()

  @spec test(module, options(), [ContextFuntions.t()]) :: Macro.t()
  def test(context, opts, functions \\ @functions) do
    schema = Keyword.get(opts, :schema)
    if is_nil(schema), do: raise("#{__MODULE__} requires a :schema option")
    singular = Belial.Schema.get_singular(schema)
    plural = Belial.Schema.get_plural(schema)

    if Enum.member?(functions, :list) do
      MultipleContext.List.test(context, schema, plural)
    end

    if Enum.member?(functions, :paginated_list) do
      MultipleContext.PaginatedList.test(context, schema, plural)
    end

    if Enum.member?(functions, :get!) do
      MultipleContext.GetBang.test(context, schema, singular)
    end

    if Enum.member?(functions, :get_by!) do
      MultipleContext.GetByBang.test(context, schema, singular)
    end

    if Enum.member?(functions, :get) do
      MultipleContext.Get.test(context, schema, singular)
    end

    if Enum.member?(functions, :get) do
      MultipleContext.GetBy.test(context, schema, singular)
    end

    if Enum.member?(functions, :change) do
      MultipleContext.Change.test(context, schema, singular)
    end

    if Enum.member?(functions, :create) do
      MultipleContext.Create.test(context, schema, singular)
    end

    if Enum.member?(functions, :update) do
      MultipleContext.Update.test(context, schema, singular)
    end

    if Enum.member?(functions, :delete) do
      MultipleContext.Delete.test(context, schema, singular)
    end
  end
end
