defmodule Belial.Web.Controllers.Api do
  @moduledoc """
  Sets up overridable default CRUD actions for a controller.

  Requires passing in Keyword pairs for :context, :schema,

  Optionally can pass in a :view, :policy, :fallback_controller, and :white_list.
  It's recommended that you pass in

  Defines the following functions with the ability to override them
  for each controller:

  index/2
  show/2
  create/2
  update/2
  delete/2
  """

  require Logger

  defp white_list_warning(caller, opts, white_list) do
    if is_nil(white_list) && Keyword.get(opts, :warn, true) do
      Logger.warn("""
      #{caller} is using #{__MODULE__} and has not defined a :white_list.
      This represents a potential security risk. This warning can be silenced by passing
      in a white list, or `warn: false`
      """)
    end
  end

  defmacro __using__(opts) do
    context = Macro.expand(Keyword.fetch!(opts, :context), __CALLER__)
    schema = Macro.expand(Keyword.fetch!(opts, :schema), __CALLER__)
    routes_tuple = Enum.find(__CALLER__.aliases, fn alyas -> {Routes, _} = alyas end)
    {_, routes} = routes_tuple
    policy = Macro.expand(Keyword.get(opts, :policy), __CALLER__)
    view = Macro.expand(Keyword.get(opts, :view), __CALLER__) || Belial.Web.Views.ApiView
    white_list = Keyword.get(opts, :white_list)
    white_list_warning(__CALLER__.module, opts, white_list)

    fallback_controller =
      Macro.expand(Keyword.get(opts, :fallback_controller), __CALLER__) ||
        Belial.Web.FallbackController

    singular = Belial.Schema.get_singular(schema)
    plural = Belial.Schema.get_plural(schema)

    quote location: :keep do
      action_fallback unquote(fallback_controller)

      plug :put_view, unquote(view)

      plug Belial.Web.Plugs.LoadResource,
        context: unquote(context),
        schema: unquote(schema),
        actions: [:show, :update, :delete]

      unless is_nil(unquote(policy)) do
        plug Belial.Web.Plugs.AuthorizeResource, policy: unquote(policy)
      end

      @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def index(conn, params) do
        page = Map.get(params, "page") || Map.get(params, "page_number") || 1

        white_listed_params =
          if is_nil(unquote(white_list)) do
            Belial.Web.Controllers.keys_to_atoms(params)
          else
            params
            |> Belial.Web.Controllers.keys_to_atoms()
            |> Enum.filter(&Enum.member?(unquote(white_list), &1))
          end

        page =
          apply(unquote(context), :"paginated_list_#{unquote(plural)}", [
            white_listed_params,
            page
          ])

        render(conn, :index, page: page)
      end

      defoverridable index: 2

      @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def show(conn, _params) do
        case resource = conn.assigns.resource do
          nil ->
            {:error, :not_found}

          _ ->
            render(conn, :show, resource: resource)
        end
      end

      defoverridable show: 2

      @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def create(conn, params) do
        resource_create_tuple = apply(unquote(context), :"create_#{unquote(singular)}", [params])

        case resource_create_tuple do
          {:error, changeset} ->
            {:error, changeset}

          {:ok, resource} ->
            conn
            |> put_status(:created)
            |> put_resp_header(
              "location",
              apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :show, resource])
            )
            |> render(:show, resource: resource)
        end
      end

      defoverridable create: 2

      @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def update(conn, params) do
        with resource when not is_nil(resource) <- resource = conn.assigns.resource,
             {:ok, resource} <-
               apply(unquote(context), :"update_#{unquote(singular)}", [resource, params]) do
          render(conn, :show, resource: resource)
        else
          nil -> {:error, :not_found}
          {:error, changeset} -> {:error, changeset}
        end
      end

      defoverridable update: 2

      @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def delete(conn, _params) do
        with resource when not is_nil(resource) <- resource = conn.assigns.resource,
             {:ok, resource} <-
               apply(unquote(context), :"delete_#{unquote(singular)}", [resource]) do
          render(conn, :show, resource: %{})
        else
          nil -> {:error, :not_found}
          {:error, changeset} -> {:error, changeset}
        end
      end

      defoverridable delete: 2
    end
  end
end
