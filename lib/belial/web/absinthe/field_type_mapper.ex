defprotocol Belial.Web.Absinthe.FieldTypeMapper do
  @doc """
  Field type mapper for elixir to Absinthe field types.

  Example usage:

  defmodule MyApp.Belial.FieldTypeMapper do
    use Belial.Web.Absinthe.FieldTypeMapperHelper

    def mapping do
      [
        {MyApp.Image.Type, :string},
        {MyApp.VideoFile.Type, :string},
        {MyApp.CustomEctoEnum, :string},
        {:utc_datetime, :string},
        {:map, :string}
      ]
    end
  end

  """
  def convert_type(type)
end

defmodule Belial.Web.Absinthe.FieldTypeMapperHelper do
  @callback mapping() :: Keyword.t()

  def mapping do
    [
      id: :id,
      binary_id: :string,
      string: :string,
      integer: :integer,
      boolean: :boolean,
      naive_datetime: :naive_datetime
    ]
  end

  defmacro __using__(_) do
    quote do
      @behaviour Belial.Web.Absinthe.FieldTypeMapperHelper

      def mapping(), do: []
      defoverridable mapping: 0

      @after_compile Belial.Web.Absinthe.FieldTypeMapperHelper
    end
  end

  defmacro __after_compile__(env, _bytecode) do
    mapping = Keyword.merge(mapping(), env.module.mapping())

    quote do
      defimpl Belial.Web.Absinthe.FieldTypeMapper, for: Atom do
        Belial.Web.Absinthe.FieldTypeMapperHelper.convert_type_fragment(unquote(mapping))
      end
    end
  end

  defmacro convert_type_fragment(mapping) do
    Enum.map(mapping, fn {ecto_type, absinthe_type} ->
      quote do
        def convert_type(unquote(ecto_type)), do: unquote(absinthe_type)
      end
    end)
  end
end
