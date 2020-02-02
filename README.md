# Belial

This library is a random assortments of boilerplate removers or
other pieces of standardization I like in my Elixir apps. I'd actively
advise other folks to stear clear.

## Installation

Currently only available via GitHub install.

### Configuration

```elixir config.exs
config :belial,
  admin_view_router: MyAppWeb.Router.Helpers,
  field_type_mapper: MyApp.Belial.FieldTypeMapper, # optional
  modifiable_fields: MyApp.Belial.ChangeValueForField # optional

config :scrivener_html,
  routes_helper: MyAppWeb.Router.Helpers,
  view_style: :bootstrap

config :speakeasy,
  user_key: :current_user,
  authn_error_message: :unauthenticated
```

```elixir lib/my_app_web.ex
def router do
  quote do
    ...
    import Phoenix.LiveView.Router
  end
end
```

```elixir lib/my_app_web/endpoint.ex
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]]
   # Where @session_options are the options given to plug Plug.Session extracted to a module attribute.
```

Add LiveView NPM dependencies in your assets/package.json. For a regular project, do:

```json package.json
{
  "dependencies": {
    "phoenix": "file:../deps/phoenix",
    "phoenix_html": "file:../deps/phoenix_html",
    "phoenix_live_view": "file:../deps/phoenix_live_view"
  }
}
```

For umbrella installs see https://hexdocs.pm/phoenix_live_view/installation.html

Ensure you have placed a CSRF meta tag inside the <head> tag in your layout (lib/my_app_web/templates/layout/app.html.eex) like so:

```html
<%= csrf_meta_tag() %>
```

Enable connecting to a LiveView socket in your app.js file.

```js
// assets/js/app.js
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

Hooks.AdminSearch = {
  mounted() {
    const adminSearch = document.getElementById("adminSearch")

    adminSearch.addEventListener("input", e => {
      const val = adminSearch.value;
      const opts = document.getElementById("matches").childNodes;
      opts.forEach(element => {
        if (element.value == val) { this.pushEvent("search", { "q": val }) }
      })
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })

liveSocket.connect()
```

### Question marks

Could modifiable_fields be handled in the same way I handle field_type_mapper? -
Yes, yes it could. It could also be handled by an application config
by combining?

```elixir
mapping = Keyword.merge(
  Belial.Web.Absinthe.FieldTypeMapperHelper.mapping(),
  Application.get_env(:belial, :field_mapping_module_fn_tuple)
)
defimpl Belial.Web.Absinthe.FieldTypeMapper, for: Atom do
  Belial.Web.Absinthe.FieldTypeMapperHelper.convert_type_fragment(mapping)
end
```

Remove SingularContext, and rename MultipleContext to Context?

Add a default mapping for utc datetime?

### For other contributors/future

Do the JS includes for admin search the cool way that phx does?

Dynamically define enums from ecto enums, along with the types?

Add to_struct - based on @derive?, also absinthe schema based on a derive alike?

The handful of FIXMEs

String to atom noise reduction in absinthe

Support only/except options?

Move assoc_constraint, change_value_for_field, default_value, errors_on, exclusive_belongs_to, modifiable_fields, required_fields, and unique_constraint tests into a changeset context and dir?
