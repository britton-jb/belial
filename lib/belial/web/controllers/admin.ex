defmodule Belial.Web.Controllers.Admin do
  @moduledoc """
  Sets up overridable default admin app controller.

  Requires passing in Keyword pairs for :context, :schema, :layout.
  Requires that the controller also implementsa router helper aliased
  as `Routes`

  Optionally can pass in :search, :view, :fallback_controller, and a :policy.

  :view is expected as a tuple, the way `put_layout` expects it.

  :search determines if a LiveView search is rendered on the index.

  It expects a field atom, or a list of atoms, to search by using OR,
  or the schema to define `__search_field/0`.

  Defines the following functions with the ability to override them
  for each controller:

  index/2
  show/2
  new/2
  create/2
  edit/2
  update/2
  delete/2
  """

  defp search_opts(schema, opts) do
    case {function_exported?(schema, :__search_field, 0), search_opt = Keyword.get(opts, :search)} do
      {false, nil} -> nil
      {true, _} -> schema.__search_field()
      {false, _} -> search_opt
    end
  end

  def pagination_params(schema, params) do
    atomized_original_params = Belial.Web.Controllers.keys_to_atoms(params)
    original_keys_map_set = atomized_original_params |> Map.keys() |> MapSet.new()
    schema_keys_map_set = MapSet.new(schema.__schema__(:fields))
    intersection = MapSet.intersection(schema_keys_map_set, original_keys_map_set)
    Map.take(atomized_original_params, MapSet.to_list(intersection))
  end

  defmacro __using__(opts) do
    context = Macro.expand(Keyword.fetch!(opts, :context), __CALLER__)
    schema = Macro.expand(Keyword.fetch!(opts, :schema), __CALLER__)
    layout = Macro.expand(Keyword.fetch!(opts, :layout), __CALLER__)
    routes_tuple = Enum.find(__CALLER__.aliases, fn alyas -> {Routes, _} = alyas end)
    {_, routes} = routes_tuple
    policy = Macro.expand(Keyword.get(opts, :policy), __CALLER__)
    view = Macro.expand(Keyword.get(opts, :view), __CALLER__) || Belial.Web.Views.AdminView
    render_search = search_opts(schema, opts)

    fallback_controller =
      Macro.expand(Keyword.get(opts, :fallback_controller), __CALLER__) ||
        Belial.Web.FallbackController

    singular = Belial.Schema.get_singular(schema)
    plural = Belial.Schema.get_plural(schema)

    quote do
      import Phoenix.LiveView.Controller
      action_fallback unquote(fallback_controller)

      plug :put_layout, unquote(layout)
      plug :put_view, unquote(view)

      plug Belial.Web.Plugs.LoadResource,
        context: unquote(context),
        schema: unquote(schema),
        actions: [:show, :edit, :update, :delete]

      unless is_nil(unquote(policy)) do
        plug Belial.Web.Plugs.AuthorizeResource, policy: unquote(policy)
      end

      @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def index(conn, params) do
        page = Map.get(params, "page") || Map.get(params, "page_number") || 1

        page =
          apply(unquote(context), :"paginated_list_#{unquote(plural)}", [
            unquote(__MODULE__).pagination_params(unquote(schema), params),
            page
          ])

        render(conn, :index,
          page: page,
          context: unquote(context),
          schema: unquote(schema),
          render_search: unquote(render_search)
        )
      end

      defoverridable index: 2

      @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def new(conn, _params) do
        changeset = apply(unquote(context), :"change_#{unquote(singular)}", [])
        render(conn, :new, changeset: changeset, schema: unquote(schema))
      end

      defoverridable new: 2

      @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def create(conn, params) do
        create_return = apply(unquote(context), :"create_#{unquote(singular)}", [params])

        case create_return do
          {:ok, resource} ->
            conn
            |> put_flash(:info, "#{String.capitalize(unquote(singular))} created successfully.")
            |> redirect(
              to: apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :show, resource])
            )

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_flash(:error, "Failed to create #{unquote(singular)}")
            |> put_status(:unprocessable_entity)
            |> render("new.html", changeset: changeset, schema: unquote(schema))

          tuple ->
            changeset = apply(unquote(context), :"change_#{unquote(singular)}", [params])

            conn
            |> put_flash(:error, "Failed to create #{unquote(singular)}: #{inspect(tuple)}")
            |> put_status(:unprocessable_entity)
            |> render("new.html", changeset: changeset, schema: unquote(schema))
        end
      end

      defoverridable create: 2

      @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def show(conn, _params) do
        case resource = conn.assigns.resource do
          nil ->
            {:error, :not_found}

          _ ->
            render(conn, :show, resource: resource, schema: unquote(schema))
        end
      end

      defoverridable show: 2

      @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def edit(conn, _params) do
        case resource = conn.assigns.resource do
          nil ->
            {:error, :not_found}

          _ ->
            changeset = apply(unquote(context), :"change_#{unquote(singular)}", [resource])

            render(conn, :edit, resource: resource, schema: unquote(schema), changeset: changeset)
        end
      end

      defoverridable edit: 2

      @spec update(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def update(conn, params) do
        with resource when not is_nil(resource) <- resource = conn.assigns.resource,
             {:ok, resource} <-
               apply(unquote(context), :"update_#{unquote(singular)}", [resource, params]) do
          conn
          |> put_flash(:info, "#{String.capitalize(unquote(singular))} updated successfully.")
          |> redirect(
            to: apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :show, resource])
          )
        else
          nil ->
            {:error, :not_found}

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Failed to update #{unquote(singular)}")
            |> put_status(:unprocessable_entity)
            |> render("edit.html",
              resource: conn.assigns.resource,
              changeset: changeset,
              schema: unquote(schema)
            )

          tuple ->
            changeset = apply(unquote(context), :"change_#{unquote(singular)}", [params])

            conn
            |> put_flash(:error, "Failed to update #{unquote(singular)}: #{inspect(tuple)}")
            |> put_status(:unprocessable_entity)
            |> render("edit.html",
              resource: conn.assigns.resource,
              changeset: changeset,
              schema: unquote(schema)
            )
        end
      end

      defoverridable update: 2

      @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
      def delete(conn, _params) do
        with resource when not is_nil(resource) <- resource = conn.assigns.resource,
             {:ok, resource} <-
               apply(unquote(context), :"delete_#{unquote(singular)}", [resource]) do
          conn
          |> put_flash(:info, "#{String.capitalize(unquote(singular))} deleted successfully.")
          |> redirect(to: apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :index]))
        else
          nil ->
            {:error, :not_found}

          {:error, changeset} ->
            conn
            |> put_flash(
              :error,
              "Failed to delete #{String.capitalize(unquote(singular))}, #{
                inspect(changeset.errors)
              }."
            )
            |> redirect(
              to:
                apply(unquote(routes), :"#{unquote(singular)}_path", [
                  conn,
                  :show,
                  conn.assigns.resource
                ])
            )

          tuple ->
            conn
            |> put_flash(
              :error,
              "Failed to delete #{String.capitalize(unquote(singular))}, #{inspect(tuple)}."
            )
            |> redirect(
              to:
                apply(unquote(routes), :"#{unquote(singular)}_path", [
                  conn,
                  :show,
                  conn.assigns.resource
                ])
            )
        end
      end

      defoverridable delete: 2
    end
  end
end
