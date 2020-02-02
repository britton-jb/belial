defmodule Belial.Test.ContextFuntions do
  @type t ::
          :data
          | :query
          | :list
          | :paginated_list
          | :get!
          | :get_by!
          | :get
          | :get_by
          | :change
          | :create
          | :update
          | :delete

  def names() do
    [
      :data,
      :query,
      :list,
      :paginated_list,
      :get!,
      :get_by!,
      :get,
      :get_by,
      :change,
      :create,
      :update,
      :delete
    ]
  end
end
