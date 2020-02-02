defmodule Belial.Web.Views.ApiView do
  use Phoenix.View, root: Path.expand(Path.join(__ENV__.file, "../../templates/"))

  def render("index.json", %{page: page}) do
    %{
      errors: %{},
      meta: %{},
      data: page
    }
  end

  def render("show.json", %{resource: resource}) do
    %{
      errors: %{},
      meta: %{},
      data: resource
    }
  end
end
