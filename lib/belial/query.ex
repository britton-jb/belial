defmodule Belial.Query do
  import Ecto.Query, warn: false

  defmacro __using__(opts) do
    schema = Macro.expand(Keyword.get(opts, :schema), __CALLER__)

    if is_nil(schema) do
      raise(Belial.CompileTimeError, "#{__MODULE__} __using__ requires a :schema")
    end

    assoc_list =
      Enum.map(schema.__schema__(:associations), fn association_atom ->
        quote location: :keep do
          import Ecto.Query

          @spec unquote(:"with_#{association_atom}")(Ecto.Queryable.t()) :: Ecto.Queryable.t()
          def unquote(:"with_#{association_atom}")(query) do
            from(
              record in query,
              left_join: association in assoc(record, unquote(association_atom)),
              preload: unquote(association_atom)
            )
          end

          defoverridable "with_#{unquote(association_atom)}": 1

          @spec unquote(:"by_#{association_atom}")(Ecto.Queryable.t(), any) :: Ecto.Queryable.t()
          def unquote(:"by_#{association_atom}")(query, query_by) when is_list(query_by) do
            from(
              record in query,
              left_join: association in assoc(record, unquote(association_atom)),
              where: association.unquote(association_atom) in ^query_by
            )
          end

          def unquote(:"by_#{association_atom}")(query, query_by) do
            from(
              record in query,
              left_join: association in assoc(record, unquote(association_atom)),
              where: association.unquote(association_atom) == ^query_by
            )
          end

          defoverridable "by_#{unquote(association_atom)}": 2
        end
      end)

    fields =
      :fields
      |> schema.__schema__()
      |> Enum.reject(&Belial.Query.reject_field?/1)

    field_list =
      Enum.map(fields, fn field ->
        quote location: :keep do
          def unquote(:"by_#{field}")(query, query_by) when is_list(query_by) do
            from(
              record in query,
              where: record.unquote(field) in ^query_by
            )
          end

          def unquote(:"by_#{field}")(query, query_by) do
            from(
              record in query,
              where: record.unquote(field) == ^query_by
            )
          end

          defoverridable "by_#{unquote(field)}": 2
        end
      end)

    assoc_list ++ field_list
  end

  # TODO - add automatic generation of scopes for these?
  @reject_fields [:inserted_at, :updated_at, :deleted_at]
  def reject_field?(field), do: Enum.member?(@reject_fields, field)

  @spec list(map, schema :: module) :: Query.t()
  def list(params_map, schema) do
    Enum.reduce(params_map, schema, &reducer/2)
  end

  defp reducer({key, value}, query) when is_list(value) do
    where(query, [record], field(record, ^key) in ^value)
  end

  defp reducer({key, value}, query) do
    where(query, [record], field(record, ^key) == ^value)
  end
end
