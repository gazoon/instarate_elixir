defmodule Voting.Mixfile do
  use Mix.Project

  def project do
    [
      app: :voting,
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
      mod: {Voting.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true},
      {:mongodb, ">= 0.0.0"},
      {:poolboy, ">= 0.0.0"},
      {:db_connection, ">= 0.0.0"},
      {:httpoison, "~> 0.13"},
      {:poison, "~> 3.1"},
      {:goth, "~> 0.7.1"},
      {:uuid, "~> 1.1"},
      {:utils, path: "../utils"}
    ]
  end
end
