defmodule Cldr.Units.Mixfile do
  use Mix.Project

  @version "4.0.0"

  def project do
    [
      app: :ex_cldr_units,
      version: @version,
      elixir: "~> 1.11",
      name: "Cldr Units",
      source_url: "https://github.com/elixir-cldr/cldr_units",
      description: description(),
      package: package(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [Phoenix.HTML.Safe]],
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps: ~w(inets jason mix)a
      ]
    ]
  end

  defp description do
    """
    Unit formatting (volume, area, length, ...), conversion and arithmetic
    functions based upon the Common Locale Data Repository (CLDR).
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr_numbers, path: "../cldr_numbers", override: true},
      #{:ex_cldr_numbers, "~> 2.23.0"},

      {:cldr_utils, path: "../cldr_utils", override: true},
      # {:cldr_utils, "~> 2.25"},

      {:ex_cldr_lists, "~> 2.10"},

      {:decimal, "~> 1.6 or ~> 2.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", optional: true, runtime: false},
      {:jason, "~> 1.0", optional: true},
      {:benchee, "~> 1.0", optional: true, only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "priv",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      logo: "logo.png",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["changelog", "CHANGELOG.md"]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-cldr/cldr_units",
      "Readme" => "https://github.com/elixir-cldr/cldr_units/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/elixir-cldr/cldr_units/blob/v#{@version}/CHANGELOG.md"
    }
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
