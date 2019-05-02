defmodule TGBot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tg_bot,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      compilers: [:gettext] ++ Mix.compilers,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TGBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poolboy, ">= 0.0.0"},
      {:poison, "~> 3.1"},
      {:uuid, "~> 1.1"},
      {:nadia, git: "https://github.com/gazoon/nadia.git"},
      {:voting, path: "../voting"},
      {:utils, path: "../utils", override: true},
      {:distillery, "~> 1.5", runtime: false},
      {:db_connection, ">= 0.0.0"},
      {:mongodb, ">= 0.0.0"},
      {:httpoison, "~> 0.13"},
      {:gettext, "~> 0.13"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
    ]
  end
end
