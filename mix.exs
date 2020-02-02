defmodule Belial.MixProject do
  use Mix.Project

  def project do
    [
      app: :belial,
      version: "0.1.0",
      elixir: "~> 1.9",
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 2.0"},
      {:phoenix, "~> 1.4.9"},
      {:phoenix_live_view, "~> 0.5.1"},
      {:plug, "~> 1.8"},
      {:bodyguard, "~> 2.2"},
      {:jason, "~> 1.0"},
      {:inflex, "~> 2.0.0"},
      {:absinthe, "~> 1.4"},
      {:absinthe_plug, "~> 1.4"},
      {:apollo_tracing, "~> 0.4.1"},
      {:dataloader, "~> 1.0.0"},
      {:absinthe_error_payload, "~> 1.0"},
      {:speakeasy, "~> 0.3.0"},
      {:scrivener, "~> 2.0"},
      {:scrivener_ecto, "~> 2.0"},
      {:scrivener_html, "~> 1.8"}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
