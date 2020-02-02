defmodule Belial.Web.FallbackController do
  @moduledoc """
  Default fallback controller for Belial
  """
  use Phoenix.Controller

  alias Belial.Web.Views.ErrorView

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(ErrorView)
    |> render(:"403")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_view(ErrorView)
    |> put_status(:unprocessable_entity)
    |> assign(:changeset, changeset)
    |> render(:"422")
  end
end
