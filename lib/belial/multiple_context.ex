defmodule Belial.MultiSchemaContext do
  @moduledoc """
  Sets up overridable default CRUD actions for context.

  Requires passing in Keyword pairs for :schema, :repo, and optionally
  :delegate, :read_repo, :write_repo, and :abinsthe?.

  Defines the following functions with the ability to override them
  for each schema:
    data/0
    query/2
    list/1
    paginated_list/2
    search_by/2 & search_by/3
    get!/1
    get_by!/1
    change/1
    create/1
    update/2
    delete/2
  """

  # credo:disable-for-this-file

  require Ecto.Query

  @spec search_query_where_ilike(Ecto.Queryable.t(), atom | [atom], String.t()) :: Ecto.Query.t()
  def search_query_where_ilike(queryable, search_fields, search_value)
      when is_list(search_fields) do
    Enum.reduce(search_fields, queryable, fn search_field, acc ->
      Ecto.Query.or_where(
        acc,
        [record],
        ilike(field(record, ^search_field), ^"%#{search_value}%")
      )
    end)
  end

  def search_query_where_ilike(queryable, search_field, search_value)
      when is_atom(search_field) do
    search_query_where_ilike(queryable, [search_field], search_value)
  end

  defp compile_time_check!(read_repo) do
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
  end

  defmacro __using__(opts) do
    schema = Macro.expand(Keyword.fetch!(opts, :schema), __CALLER__)
    delegate = Macro.expand(Keyword.fetch!(opts, :delegate), __CALLER__)

    read_repo =
      Macro.expand(Keyword.get(opts, :read_repo), __CALLER__) ||
        Macro.expand(Keyword.get(opts, :repo), __CALLER__)

    write_repo =
      Macro.expand(Keyword.get(opts, :write_repo), __CALLER__) ||
        Macro.expand(Keyword.get(opts, :repo), __CALLER__)

    compile_time_check!(read_repo)

    absinthe? = Keyword.get(opts, :absinthe?, false)
    singular = Belial.Schema.get_singular(schema)
    plural = Belial.Schema.get_plural(schema)

    quote location: :keep do
      require Ecto.Query

      if unquote(absinthe?) do
        @doc """
        For use with Absinthe Dataloader functionality.
        """
        if function_exported?(unquote(delegate), :data, 0) do
          defdelegate :"#{unquote(plural)}_data", to: unquote(delegate), as: :data
        else
          def unquote(:"#{plural}_data")() do
            Dataloader.Ecto.new(unquote(read_repo), query: &query/2)
          end

          unless function_exported?(__MODULE__, :data, 0) do
            def data, do: Dataloader.Ecto.new(unquote(read_repo), query: &query/2)
            defoverridable data: 0
          end
        end

        @doc """
        For use with Absinthe Dataloader functionality.
        """
        @spec query(Ecto.Queryable.t(), any) :: Ecto.Queryable.t()
        if function_exported?(unquote(delegate), :query, 2) do
          defdelegate :query, to: unquote(delegate)
        else
          unless function_exported?(__MODULE__, :query, 2) do
            def query(queryable, _params), do: queryable
            defoverridable query: 2
          end
        end
      end

      @doc """
      List #{unquote(plural)}.

      ## Examples

          iex> list_#{unquote(plural)}()
          [%#{unquote(schema)}{}]
      """
      @spec unquote(:"list_#{plural}")(Ecto.Queryable.t()) :: unquote(schema).t() | no_return
      if function_exported?(unquote(delegate), :list, 1) do
        defdelegate :"list_#{unquote(plural)}", to: unquote(delegate), as: :list
      else
        def unquote(:"list_#{plural}")(queryable \\ unquote(schema)) do
          unquote(read_repo).all(queryable)
        end

        defoverridable "list_#{unquote(plural)}": 1
      end

      @doc """
      Paginated list #{unquote(plural)}.

      ## Examples

          iex> paginated_list_#{unquote(plural)}()
          [%#{unquote(schema)}{}]
      """
      @spec unquote(:"paginated_list_#{plural}")(
              Ecto.Queryable.t() | map(),
              page_number :: pos_integer()
            ) :: %Scrivener.Page{
              entries: list(%unquote(schema){}),
              page_number: pos_integer(),
              page_size: integer(),
              total_entries: integer(),
              total_pages: pos_integer()
            }
      if function_exported?(unquote(delegate), :paginated_list, 2) do
        defdelegate :"paginated_list_#{unquote(plural)}",
          to: unquote(delegate),
          as: :paginated_list
      else
        def unquote(:"paginated_list_#{plural}")(
              queryable \\ unquote(schema),
              page_number \\ 1
            )

        @doc """
        Handles module case
        """
        def unquote(:"paginated_list_#{plural}")(queryable, page_number)
            when is_atom(queryable) do
          unquote(read_repo).paginate(queryable, page: page_number)
        end

        def unquote(:"paginated_list_#{plural}")(%Ecto.Query{} = queryable, page_number) do
          unquote(read_repo).paginate(queryable, page: page_number)
        end

        def unquote(:"paginated_list_#{plural}")(query_params, page_number)
            when is_map(query_params) do
          unquote(read_repo).paginate(Belial.Query.list(query_params, unquote(schema)),
            page: page_number
          )
        end

        def unquote(:"paginated_list_#{plural}")(queryable, page_number) do
          unquote(read_repo).paginate(queryable, page: page_number)
        end

        defoverridable "paginated_list_#{unquote(plural)}": 2
      end

      @doc """
      Case insensitive search for a list of #{unquote(singular)}
      by a given field, or list of fields.

      ## Examples

          iex> search_#{unquote(plural)}_by(:name, "bob")
          [%#{unquote(schema)}{}]

          iex> search_#{unquote(plural)}_by([:name, :email], "bob")
          [%#{unquote(schema)}{}]
      """
      @spec unquote(:"search_#{plural}_by")(atom | [atom], any) :: [unquote(schema).t()]
      if function_exported?(unquote(delegate), :search_by, 2) do
        defdelegate :"search_#{unquote(plural)}_by", to: unquote(delegate), as: :search_by
      else
        def unquote(:"search_#{plural}_by")(search_fields, search_value) do
          apply(__MODULE__, :"search_#{unquote(plural)}_by", [
            unquote(schema),
            search_fields,
            search_value
          ])
        end

        defoverridable "search_#{unquote(plural)}_by": 2
      end

      @doc """
      Case insensitive search for a list of #{unquote(singular)}
      by a given field, or list of fields.

      ## Examples

          iex> search_#{unquote(plural)}_by(#{unquote(schema)}, :name, "bob")
          [%#{unquote(schema)}{}]

          iex> search_#{unquote(plural)}_by(#{unquote(schema)}, [:name, :email], "bob")
          [%#{unquote(schema)}{}]
      """
      @spec unquote(:"search_#{plural}_by")(Ecto.Queryable.t(), atom | [atom], any) :: [
              unquote(schema).t()
            ]
      if function_exported?(unquote(delegate), :search_by, 3) do
        defdelegate :"search_#{unquote(plural)}_by", to: unquote(delegate), as: :search_by
      else
        def unquote(:"search_#{plural}_by")(queryable, search_fields, search_value) do
          queryable
          |> unquote(__MODULE__).search_query_where_ilike(search_fields, search_value)
          |> Ecto.Query.limit(5)
          |> unquote(read_repo).all()
        end

        defoverridable "search_#{unquote(plural)}_by": 3
      end

      @doc """
      Gets a single #{unquote(singular)}.

      Raises `Ecto.NoResultsError` if the #{unquote(singular)} does not exist.

      ## Examples

          iex> get_#{unquote(singular)}!(123)
          %#{unquote(schema)}{}

          iex> get_#{unquote(singular)}!(456)
          ** (Ecto.NoResultsError)

      """
      @spec unquote(:"get_#{singular}!")(Belial.EctoID.t()) :: unquote(schema).t() | no_return
      if function_exported?(unquote(delegate), :get!, 1) do
        defdelegate :"get_#{unquote(singular)}!", to: unquote(delegate), as: :get!
      else
        def unquote(:"get_#{singular}!")(id), do: unquote(read_repo).get!(unquote(schema), id)
        defoverridable "get_#{unquote(singular)}!": 1
      end

      @doc """
      Gets a single #{unquote(singular)}.

      Raises `Ecto.NoResultsError` if the #{unquote(singular)} does not exist.

      ## Examples

          iex> get_#{unquote(singular)}_by!(123)
          %#{unquote(schema)}{}

          iex> get_#{unquote(singular)}_by!(456)
          ** (Ecto.NoResultsError)

      """
      @spec unquote(:"get_#{singular}_by!")(map()) :: unquote(schema).t() | no_return
      if function_exported?(unquote(delegate), :get_by!, 1) do
        defdelegate :"get_#{unquote(singular)}_by!", to: unquote(delegate), as: :get_by!
      else
        def unquote(:"get_#{singular}_by!")(attrs) do
          unquote(read_repo).get_by!(unquote(schema), attrs)
        end

        defoverridable "get_#{unquote(singular)}_by!": 1
      end

      @doc """
      Gets a single #{unquote(singular)}.

      Returns `nil` if the #{unquote(singular)} does not exist.

      ## Examples

          iex> get_#{unquote(singular)}(123)
          %#{unquote(schema)}{}

          iex> get_#{unquote(singular)}(456)
          nil

      """
      @spec unquote(:"get_#{singular}")(Belial.EctoID.t()) :: unquote(schema).t() | nil
      if function_exported?(unquote(delegate), :get, 1) do
        defdelegate :"get_#{unquote(singular)}", to: unquote(delegate), as: :get
      else
        def unquote(:"get_#{singular}")(id), do: unquote(read_repo).get(unquote(schema), id)
        defoverridable "get_#{unquote(singular)}": 1
      end

      @doc """
      Gets a single #{unquote(singular)}.

      Returns `nil` if the #{unquote(singular)} does not exist.

      ## Examples

          iex> get_#{unquote(singular)}_by(123)
          %#{unquote(schema)}{}

          iex> get_#{unquote(singular)}_by(456)
          nil

      """
      @spec unquote(:"get_#{singular}_by")(map()) :: unquote(schema).t() | nil
      if function_exported?(unquote(delegate), :get_by, 1) do
        defdelegate :"get_#{unquote(singular)}_by", to: unquote(delegate), as: :get_by
      else
        def unquote(:"get_#{singular}_by")(attrs) do
          unquote(read_repo).get_by(unquote(schema), attrs)
        end

        defoverridable "get_#{unquote(singular)}_by": 1
      end

      @doc """
      Returns an `%Ecto.Changeset{}` for tracking #{unquote(singular)} changes.

      ## Examples

          iex> change_#{unquote(singular)}(#{unquote(singular)})
          %Ecto.Changeset{source: %#{unquote(schema)}{}}

      """
      @spec unquote(:"change_#{singular}")(unquote(schema).t() | map()) :: Ecto.Changeset.t()
      if function_exported?(unquote(delegate), :change, 1) do
        defdelegate :"change_#{unquote(singular)}", to: unquote(delegate), as: :change
      else
        def unquote(:"change_#{singular}")(resource \\ %unquote(schema){})

        def unquote(:"change_#{singular}")(%unquote(schema){} = resource) do
          unquote(schema).changeset(resource, %{})
        end

        def unquote(:"change_#{singular}")(params) when is_map(params) do
          unquote(schema).changeset(%unquote(schema){}, params)
        end

        defoverridable "change_#{unquote(singular)}": 1
      end

      @doc """
      Creates #{unquote(singular)}.

      ## Examples

          iex> create_#{unquote(singular)}(%{field: value})
          {:ok, %#{unquote(schema)}{}}

          iex> create_#{unquote(singular)}(%{field: bad_value})
          {:error, %Ecto.Changeset{}}

      """
      if function_exported?(unquote(delegate), :create, 1) do
        defdelegate :"create_#{unquote(singular)}", to: unquote(delegate), as: :create
      else
        @spec unquote(:"create_#{singular}")(map()) ::
                {:ok, unquote(schema).t()} | {:error, Ecto.Changeset.t()}
        def unquote(:"create_#{singular}")(attrs) do
          %unquote(schema){}
          |> unquote(schema).changeset(attrs)
          |> unquote(write_repo).insert()
        end

        defoverridable "create_#{unquote(singular)}": 1
      end

      @doc """
      Updates #{unquote(singular)}.

      ## Examples

          iex> update_#{unquote(singular)}(#{unquote(singular)}, %{field: new_value})
          {:ok, %Episode{}}

          iex> update_#{unquote(singular)}(#{unquote(singular)}, %{field: bad_value})
          {:error, %Ecto.Changeset{}}

      """
      if function_exported?(unquote(delegate), :update, 2) do
        defdelegate :"update_#{unquote(singular)}", to: unquote(delegate), as: :update
      else
        @spec unquote(:"update_#{singular}")(unquote(schema).t(), map()) ::
                {:ok, unquote(schema).t()} | {:error, Ecto.Changeset.t()}
        def unquote(:"update_#{singular}")(%unquote(schema){} = resource, attrs) do
          resource
          |> unquote(schema).changeset(attrs)
          |> unquote(write_repo).update()
        end

        defoverridable "update_#{unquote(singular)}": 2
      end

      if function_exported?(unquote(delegate), :delete, 1) do
        defdelegate :"delete_#{unquote(singular)}", to: unquote(delegate), as: :delete
      else
        @doc """
        Deletes #{unquote(singular)}.

        ## Examples

            iex> delete_#{unquote(singular)}(#{unquote(singular)})
            {:ok, %Episode{}}

            iex> delete_#{unquote(singular)}(#{unquote(singular)})
            {:error, %Ecto.Changeset{}}

        """

        @spec unquote(:"delete_#{singular}")(unquote(schema).t()) ::
                {:ok, unquote(schema).t()} | {:error, Ecto.Changeset.t()}
        def unquote(:"delete_#{singular}")(%unquote(schema){} = resource) do
          __MODULE__
          |> apply(:"change_#{unquote(singular)}", [resource])
          |> unquote(write_repo).delete()
        end

        defoverridable "delete_#{unquote(singular)}": 1
      end
    end
  end
end
