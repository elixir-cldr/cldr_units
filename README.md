# Cldr for Units
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_units)
![Deps Status](https://beta.hexfaktor.org/badge/all/github/kipcole9/cldr_units.svg)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_units.svg?style=flat)](https://hex.pm/packages/ex_cldr_units)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/kipcole9/cldr_units/blob/master/LICENSE)

## Introduction and Getting Started

`ex_cldr_units` is an addon library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for units such as weights, lengths, areas, volumes and so on.

The primary api is `Cldr.Unit.to_string/2`.  The following examples demonstrate:

```elixir
iex> Cldr.Unit.to_string 123, :volume_gallon
{:ok, "123 gallons"}

iex> Cldr.Unit.to_string 1234, :volume_gallon, format: :long
{:ok, "1 thousand gallons"}

iex> Cldr.Unit.to_string 1234, :volume_gallon, format: :short
{:ok, "1K gallons"}

iex> Cldr.Unit.to_string 1234, :frequency_megahertz
{:ok, "1,234 megahertz"}
```

For help in `iex`:

```elixir
iex> h Cldr.Unit.to_string
```

## Documentation

Primary documentation is available as part of the [hex documentation for ex_cldr](https://hexdocs.pm/ex_cldr/4_list_formats.html)

## Installation

Note that `:ex_cldr_units` requires Elixir 1.5 or later.

Add `ex_cldr_dates_time` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_units, "~> 0.1.2"}
      ]
    end

then retrieve `ex_cldr_units` from [hex](https://hex.pm/packages/ex_cldr_units):

    mix deps.get
    mix deps.compile

