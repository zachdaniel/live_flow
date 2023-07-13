defmodule LiveFlow.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_flow,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  defp package do
    [
      name: :live_flow,
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/ash-project/ash"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      dev: "run dev.exs"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.18"},
      {:jason, "~> 1.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:plug_cowboy, "~> 2.5", only: :dev},
      {:esbuild, "~> 0.7", only: :dev},
      {:tailwind, "~> 0.2.0", only: :dev}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
