defmodule Belial.Test.Web.Absinthe do
  def setup_one(schema) do
    factory = schema.__test_factory()
    user = factory.insert(:user)
    primary_key = Belial.Schema.get_primary_key(schema)
    resource = factory.insert(schema.__test_resource_atom())
    singular = Belial.Schema.get_singular(schema)

    query = """
      query QueryOne($#{primary_key}:ID!) {
        #{singular}(#{primary_key}:$#{primary_key}) {
          #{primary_key}
        }
      }
    """

    variables = %{"#{primary_key}" => Map.get(resource, primary_key)}

    {:ok, resource: resource, query: query, variables: variables, user: user}
  end

  defmacro query_singular_test(raw_schema) do
    schema = Macro.expand(raw_schema, __CALLER__)
    primary_key = Belial.Schema.get_primary_key(schema)
    singular = Belial.Schema.get_singular(schema)

    quote location: :keep do
      describe "query singular" do
        setup do
          unquote(__MODULE__).setup_one(unquote(schema))
        end

        test "query_#{unquote(singular)} fetches a #{unquote(singular)}", %{
          resource: resource,
          query: query,
          variables: variables,
          user: user
        } do
          expected = %{
            "#{unquote(singular)}" => %{
              "#{unquote(primary_key)}" => "#{Map.get(resource, unquote(primary_key))}"
            }
          }

          Belial.Test.Web.Absinthe.Helper.assert_query(user, query, variables, expected)
        end
      end
    end
  end

  def setup_many(schema) do
    factory = schema.__test_factory()
    user = factory.insert(:user)
    primary_key = Belial.Schema.get_primary_key(schema)
    resource = factory.insert(schema.__test_resource_atom())
    plural = Belial.Schema.get_plural(schema)

    query = """
      query QueryMany(
        $page: Int,
        $perPage: Int,
      ) {
        #{plural}(
          page: $page,
          perPage: $perPage,
        ) {
          entries {
            #{primary_key}
          }
          page_number
          page_size
          total_entries
          total_pages
        }
      }
    """

    variables = %{id: resource.id}

    {:ok, resource: resource, query: query, variables: variables, user: user}
  end

  defmacro query_paginated_test(raw_schema) do
    schema = Macro.expand(raw_schema, __CALLER__)
    primary_key = Belial.Schema.get_primary_key(schema)
    plural = Belial.Schema.get_plural(schema)

    quote location: :keep do
      describe "query paginated" do
        setup do
          unquote(__MODULE__).setup_many(unquote(schema))
        end

        test "query_#{unquote(plural)} fetches a paginated list of #{unquote(plural)}", %{
          resource: resource,
          query: query,
          variables: variables,
          user: user
        } do
          expected = %{
            "#{unquote(plural)}" => %{
              "entries" => [
                %{
                  "#{unquote(primary_key)}" => "#{Map.get(resource, unquote(primary_key))}"
                }
              ],
              "page_number" => 1,
              "page_size" => 10,
              "total_entries" => 1,
              "total_pages" => 1
            }
          }

          Belial.Test.Web.Absinthe.Helper.assert_query(user, query, variables, expected)
        end
      end
    end
  end

  def input_name_helper(input_name) do
    input_name
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join("")
  end

  def setup_create(schema) do
    factory = schema.__test_factory()
    user = factory.insert(:user)

    params =
      schema.__test_resource_atom()
      |> factory.params_with_assocs()
      |> Map.take(Belial.Web.Absinthe.Notation.input_fields(schema))

    singular = Belial.Schema.get_singular(schema)

    query = """
    mutation Create($#{singular}: #{
      Belial.Test.Web.Absinthe.input_name_helper("create_#{singular}_input")
    }!) {
      #{Absinthe.Adapter.LanguageConventions.to_external_name("create_#{singular}", "")}(#{
      singular
    }: $#{singular}) {
        #{params |> Map.keys() |> Enum.join("\n")}
      }
    }
    """

    variables = %{String.to_atom(singular) => params}

    {:ok, query: query, variables: variables, user: user}
  end

  defmacro mutation_create_test(raw_schema) do
    schema = Macro.expand(raw_schema, __CALLER__)
    singular = Belial.Schema.get_singular(schema)

    quote location: :keep do
      describe "create" do
        setup do
          unquote(__MODULE__).setup_create(unquote(schema))
        end

        test "mutation_create_#{unquote(singular)} fetches a #{unquote(singular)}", %{
          query: query,
          variables: variables,
          user: user
        } do
          expected = %{
            "#{
              Absinthe.Adapter.LanguageConventions.to_external_name(
                "create_#{unquote(singular)}",
                ""
              )
            }" => Map.get(variables, unquote(String.to_atom(singular)))
          }

          Belial.Test.Web.Absinthe.Helper.assert_query(user, query, variables, expected)
        end
      end
    end
  end

  def setup_update(schema) do
    factory = schema.__test_factory()
    user = factory.insert(:user)
    primary_key = Belial.Schema.get_primary_key(schema)

    resource = factory.insert(schema.__test_resource_atom())

    params =
      schema.__test_resource_atom()
      |> factory.params_with_assocs()
      |> Map.take(Belial.Web.Absinthe.Notation.input_fields(schema))

    singular = Belial.Schema.get_singular(schema)

    query = """
    mutation Update($#{singular}: #{
      Belial.Test.Web.Absinthe.input_name_helper("update_#{singular}_input")
    }!) {
      #{Absinthe.Adapter.LanguageConventions.to_external_name("update_#{singular}", "")}(#{
      singular
    }: $#{singular}) {
        #{params |> Map.keys() |> List.insert_at(-1, primary_key) |> Enum.join("\n")}
      }
    }
    """

    variables = %{
      String.to_atom(singular) =>
        Map.merge(%{primary_key => "#{Map.get(resource, primary_key)}"}, params)
    }

    {:ok, resource: resource, query: query, variables: variables, user: user}
  end

  defmacro mutation_update_test(raw_schema) do
    schema = Macro.expand(raw_schema, __CALLER__)
    singular = Belial.Schema.get_singular(schema)
    primary_key = Belial.Schema.get_primary_key(schema)

    quote location: :keep do
      describe "update" do
        setup do
          unquote(__MODULE__).setup_update(unquote(schema))
        end

        test "mutation_update_#{unquote(singular)} fetches a #{unquote(singular)}", %{
          resource: resource,
          query: query,
          variables: variables,
          user: user
        } do
          expected = %{
            "#{
              Absinthe.Adapter.LanguageConventions.to_external_name(
                "update_#{unquote(singular)}",
                ""
              )
            }" => Map.get(variables, unquote(String.to_atom(singular)))
          }

          %{unquote(primary_key) => "#{Map.get(resource, unquote(primary_key))}"}

          Belial.Test.Web.Absinthe.Helper.assert_query(user, query, variables, expected)
        end
      end
    end
  end

  def setup_delete(schema) do
    factory = schema.__test_factory()
    user = factory.insert(:user)
    resource = factory.insert(schema.__test_resource_atom())

    primary_key = Belial.Schema.get_primary_key(schema)
    singular = Belial.Schema.get_singular(schema)

    query = """
    mutation Update($#{singular}: #{
      Belial.Test.Web.Absinthe.input_name_helper("delete_#{singular}_input")
    }!) {
      #{Absinthe.Adapter.LanguageConventions.to_external_name("delete_#{singular}", "")}(#{
      singular
    }: $#{singular}) {
        #{primary_key}
      }
    }
    """

    variables = %{
      String.to_atom(singular) => %{primary_key => "#{Map.get(resource, primary_key)}"}
    }

    {:ok, resource: resource, query: query, variables: variables, user: user}
  end

  defmacro mutation_delete_test(raw_schema) do
    schema = Macro.expand(raw_schema, __CALLER__)
    singular = Belial.Schema.get_singular(schema)
    primary_key = Belial.Schema.get_primary_key(schema)

    quote location: :keep do
      describe "delete" do
        setup do
          unquote(__MODULE__).setup_delete(unquote(schema))
        end

        test "mutation_delete_#{unquote(singular)} fetches a #{unquote(singular)}", %{
          resource: resource,
          query: query,
          variables: variables,
          user: user
        } do
          expected = %{
            "#{
              Absinthe.Adapter.LanguageConventions.to_external_name(
                "delete_#{unquote(singular)}",
                ""
              )
            }" => Map.get(variables, unquote(String.to_atom(singular)))
          }

          %{unquote(primary_key) => "#{Map.get(resource, unquote(primary_key))}"}

          Belial.Test.Web.Absinthe.Helper.assert_query(user, query, variables, expected)
        end
      end
    end
  end
end
