defmodule CldrUnits.Mixfile do
  use Mix.Project

  @version "0.4.2"

  def project do
    [
      app: :ex_cldr_units,
      version: @version,
      elixir: "~> 1.5",
      name: "Cldr_Units",
      source_url: "https://github.com/kipcole9/cldr_units",
      description: description(),
      package: package(),
      docs: docs(),
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  defp description do
    """
    Unit formatting (volume, area, length, ...) functions for the Common Locale Data Repository (CLDR)
    package ex_cldr
    """
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr, "~> 0.12.0"},
      {:ex_cldr_numbers, "~> 0.3.2"},
      {:ex_doc, ">= 0.18.1", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache 2.0"],
      links: links(),
      files: [
        "lib", "config", "mix.exs", "README*", "CHANGELOG*", "LICENSE*"
      ]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  def links do
    %{
      "GitHub"    => "https://github.com/kipcole9/cldr_units",
      "Readme"    => "https://github.com/kipcole9/cldr_units/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/kipcole9/cldr_units/blob/v#{@version}/CHANGELOG.md"
    }
  end

end
