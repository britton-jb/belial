defmodule Belial.Web.Live.SearchLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <form phx-change="suggest" phx-submit="search">
      <input phx-throttle="300" id="adminSearch" type="text" name="q" value="<%= @query %>" list="matches" placeholder="Search..." phx-hook="AdminSearch"
             <%= if @loading, do: "readonly" %>/>
      <datalist id="matches">
        <%= for match <- @matches do %>
          <%= Belial.Web.Views.AdminView.live_search_option(@schema, @search_fields, match) %>
        <% end %>
      </datalist>
      <%= if @result do %><pre><%= @result %></pre><% end %>
    </form>
    """
  end

  def mount(%{"context" => context, "schema" => schema, "search_fields" => search_fields}, socket) do
    {:ok,
     assign(socket,
       query: nil,
       context: context,
       schema: schema,
       search_fields: search_fields,
       result: nil,
       loading: false,
       matches: []
     )}
  end

  def handle_event("suggest", %{"q" => query}, socket)
      when byte_size(query) <= 100 do
    context = socket.assigns.context
    plural = Belial.Schema.get_plural(socket.assigns.schema)
    search_fields = socket.assigns.search_fields

    matches =
      if String.length(query) > 2 do
        apply(context, :"search_#{plural}_by", [search_fields, query])
      else
        []
      end

    {:noreply, assign(socket, matches: matches)}
  end

  def handle_event("search", %{"q" => query}, socket)
      when byte_size(query) <= 100 do
    send(self(), {:search, query})

    {:noreply,
     assign(socket,
       query: query,
       result: "Searching...",
       loading: true,
       matches: socket.assigns.matches
     )}
  end

  def handle_info({:search, query}, socket) do
    schema = socket.assigns.schema
    primary_key = Belial.Schema.get_primary_key(schema)

    result =
      Enum.find(socket.assigns.matches, fn match ->
        inspect(Map.get(match, primary_key)) == query
      end)

    {:stop,
     redirect(socket,
       to:
         apply(
           Belial.Web.Views.AdminView.routes(),
           :"#{Belial.Schema.get_singular(schema)}_path",
           [socket, :show, result]
         )
     )}
  end
end
