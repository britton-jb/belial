defmodule Belial.Web.Absinthe.Notation do
  @moduledoc """
  Generator for Absinthe types for a given ecto schema,
  as well as basic queries and mutations.
  """

  @spec input_fields(module) :: [atom]
  def input_fields(schema) do
    primary_key = Belial.Schema.get_primary_key(schema)
    fields = schema.__schema__(:fields)

    fields -- [primary_key, :inserted_at, :updated_at, :deleted_at]
  end

  defmacro fields_wrapper(schema) do
    fields = schema.__schema__(:fields)
    do_fields_wrapper(schema, fields)
  end

  defmacro fields_wrapper(schema, fields) do
    do_fields_wrapper(schema, fields)
  end

  defp do_fields_wrapper(schema, fields) do
    Enum.map(fields, fn field_atom ->
      converted_type =
        :type
        |> schema.__schema__(field_atom)
        |> Belial.Web.Absinthe.FieldTypeMapper.convert_type()

      quote do
        field(
          unquote(field_atom),
          unquote(converted_type)
        )
      end
    end)
  end

  def assoc_quote(
        context,
        schema,
        %Ecto.Association.HasThrough{cardinality: cardinality, through: through},
        assoc_atom
      ) do
    related = Belial.Web.Absinthe.Dataloader.chase_down_queryable(through, schema)
    assoc_quote(context, schema, %{cardinality: cardinality, related: related}, assoc_atom)
  end

  def assoc_quote(context, _schema, %{cardinality: :one, related: related}, assoc_atom) do
    quote do
      field(
        unquote(assoc_atom),
        unquote(String.to_atom(Belial.Schema.get_singular(related)))
      ) do
        resolve(Belial.Web.Absinthe.Dataloader.dataloader(unquote(context)))
      end
    end
  end

  def assoc_quote(context, _schema, %{cardinality: :many, related: related}, assoc_atom) do
    quote do
      field(
        unquote(assoc_atom),
        list_of(unquote(String.to_atom(Belial.Schema.get_singular(related))))
      ) do
        resolve(Belial.Web.Absinthe.Dataloader.dataloader(unquote(context)))
      end
    end
  end

  defmacro assocs_wrapper(context, schema) do
    associations = schema.__schema__(:associations)

    Enum.map(associations, fn assoc_atom ->
      assoc_meta = schema.__schema__(:association, assoc_atom)
      assoc_quote(context, schema, assoc_meta, assoc_atom)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defmacro __using__(opts) do
    context = Macro.expand(Keyword.fetch!(opts, :context), __CALLER__)
    schema = Macro.expand(Keyword.fetch!(opts, :schema), __CALLER__)
    policy = Macro.expand(Keyword.fetch!(opts, :policy), __CALLER__)

    singular = Belial.Schema.get_singular(schema)
    plural = Belial.Schema.get_plural(schema)
    primary_key = Belial.Schema.get_primary_key(schema)

    quote location: :keep do
      use Absinthe.Schema.Notation
      require unquote(__MODULE__)
      import Absinthe.Resolution.Helpers

      object unquote(String.to_atom(singular)) do
        unquote(__MODULE__).fields_wrapper(unquote(schema))
        unquote(__MODULE__).assocs_wrapper(unquote(context), unquote(schema))
      end

      @desc "Paginated list of #{unquote(plural)}"
      object unquote(String.to_atom("#{singular}_list")) do
        field(:entries, non_null(list_of(unquote(String.to_atom(singular)))))
        field(:page_number, non_null(:integer))
        field(:page_size, non_null(:integer))
        field(:total_entries, non_null(:integer))
        field(:total_pages, non_null(:integer))
      end

      input_object unquote(String.to_atom("create_#{singular}_input")) do
        unquote(__MODULE__).fields_wrapper(
          unquote(schema),
          unquote(__MODULE__.input_fields(schema))
        )
      end

      input_object unquote(String.to_atom("update_#{singular}_input")) do
        unquote(__MODULE__).fields_wrapper(
          unquote(schema),
          unquote([primary_key | __MODULE__.input_fields(schema)])
        )
      end

      input_object unquote(String.to_atom("delete_#{singular}_input")) do
        unquote(__MODULE__).fields_wrapper(
          unquote(schema),
          unquote([primary_key])
        )
      end

      object unquote(String.to_atom("#{singular}_mutations")) do
        field unquote(String.to_atom("create_#{singular}")), unquote(String.to_atom(singular)) do
          arg(
            unquote(String.to_atom(singular)),
            non_null(unquote(String.to_atom("create_#{singular}_input")))
          )

          middleware(Speakeasy.Authn)
          middleware(Speakeasy.Authz, {unquote(policy), :"create_#{unquote(singular)}"})

          resolve(fn %{unquote(String.to_atom(singular)) => args},
                     %{context: %{current_user: _user}} = _res ->
            # FIXME some kind of injection of the current user into the args?
            apply(unquote(context), :"create_#{unquote(singular)}", [args])
          end)
        end

        field unquote(String.to_atom("update_#{singular}")), unquote(String.to_atom(singular)) do
          arg(
            unquote(String.to_atom(singular)),
            non_null(unquote(String.to_atom("update_#{singular}_input")))
          )

          middleware(Speakeasy.Authn)

          middleware(Speakeasy.LoadResource, fn attrs ->
            primary_key_value =
              attrs
              |> Map.get(unquote(String.to_atom(singular)), %{})
              |> Map.get(unquote(primary_key))

            apply(unquote(context), :"get_#{unquote(singular)}", [primary_key_value])
          end)

          middleware(Speakeasy.Authz, {unquote(policy), :"update_#{unquote(singular)}"})

          resolve(fn %{unquote(String.to_atom(singular)) => args},
                     %{context: %{current_user: _user} = ctx} = _res ->
            # FIXME some kind of injection of the current user into the args?
            apply(unquote(context), :"update_#{unquote(singular)}", [ctx.speakeasy.resource, args])
          end)
        end

        field unquote(String.to_atom("delete_#{singular}")), unquote(String.to_atom(singular)) do
          arg(
            unquote(String.to_atom(singular)),
            unquote(String.to_atom("delete_#{singular}_input"))
          )

          arg(unquote(primary_key), :id)

          middleware(Speakeasy.Authn)

          middleware(Speakeasy.LoadResource, fn attrs ->
            primary_key_value =
              attrs
              |> Map.get(unquote(String.to_atom(singular)), %{})
              |> Map.get(unquote(primary_key)) ||
                Map.get(attrs, unquote(primary_key))

            apply(unquote(context), :"get_#{unquote(singular)}", [primary_key_value])
          end)

          middleware(Speakeasy.Authz, {unquote(policy), :"delete_#{unquote(singular)}"})

          resolve(fn _args, %{context: %{current_user: _user} = ctx} = _res ->
            apply(unquote(context), :"delete_#{unquote(singular)}", [ctx.speakeasy.resource])
          end)
        end
      end

      object unquote(String.to_atom("query_#{singular}")) do
        field unquote(String.to_atom(singular)), unquote(String.to_atom(singular)) do
          arg(unquote(primary_key), non_null(:id))

          middleware(Speakeasy.Authn)

          middleware(Speakeasy.LoadResourceByID, fn params ->
            apply(unquote(context), :"get_#{unquote(singular)}", [params])
          end)

          middleware(Speakeasy.Authz, {unquote(policy), :"query_#{unquote(singular)}"})
          middleware(Speakeasy.Resolve)
        end
      end

      object unquote(String.to_atom("query_#{plural}")) do
        field unquote(String.to_atom(plural)),
              non_null(unquote(String.to_atom("#{singular}_list"))) do
          arg(:page, :integer)
          arg(:per_page, :integer)

          middleware(Speakeasy.Authn)

          middleware(Speakeasy.LoadResource, fn params ->
            page = Map.get(params, "page") || Map.get(params, "page_number") || 1

            apply(unquote(context), :"paginated_list_#{unquote(plural)}", [params, page])
          end)

          middleware(Speakeasy.Authz, {unquote(policy), :"query_#{unquote(plural)}"})
          middleware(Speakeasy.Resolve)
        end
      end
    end
  end
end
