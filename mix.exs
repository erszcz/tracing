defmodule Tracing.MixProject do
  use Mix.Project

  def project do
    [
      app: :tracing,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Tracing.Application, []}
    ]
  end

  def aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}

      # Tracing
      # {:ex_doctor, "~> 0.3.2"},
      {:ex_doctor,
       git: "https://github.com/erszcz/ex_doctor.git", branch: "main", override: true},
      {:extrace, "~> 0.6.0"},
      {:recon, "~> 2.5"},

      # AI agent
      {:tidewave, "~> 0.4", only: :dev},
      {:bandit, "~> 1.0", only: :dev}
    ]
  end
end
