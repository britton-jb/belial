defmodule Belial.SingularContext do
  @moduledoc """
  Sets up overridable default CRUD actions for context.
  Designed to be used with contexts relating to a single schema.

  Requires passing in Keyword pairs for :schema, :repo, and optionally
  :read_repo, :write_repo, and :abinsthe?.

  Defines the following functions with the ability to override them:
    data/0
    query/2
    list/1
    paginated_list/1
    get!/1
    get_by!/1
    change/1
    create/1
    update/2
    delete/2
  """

  # credo:disable-for-this-file

  @callback data() :: Dataloader.Ecto.t()
  @callback query(Ecto.Queryable.t(), any) :: Ecto.Queryable.t()
  @callback list(Ecto.Queryable.t()) :: [Ecto.Schema.t()]
  @callback paginated_list(Ecto.Queryable.t()) :: %Scrivener.Page{}
  @callback get!(Belial.EctoID.t()) :: Ecto.Schema.t() | no_return
  @callback get_by!(map()) :: Ecto.Schema.t() | no_return
  @callback get(Belial.EctoID.t()) :: Ecto.Schema.t() | nil
  @callback get_by(map()) :: Ecto.Schema.t() | nil
  @callback change(Ecto.Schema.t()) :: Ecto.Changeset.t()
  @callback create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback update(Ecto.Schema.t(), map()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback delete(Ecto.Schema.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @optional_callbacks data: 0, query: 2

  defmacro __using__(opts) do
    schema = Macro.expand(Keyword.get(opts, :schema), __CALLER__)

    read_repo =
      Macro.expand(Keyword.get(opts, :read_repo), __CALLER__) ||
        Macro.expand(Keyword.get(opts, :repo), __CALLER__)

    write_repo =
      Macro.expand(Keyword.get(opts, :write_repo), __CALLER__) ||
        Macro.expand(Keyword.get(opts, :repo), __CALLER__)

    if is_nil(schema) do
      raise(Belial.CompileTimeError, "#{__MODULE__} __using__ requires a :schema")
    end

    if is_nil(read_repo) do
      raise(Belial.CompileTimeError, "#{__MODULE__} __using__ requires a :repo")
    end

    # FIXME this worked when it existed as part of a greater project, fails stand alone.
    # unless function_exported?(read_repo, :paginate, 2) do
    #   raise(
    #     Belial.CompileTimeError,
    #     "#{__MODULE__} __using__ requires a :repo that uses Scrivener"
    #   )
    # end

    absinthe? = Keyword.get(opts, :absinthe?, false)

    quote do
      @behaviour Belial.SingularContext

      if unquote(absinthe?) do
        @doc """
        For use with Absinthe Dataloader functionality.
        """
        @spec data() :: Dataloader.Ecto.t()
        def data() do
          Dataloader.Ecto.new(unquote(read_repo), query: &query/2)
        end

        @doc """
        For use with Absinthe Dataloader functionality.
        """
        @spec query(Ecto.Queryable.t(), any) :: Ecto.Queryable.t()
        def query(queryable, _params), do: queryable
      end

      @doc """
      Gets a list of #{unquote(schema)}.

      ## Examples

          iex> list(unquote(schema))
          [%#{unquote(schema)}{}]
      """
      @spec list(Ecto.Queryable.t()) :: [unquote(schema).t()]
      def list(query \\ unquote(schema)), do: unquote(read_repo).all(query)
      defoverridable list: 1

      @doc """
      Gets a paginated list of #{unquote(schema)}.

      ## Examples

          iex> paginated_list(unquote(schema))
          [%#{unquote(schema)}{}]
      """
      @spec paginated_list(Ecto.Queryable.t(), page_number :: pos_integer()) :: %Scrivener.Page{
              entries: list(%unquote(schema){}),
              page_number: pos_integer(),
              page_size: integer(),
              total_entries: integer(),
              total_pages: pos_integer()
            }
      def paginated_list(queryable \\ unquote(schema), page_number \\ 1) do
        unquote(read_repo).paginate(queryable, page: page_number)
      end

      defoverridable paginated_list: 2

      @doc """
      Gets a single #{unquote(schema)}.

      Raises `Ecto.NoResultsError` if the #{unquote(schema)} does not exist.

      ## Examples

          iex> get!(123)
          %#{unquote(schema)}{}

          iex> get!(456)
          ** (Ecto.NoResultsError)

      """
      @spec get!(Belial.EctoID.t()) :: unquote(schema).t() | no_return
      def get!(id), do: unquote(read_repo).get!(unquote(schema), id)
      defoverridable get!: 1

      @doc """
      Gets a single #{unquote(schema)}.

      Raises `Ecto.NoResultsError` if the #{unquote(schema)} does not exist.

      ## Examples

          iex> get_by!(123)
          %#{unquote(schema)}{}

          iex> get_by!(456)
          ** (Ecto.NoResultsError)

      """
      @spec get_by!(map()) :: unquote(schema).t() | nil
      def get_by!(attrs) do
        unquote(read_repo).get_by!(unquote(schema), attrs)
      end

      defoverridable get_by!: 1

      @doc """
      Gets a single #{unquote(schema)}.

      Returns `nil` if the #{unquote(schema)} does not exist.

      ## Examples

          iex> get(123)
          %#{unquote(schema)}{}

          iex> get(456)
          nil

      """
      @spec get(Belial.EctoID.t()) :: unquote(schema).t() | nil
      def get(id), do: unquote(read_repo).get(unquote(schema), id)
      defoverridable get: 1

      @doc """
      Gets a single #{unquote(schema)}.

      Returns `nil` if the #{unquote(schema)} does not exist.

      ## Examples

          iex> get_by(123)
          %#{unquote(schema)}{}

          iex> get_by(456)
          nil

      """
      @spec get_by(map()) :: unquote(schema).t() | nil
      def get_by(attrs) do
        unquote(read_repo).get_by(unquote(schema), attrs)
      end

      defoverridable get_by: 1

      @doc """
      Returns an `%Ecto.Changeset{}` for tracking #{unquote(schema)} changes.

      ## Examples

          iex> change(#{unquote(schema)})
          %Ecto.Changeset{source: %#{unquote(schema)}{}}

      """
      @spec change(unquote(schema).t() | map()) :: Ecto.Changeset.t()
      def change(resource \\ %unquote(schema){})

      def change(%unquote(schema){} = resource) do
        unquote(schema).changeset(resource, %{})
      end

      def change(params) when is_map(params) do
        unquote(schema).changeset(%unquote(schema){}, params)
      end

      defoverridable change: 1

      @doc """
      Creates #{unquote(schema)}.

      ## Examples

          iex> create_#{unquote(schema)}(%{field: value})
          {:ok, %#{unquote(schema)}{}}

          iex> create_#{unquote(schema)}(%{field: bad_value})
          {:error, %Ecto.Changeset{}}

      """
      @spec create(map()) ::
              {:ok, unquote(schema).t()} | {:error, Ecto.Changeset.t()}
      def create(attrs) do
        %unquote(schema){}
        |> unquote(schema).changeset(attrs)
        |> unquote(write_repo).insert()
      end

      defoverridable create: 1

      @doc """
      Updates #{unquote(schema)}.

      ## Examples

          iex> update(#{unquote(schema)}, %{field: new_value})
          {:ok, %Episode{}}

          iex> update(#{unquote(schema)}, %{field: bad_value})
          {:error, %Ecto.Changeset{}}

      """
      @spec update(unquote(schema).t(), map()) ::
              {:ok, unquote(schema).t()} | {:error, Ecto.Changeset.t()}
      def update(%unquote(schema){} = resource, attrs) do
        resource
        |> unquote(schema).changeset(attrs)
        |> unquote(write_repo).update()
      end

      defoverridable update: 2

      @doc """
      Deletes #{unquote(schema)}.

      ## Examples

          iex> delete(#{unquote(schema)})
          {:ok, %Episode{}}

          iex> delete(#{unquote(schema)})
          {:error, %Ecto.Changeset{}}

      """

      @spec delete(unquote(schema).t()) ::
              {:ok, unquote(schema).t()} | {:error, Ecto.Changeset.t()}
      def delete(%unquote(schema){} = resource) do
        resource
        |> change()
        |> unquote(write_repo).delete()
      end

      defoverridable delete: 1
    end
  end
end
