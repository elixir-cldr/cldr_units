# Cldr for Units
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_units)
![Deps Status](https://beta.hexfaktor.org/badge/all/github/kipcole9/cldr_units.svg)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_units.svg?style=flat)](https://hex.pm/packages/ex_cldr_units)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/kipcole9/cldr_units/blob/master/LICENSE)

## Introduction and Getting Started

`ex_cldr_units` is an addon library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for units such as weights, lengths, areas, volumes and so on.

The primary api is `Cldr.Unit.to_string/2`.  The following examples demonstrate:

```elixir
iex> Cldr.Unit.to_string 123, :gallon
{:ok, "123 gallons"}

iex> Cldr.Unit.to_string 1234, :gallon, format: :long
{:ok, "1 thousand gallons"}

iex> Cldr.Unit.to_string 1234, :gallon, format: :short
{:ok, "1K gallons"}

iex> Cldr.Unit.to_string 1234, :megahertz
{:ok, "1,234 megahertz"}
```

Available units can be retrieved by `Cldr.Unit.available_units/2`:

```elixir
iex> Cldr.Unit.available_units
[:acre, :acre_foot, :ampere, :arc_minute, :arc_second, :astronomical_unit, :bit,
 :bushel, :byte, :calorie, :carat, :celsius, :centiliter, :centimeter, :century,
 :cubic_centimeter, :cubic_foot, :cubic_inch, :cubic_kilometer, :cubic_meter,
 :cubic_mile, :cubic_yard, :cup, :cup_metric, :day, :deciliter, :decimeter,
 :degree, :fahrenheit, :fathom, :fluid_ounce, :foodcalorie, :foot, :furlong,
 :g_force, :gallon, :gallon_imperial, :generic, :gigabit, :gigabyte, :gigahertz,
 :gigawatt, :gram, :hectare, :hectoliter, :hectopascal, :hertz, :horsepower,
 :hour, :inch, ...]
```

Known unit types cab be retrieved by `Cldr.Unit.available_unit_types/2`:

```elixir
iex> Cldr.Unit.available_unit_types
[:acceleration, :angle, :area, :concentr, :consumption, :coordinate, :digital,
 :duration, :electric, :energy, :frequency, :length, :light, :mass, :power,
 :pressure, :speed, :temperature, :volume]
```

For help in `iex`:

```elixir
iex> h Cldr.Unit.to_string
iex> h Cldr.Unit.available_units
iex> h Cldr.Unit.available_unit_types
```

## Documentation

Primary documentation is available as part of the [hex documentation for ex_cldr](https://hexdocs.pm/ex_cldr/6_units_formats.html)

## Installation

Note that `:ex_cldr_units` requires Elixir 1.5 or later.

Add `ex_cldr_units` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_units, "~> 0.3.1"}
      ]
    end

then retrieve `ex_cldr_units` from [hex](https://hex.pm/packages/ex_cldr_units):

    mix deps.get
    mix deps.compile

