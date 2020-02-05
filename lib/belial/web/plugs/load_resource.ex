defmodule Belial.Web.Plugs.LoadResource do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    schema = Keyword.fetch!(opts, :schema)
    context = Keyword.fetch!(opts, :context)
    actions = Keyword.fetch!(opts, :actions)

    if Enum.member?(actions, Phoenix.Controller.action_name(conn)) do
      primary_key = Belial.Schema.get_primary_key(schema)
      singular = Belial.Schema.get_singular(schema)

      resource =
        apply(context, :"get_#{singular}", [
          Map.get(conn.params, Atom.to_string(primary_key))
        ])

      assign(conn, :resource, resource)
    else
      conn
    end
  end
end
