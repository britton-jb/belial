defmodule Belial.Web.Plugs.LoadResource do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    schema = Keyword.get(opts, :schema)
    context = Keyword.get(opts, :context)
    actions = Keyword.get(opts, :actions)

    if is_nil(schema) && is_nil(context) && is_nil(actions) do
      raise(
        Belial.CompileTimeError,
        "#{__MODULE__} requires a :context, :schema, and :actions"
      )
    end

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
