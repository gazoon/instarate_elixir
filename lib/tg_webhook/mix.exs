defmodule TgWebhook.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tg_webhook,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TGWebhook.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.1.2"},
      {:plug, "~> 1.4.3"},
      {:distillery, "~> 1.5", runtime: false},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.13"},
      {:utils, path: "../utils"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
