defmodule Belial.Web.Views.ErrorView do
  use Phoenix.View,
    root: "lib/belial/web/templates/errors",
    path: ""

  use Phoenix.HTML

  def render("401.json", _other_data) do
    %{
      errors: %{message: "not authenticated"},
      meta: %{},
      data: %{}
    }
  end

  def render("403.json", _other_data) do
    %{
      errors: %{message: "not authorized"},
      meta: %{},
      data: %{}
    }
  end

  def render("404.json", _other_data) do
    %{
      errors: %{message: "not found"},
      meta: %{},
      data: %{}
    }
  end

  def render("422.json", %{changeset: changeset}) do
    %{
      errors: encode_errors(changeset),
      meta: %{},
      data: %{}
    }
  end

  def encode_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
