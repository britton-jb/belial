defmodule Belial.Test.Web.Absinthe.Helper do
  import ExUnit.Assertions
  @endpoint Application.get_env(:belial, :absinthe_endpoint)

  use Phoenix.ConnTest

  def assert_query(query, variables, expected) do
    response =
      Phoenix.ConnTest.build_conn()
      |> graphql_query(query: query, variables: variables)
      |> log_errors()
      |> Map.fetch!("data")

    assert response == Belial.Web.Controllers.keys_to_strings(expected)
  end

  def assert_query(user, query, variables, expected) do
    response =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.assign(:current_user, user)
      |> graphql_query(query: query, variables: variables)
      |> log_errors()
      |> Map.fetch!("data")

    assert response == Belial.Web.Controllers.keys_to_strings(expected)
  end

  defp graphql_query(conn, options) do
    conn
    |> Phoenix.ConnTest.post("/graphql", build_query(options[:query], options[:variables]))
    |> Phoenix.ConnTest.json_response(200)
  end

  defp build_query(query, variables) do
    %{
      "query" => query,
      "variables" => variables
    }
  end

  defp log_errors(%{"errors" => errors} = conn) when length(errors) > 0 do
    IO.inspect(errors)
    conn
  end

  defp log_errors(conn), do: conn
end
