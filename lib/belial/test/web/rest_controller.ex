defmodule Belial.Test.Web.RestController do
  @actions [:index, :create, :show, :update, :delete]

  defmacro test(schema, fields_to_compare, actions \\ @actions) do
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

    quote do
      if Enum.member?(unquote(actions), :index) do
        test "#index/2 lists all #{unquote(singular)}", %{conn: conn} do
          primary_key = Belial.Schema.get_primary_key(unquote(schema))
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)
          conn = get(conn, apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :index]))
          body = json_response(conn, 200)

          assert %{
                   "entries" => entries,
                   "page_number" => 1,
                   "page_size" => 10,
                   "total_entries" => 1,
                   "total_pages" => 1
                 } = body["data"]

          assert entries |> List.first() |> Map.get(Atom.to_string(primary_key)) ==
                   Map.get(resource, primary_key)
        end
      end

      if Enum.member?(unquote(actions), :show) do
        test "#show/2 renders when the #{unquote(singular)} exists", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)
          primary_key = Belial.Schema.get_primary_key(unquote(schema))

          conn =
            get(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :show,
                resource
              ])
            )

          body = json_response(conn, 200)
          data = Belial.Web.Controllers.keys_to_atoms(body["data"])

          resource_taked = Map.take(Map.from_struct(resource), unquote(fields_to_compare))
          json_taked = Map.take(data, unquote(fields_to_compare))

          assert json_taked == resource_taked
        end

        test "#show/2 renders 404 when the #{unquote(singular)} doesn't exist", %{conn: conn} do
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

          conn =
            get(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :show,
                999_999
              ])
            )

          body = json_response(conn, 404)
          assert body["data"] == %{}
          assert body["errors"] == %{"message" => "not found"}
        end
      end

      if Enum.member?(unquote(actions), :create) do
        test "#create/2 creates when data is valid", %{conn: conn} do
          primary_key = Belial.Schema.get_primary_key(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

          conn =
            post(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :create]),
              @create_attrs
            )

          body = json_response(conn, 201)
          data = Belial.Web.Controllers.keys_to_atoms(body["data"])

          resource_taked = Map.take(@create_attrs, unquote(fields_to_compare))
          json_taked = Map.take(data, unquote(fields_to_compare) |> List.delete(primary_key))

          assert json_taked == resource_taked
        end

        test "#create/2 renders errors when data is invalid", %{conn: conn} do
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

          conn =
            post(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [conn, :create]),
              @invalid_attrs
            )

          body = json_response(conn, 422)
          assert body["data"] == %{}
          assert body["errors"] != %{}
        end
      end

      if Enum.member?(unquote(actions), :update) do
        test "#update/2 redirects when data is valid", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

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

          body = json_response(conn, 200)
          data = body["data"]

          data = Belial.Web.Controllers.keys_to_atoms(body["data"])

          resource_taked =
            Map.take(
              resource |> Map.from_struct() |> Map.merge(@update_attrs),
              unquote(fields_to_compare)
            )

          json_taked = Map.take(data, unquote(fields_to_compare))

          assert json_taked == resource_taked
        end

        test "#update/2 renders errors when data is invalid", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

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

          body = json_response(conn, 422)
          assert body["data"] == %{}
          assert body["errors"] != %{}
        end

        test "#update/2 renders 404 when the resource doesn't exist", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

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

          body = json_response(conn, 404)
          assert body["data"] == %{}
          assert body["errors"] == %{"message" => "not found"}
        end
      end

      if Enum.member?(unquote(actions), :delete) do
        test "deletes chosen #{unquote(singular)}", %{conn: conn} do
          resource = Belial.Test.Web.RestController.create_resource(unquote(schema))
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

          conn =
            delete(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :delete,
                resource
              ])
            )

          body = json_response(conn, 200)
          assert body["data"] == %{}
          assert body["errors"] == %{}
        end

        test "renders 404 when the resource doesn't exist", %{conn: conn} do
          conn = Belial.Test.Web.RestController.add_json_req_headers(conn)

          conn =
            delete(
              conn,
              apply(unquote(routes), :"#{unquote(singular)}_path", [
                conn,
                :delete,
                999_999
              ])
            )

          body = json_response(conn, 404)
          assert body["data"] == %{}
          assert body["errors"] == %{"message" => "not found"}
        end
      end
    end
  end

  def add_json_req_headers(conn) do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("accept", "application/json")
  end

  def create_resource(schema) do
    schema.__test_factory.insert(schema.__test_resource_atom)
  end
end
