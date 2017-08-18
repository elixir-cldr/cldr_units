defmodule CldrUnits.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ex_cldr_units,
      version: @version,
      elixir: "~> 1.5",
      name: "Cldr_Units",
      source_url: "https://github.com/kipcole9/cldr_units",
      description: description(),
      package: package(),
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
      {:ex_cldr, "~> 0.5.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
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

  def links do
    %{
      "GitHub"    => "https://github.com/kipcole9/cldr_units",
      "Changelog" => "https://github.com/kipcole9/cldr_units/blob/v#{@version}/CHANGELOG.md"
    }
  end

end
