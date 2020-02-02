defmodule Belial.Test.Web.AdminController do
  @actions [:index, :new, :create, :show, :edit, :update, :delete]

  defmacro test(schema, actions \\ @actions) do
    schema = Macro.expand(schema, __CALLER__)
    routes_tuple = Enum.find(__CALLER__.aliases, fn alyas -> {Routes, _} = alyas end)

    if is_nil(routes_tuple) do
      raise(
        Belial.CompileTimeError,
        "#{__MODULE__} requires the caller alias a Routes helper as `Routes`"
      )
    end

    schema = Macro.expand(schema, __CALLER__)
    singular = Belial.Schema.get_singular(schema)
    {_, routes} = routes_tuple

    quote location: :keep do
      if Enum.member?(unquote(actions), :index) do
        test "#index/2 lists all #{unquote(singular)}", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = get(conn, apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :index]))
          assert response = html_response(conn, 200)
          assert response =~ "#{unquote(schema)}"
        end
      end

      if Enum.member?(unquote(actions), :show) do
        test "#show/2 renders when the #{unquote(singular)} exists", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))

          conn =
            get(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :show,
                resource
              ])
            )

          assert body = response(conn, 200)
        end

        test "#show/2 renders 404 when the #{unquote(singular)} doesn't exist", %{conn: conn} do
          conn =
            get(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :show,
                999_999
              ])
            )

          assert body = response(conn, 404)
        end
      end

      if Enum.member?(unquote(actions), :new) do
        test "#new/2 renders the new #{unquote(singular)} form", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = get(conn, apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :new]))
          assert response = html_response(conn, 200)
          assert response =~ "New"
        end
      end

      if Enum.member?(unquote(actions), :create) do
        test "#create/2 creates when data is valid", %{conn: conn} do
          conn =
            post(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :create]),
              @create_attrs
            )

          body = response(conn, 302)
          assert get_flash(conn, :info) =~ "created successfully"

          assert redirected_to(conn) =~
                   apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :index])
        end

        test "#create/2 renders errors when data is invalid", %{conn: conn} do
          conn =
            post(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :create]),
              @invalid_attrs
            )

          body = response(conn, 422)
          assert get_flash(conn, :error) =~ "Failed to create"
        end
      end

      if Enum.member?(unquote(actions), :edit) do
        test "#edit/2 renders the edit #{unquote(singular)} form", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))

          conn =
            get(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :edit,
                resource
              ])
            )

          assert response = response(conn, 200)
          assert response =~ "Edit"
        end
      end

      if Enum.member?(unquote(actions), :update) do
        test "#update/2 redirects when data is valid", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))

          conn =
            put(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :update,
                resource
              ]),
              @update_attrs
            )

          body = response(conn, 302)
          assert get_flash(conn, :info) =~ "updated successfully"

          assert redirected_to(conn) ==
                   apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :show, resource])
        end

        test "#update/2 renders errors when data is invalid", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))

          conn =
            put(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :update,
                resource
              ]),
              @invalid_attrs
            )

          body = response(conn, 422)
          assert get_flash(conn, :error) =~ "Failed to update"
        end

        test "#update/2 renders 404 when the resource doesn't exist", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))

          conn =
            put(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :update,
                999_999
              ]),
              @invalid_attrs
            )

          body = response(conn, 404)
        end
      end

      if Enum.member?(unquote(actions), :delete) do
        test "deletes chosen #{unquote(singular)}", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))

          conn =
            delete(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :delete,
                resource
              ])
            )

          body = response(conn, 302)
          assert get_flash(conn, :info) =~ "deleted successfully"

          assert redirected_to(conn) ==
                   apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :index])
        end

        test "renders 404 when the resource doesn't exist", %{conn: conn} do
          conn =
            delete(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :delete,
                999_999
              ])
            )

          body = response(conn, 404)
        end
      end
    end
  end

  def create_resource(schema) do
    schema.__test_factory.insert(schema.__test_resource_atom)
  end
end
