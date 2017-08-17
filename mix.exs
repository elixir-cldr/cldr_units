defmodule CldrUnits.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_cldr_units,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr, path: "../cldr"}
    ]
  end
end
