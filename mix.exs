defmodule Pockets.MixProject do
  use Mix.Project

  @source_url "https://github.com/fireproofsocks/pockets"
  @version "1.0.0"

  def project do
    [
      app: :pockets,
      name: "Pockets",
      description: description(),
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test],
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @source_url,
        logo: "assets/logo.png",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  defp description do
    """
    Pockets is an Elixir wrapper around Erlang :ets and :dets, a disk-based
    term storage. It offers a simple key/value store with a familiar interface.
    This is a simple alternative to :mnesia or Redis.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Everett Griffiths"],
      licenses: ["Apache 2.0"],
      logo: "assets/logo.png",
      links: links(),
      files: [
        "lib",
        "assets/logo.png",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def links do
    %{
      "GitHub" => @source_url,
      "Readme" => "#{@source_url}/blob/v#{@version}/README.md",
      "Changelog" => "#{@source_url}/blob/v#{@version}/CHANGELOG.md"
    }
  end

  def application do
    [
      mod: {Pockets.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22.5", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end
end
