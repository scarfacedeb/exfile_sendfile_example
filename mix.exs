defmodule ExfileSendfile.MixProject do
  use Mix.Project

  def project do
    [
      app: :exfile_sendfile,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExfileSendfile.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exfile, "~> 0.3"},
      {:plug, "1.6.4"},
      {:cowboy, "~> 1.0"}
    ]
  end
end
