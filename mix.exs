defmodule Pockets.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :pockets,
      name: "Pockets",
      description:
        "Pockets is an Elixir wrapper around Erlang :ets and :dets, a disk-based term storage. It offers a simple key/value store with a familiar interface.",
      source_url: "https://github.com/fireproofsocks/pockets",
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        source_ref: "v#{@version}",
        logo: "docs/logo.png",
        main: "overview",
        extras: extras()
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Extra pages for the docs
  def extras do
    [
      "docs/overview.md"
    ]
  end

  defp package do
    [
      maintainers: ["Everett Griffiths"],
      licenses: ["Apache 2.0"],
      logo: "docs/logo.png",
      links: links(),
      files: [
        "lib",
        "docs/logo.png",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/fireproofsocks/pockets",
      "Readme" => "https://github.com/fireproofsocks/pockets/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/fireproofsocks/pockets/blob/v#{@version}/CHANGELOG.md"
    }
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Pockets.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.22.5", only: :dev, runtime: false}
    ]
  end
end
