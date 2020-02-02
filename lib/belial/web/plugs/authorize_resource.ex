defmodule Belial.Web.Plugs.AuthorizeResource do
  def init(opts), do: opts

  def call(conn, opts) do
    user = conn.assigns.current_user
    policy = Keyword.get(opts, :policy)
    action = Phoenix.Controller.action_name(conn)
    resource = conn.assigns.resource

    case Bodyguard.permit(policy, action, user, resource) do
      :ok -> conn
      {:error, _} -> {:error, :unauthorized}
    end
  end
end
