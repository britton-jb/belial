defmodule Belial.Web.Absinthe.Dataloader do
  @moduledoc """
  Module replacing the Absinthe default dataloader helper because it runs
  into an issue for me. Should submit an issue to see if it's just me?
  """
  def chase_down_queryable([field], schema) do
    case schema.__schema__(:association, field) do
      %{queryable: queryable} ->
        queryable

      %Ecto.Association.HasThrough{through: through} ->
        chase_down_queryable(through, schema)

      val ->
        raise """
        Valid association #{field} not found on schema #{inspect(schema)}
        Got: #{inspect(val)}
        """
    end
  end

  def chase_down_queryable([field | fields], schema) do
    case schema.__schema__(:association, field) do
      %{queryable: queryable} ->
        chase_down_queryable(fields, queryable)

      %Ecto.Association.HasThrough{through: [through_field | through_fields]} ->
        [through_field | through_fields ++ fields]
        |> chase_down_queryable(schema)
    end
  end

  def on_load(loader, fun) do
    {:middleware, Absinthe.Middleware.Dataloader, {loader, fun}}
  end

  def dataloader(source) do
    fn parent, args, %{context: %{loader: loader}} = res ->
      resource = res.definition.schema_node.identifier
      do_dataloader(loader, source, resource, args, parent, [])
    end
  end

  def dataloader(source, fun, opts \\ [])

  def dataloader(source, fun, opts) when is_function(fun, 3) do
    fn parent, args, %{context: %{loader: loader}} = res ->
      {resource, args} = fun.(parent, args, res)
      do_dataloader(loader, source, resource, args, parent, opts)
    end
  end

  def dataloader(source, resource, opts) do
    fn parent, args, %{context: %{loader: loader}} ->
      do_dataloader(loader, source, resource, args, parent, opts)
    end
  end

  defp use_parent(loader, source, resource, parent, args, opts) do
    with true <- Keyword.get(opts, :use_parent, false),
         {:ok, val} <- is_map(parent) && Map.fetch(parent, resource) do
      Dataloader.put(loader, source, {resource, args}, parent, val)
    else
      _ -> loader
    end
  end

  defp do_dataloader(loader, source, resource, args, parent, opts) do
    args =
      opts
      |> Keyword.get(:args, %{})
      |> Map.merge(args)

    loader
    |> use_parent(source, resource, parent, args, opts)
    |> Dataloader.load(source, {resource, args}, parent)
    |> on_load(fn loader ->
      # FIXME this is the bit I patched, removing the ok tuple
      Dataloader.get(loader, source, {resource, args}, parent)
    end)
  end
end
