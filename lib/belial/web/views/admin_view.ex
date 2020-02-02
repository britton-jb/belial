defmodule Belial.Web.Views.AdminView do
  use Phoenix.View,
    root: Path.expand(Path.join(__ENV__.file, "../../templates/")),
    path: ""

  use Phoenix.HTML

  import Scrivener.HTML
  import Phoenix.LiveView.Helpers

  def routes do
    Application.get_env(:belial, :admin_view_router)
  end

  def has_link(conn, schema, resource, assoc_atom) do
    related_singular =
      Belial.Schema.get_singular(Map.get(schema.__schema__(:association, assoc_atom), :related))

    if function_exported?(routes(), :"#{related_singular}_path", 3) do
      related_key = Map.get(schema.__schema__(:association, assoc_atom), :related_key)
      owner_key = Map.get(schema.__schema__(:association, assoc_atom), :owner_key)
      owner_value = Map.get(resource, owner_key)

      related_index_route =
        apply(routes(), :"#{related_singular}_path", [
          conn,
          :index,
          %{related_key => owner_value}
        ])

      link("List related #{assoc_atom}", to: related_index_route)
    else
      "No routes defined for #{assoc_atom}"
    end
  end

  def belongs_to_link(conn, schema, resource, assoc_atom) do
    related_singular =
      Belial.Schema.get_singular(Map.get(schema.__schema__(:association, assoc_atom), :related))

    if function_exported?(routes(), :"#{related_singular}_path", 3) do
      owner_key = Map.get(schema.__schema__(:association, assoc_atom), :owner_key)

      related_show_route =
        apply(routes(), :"#{related_singular}_path", [
          conn,
          :show,
          Map.get(resource, owner_key)
        ])

      link("#{assoc_atom |> Atom.to_string() |> String.capitalize()}", to: related_show_route)
    else
      "No routes defined for #{assoc_atom}"
    end
  end

  def live_search_option(schema, search_field, match) when is_atom(search_field) do
    live_search_option(schema, [search_field], match)
  end

  def live_search_option(schema, search_fields, match) when is_list(search_fields) do
    primary_key = Belial.Schema.get_primary_key(schema)
    primary_key_value = Map.get(match, primary_key)

    show_to_user =
      match
      |> Map.take(search_fields)
      |> Map.values()

    content_tag(:option, show_to_user, value: primary_key_value)
  end

  # FIXME use LiveView checkboxes to decide what to render?
  def fields_to_render(schema) do
    # FIXME add some sort of helper for "don't render these"?
    case {function_exported?(schema, :required, 0), function_exported?(schema, :optional, 0)} do
      {true, true} ->
        schema.required() ++ schema.optional()

      {true, false} ->
        schema.required()

      {false, true} ->
        schema.optional()

      {false, false} ->
        primary_key = Belial.Schema.get_primary_key(schema)
        fields_to_reject = [primary_key, :inserted_at, :updated_at]

        :fields
        |> schema.__schema__()
        |> Enum.reject(fn field -> Enum.member?(fields_to_reject, field) end)
    end
  end

  def form_field_mapper(form, schema, field) do
    # FIXME make this more intelligent based on work done with absinthe?
    case schema.__schema__(:type, field) do
      :integer ->
        number_input(form, field)

      :naive_datetime ->
        datetime_select(form, field)

      :utc_datetime ->
        datetime_select(form, field)

      :boolean ->
        checkbox(form, field)

      _ ->
        text_input(form, field)
    end
  end

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, elem(error, 0), class: "help-block")
    end)
  end
end
