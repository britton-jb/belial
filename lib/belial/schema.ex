defmodule Belial.Schema do
  @moduledoc """
  Shared schema code.
  Requires the implementation of the following callbacks:

  __test_repo/0
  __test_factory/0

  And optionally allows you to override the following callbacks:

  changeset/2
  to_struct/1
  __singularize/0
  __pluralize/0
  __test_resource_atom/0

  Implements the Access behaviour and a default changeset.

  Also create dynamically creates a MyApp.Context.Schema.Query
  module and scopes/query definitinos for `with_x` and `by_x`.

  Example usage:

  defmodule MyApp.Schema do
    defmacro __using__(_) do
      quote do
        alias MyApp.Repo
        use Belial.Schema
        @impl true
        def __test_factory(), do: MyApp.Factory

        @impl true
        def __test_repo(), do: MyApp.Repo
      end
    end
  end
  """

  @callback changeset(Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  @callback to_struct(map) :: Ecto.Schema.t()
  @callback __singularize() :: String.t()
  @callback __pluralize() :: String.t()
  @callback __test_repo() :: Ecto.Repo.t()
  @callback __test_factory() :: module
  @callback __test_resource_atom() :: atom
  @optional_callbacks __singularize: 0, __pluralize: 0, __test_resource_atom: 0

  @doc """
  Fetches the primary key atom for a given schema module or struct
  """
  @spec get_primary_key(module() | Ecto.Schema.t()) :: atom()
  def get_primary_key(schema) when is_atom(schema) do
    :primary_key |> schema.__schema__() |> List.first()
  end

  def get_primary_key(%_schema{} = struct) do
    Ecto.primary_key(struct) |> Keyword.keys() |> List.first()
  end

  @doc """
  Fetches the singular string for a given schema module
  """
  @spec get_singular(module()) :: String.t()
  def get_singular(schema) do
    if function_exported?(schema, :__singularize, 0) do
      schema.__singularize()
    else
      Inflex.singularize(struct!(schema).__meta__.source)
    end
  end

  @doc """
  Fetches the plural string for a given schema module
  """
  @spec get_plural(module()) :: String.t()
  def get_plural(schema) do
    if function_exported?(schema, :__pluralize, 0) do
      schema.__pluralize()
    else
      struct!(schema).__meta__.source
    end
  end

  defmacro __using__(opts) do
    primary_key_atom = Keyword.get(opts, :primary_key, :id)

    quote location: :keep do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query, warn: false
      import EctoEnum

      # FIXME flip between embedded schema and not option based on passed in opts here in after_compile?
      @after_compile Belial.Schema

      @type t :: %__MODULE__{}

      @derive {Jason.Encoder, only: [unquote(primary_key_atom) | @required ++ @optional]}
      @behaviour Access

      @impl true
      defdelegate fetch(resource, key), to: Map

      @impl true
      defdelegate get_and_update(resource, key, function), to: Map

      @impl true
      defdelegate pop(resource, key), to: Map

      @doc """
      Extensible base from which to build other changesets
      """
      @spec changeset_base(t(), map) :: Ecto.Changeset.t()
      def changeset_base(resource, attrs \\ %{}) do
        resource
        |> cast(attrs, @required ++ @optional)
        |> validate_required(@required)
      end

      @behaviour Belial.Schema

      @impl true
      def changeset(resource, attrs \\ %{}), do: changeset_base(resource, attrs)
      defoverridable changeset: 2

      @impl true
      @spec to_struct(map) :: __MODULE__.t()
      def to_struct(map) do
        __MODULE__
        |> struct()
        |> changeset(map)
        |> apply_changes()

        # FIXME impl this properly - actually the keys_to_atoms function I impl'd for web
        # Enum.reduce(map, %{}, fn {k, v}, acc ->
        #   if Enum.member?(derived_fields, k)
        #     Map.put(acc, String.to_existing_atom(k), v)
        #   else
        #     acc
        #   end
        # end)
      end

      defoverridable to_struct: 1
    end
  end

  defmacro __after_compile__(env, _bytecode) do
    Belial.CompileTimeError.test_module_attributes_defined?(env.module)
    query_module = Module.concat(env.module, Query)

    quote do
      defmodule unquote(query_module) do
        use Belial.Query, schema: unquote(env.module)
      end
    end
  end
end
