# Cldr for Units
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_units)
![Deps Status](https://beta.hexfaktor.org/badge/all/github/kipcole9/cldr_units.svg)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_units.svg?style=flat)](https://hex.pm/packages/ex_cldr_units)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/kipcole9/cldr_units/blob/master/LICENSE)

## Getting Started

`ex_cldr_units` is an add-on library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for units such as weights, lengths, areas, volumes and so on. It also provides unit conversion and simple arithmetic for compatible units.

### Configuration

From [ex_cldr](https://hex.pm/packages/ex_cldr) version 2.0, a backend module must be defined into which the public API and the [CLDR](https://cldr.unicode.org) data is compiled.  See the [ex_cldr documentation](https://hexdocs.pm/ex_cldr/readme.html) for further information on configuration.

In the following examples we assume the presence of a module called `MyApp.Cldr` defined as:
```elixir
defmodule MyApp.Cldr do
  use Cldr, locales: ["en", "fr"], default_locale: "en"
end
```

### Pub lic API

The primary api is defined by three functions:

* `MyApp.Cldr.Unit.to_string/2` for formatting units

* `MyApp.Cldr.Unit.new/2` to create a new `Unit.t` struct that encapsulated a unit and a value that can be used for arithmetic, comparison and conversion

* `MyApp.Cldr.Unit.convert/2` to convert one compatible unit to another

* `MyApp.Cldr.Unit.add/2`, `MyApp.Cldr.Unit.sub/2`, `MyApp.Cldr.Unit.mult/2`, `MyApp.Cldr.Unit.div/2` provide basic arithmetic operations on compatible `Unit.t` structs.

### Unit formatting and localization

`MyApp.Cldr.Unit.to_string/2` provides localized unit formatting. It supports two arguments:

  * `number` is any number (integer, float or Decimal) or a `Unit.t` struct returned by `Cldr.Unit.new/2`

  * `options` are:

    *  `unit` is any unit returned by `Cldr.Unit.units/0`.  This option is required unless a `Unit.t` is passed as the first argument.

    * `locale` is any configured locale. See `Cldr.known_locales()`. The default
      is `locale: Cldr.get_current_locale()`

    * `style` is one of those returned by `Cldr.Unit.available_styles`.
      The current styles are `:long`, `:short` and `:narrow`.  The default is `style: :long`

    * Any other options are passed to `Cldr.Number.to_string/2` which is used to format the `number`

```elixir
iex> MyApp.Cldr.Unit.to_string 123, unit: :gallon
{:ok, "123 gallons"}

iex> MyApp.Cldr.Unit.to_string 1234, unit: :gallon, format: :long
{:ok, "1 thousand gallons"}

iex> MyApp.Cldr.Unit.to_string 1234, unit: :gallon, format: :short
{:ok, "1K gallons"}

iex> MyApp.Cldr.Unit.to_string 1234, unit: :megahertz
{:ok, "1,234 megahertz"}

iex> MyApp.Cldr.Unit.to_string 1234, unit: :foot, locale: "fr"
{:ok, "1 234 pieds"}

iex> MyApp.Cldr.Unit.to_string Cldr.Unit.new(:ampere, 42), locale: "fr"
{:ok, "42 ampères"}

```

### Converting Units

`Unit.t` structs can be converted to other compatible units.  For example, `feet` can be converted to `meters` since they are both the `length` unit type.

```elixir
# Test for unit compatibility
iex> MyApp.Cldr.Unit.compatible? :foot, :meter
true
iex> MyApp.Cldr.Unit.compatible? :foot, :liter
false

# Convert a unit
iex> MyApp.Cldr.Unit.convert MyApp.Cldr.Unit.new(:foot, 3), :meter
#Unit<:meter, 0.9144111192392099>

# What units are compatible?
iex> MyApp.Cldr.Unit.compatible_units :foot
[:astronomical_unit, :centimeter, :decimeter, :fathom, :foot, :furlong, :inch,
 :kilometer, :light_year, :meter, :micrometer, :mile, :mile_scandinavian,
 :millimeter, :nanometer, :nautical_mile, :parsec, :picometer, :point, :yard]
```

### Unit arithmetic

Basic arithmetic is provided by `Cldr.Unit.add/2`, `Cldr.Unit.sub/2`, `Cldr.Unit.mult/2`, `Cldr.Unit.div/2` as well as `Cldr.Unit.round/3`

```elixir
iex> MyApp.Cldr.Unit.Math.add MyApp.Cldr.Unit.new!(:foot, 1), MyApp.Cldr.Unit.new!(:foot, 1)
#Unit<:foot, 2>

iex> MyApp.Cldr.Unit.Math.add MyApp.Cldr.Unit.new!(:foot, 1), MyApp.Cldr.Unit.new!(:mile, 1)
#Unit<:foot, 5280.945925937846>

iex> MyApp.Cldr.Unit.Math.add MyApp.Cldr.Unit.new!(:foot, 1), MyApp.Cldr.Unit.new!(:gallon, 1)
{:error, {Cldr.Unit.IncompatibleUnitError,
  "Operations can only be performed between units of the same type. Received #Unit<:foot, 1> and #Unit<:gallon, 1>"}}

iex> MyApp.Cldr.Unit.round MyApp.Cldr.Unit.new(:yard, 1031.61), 1
#Unit<:yard, 1031.6>

iex> MyApp.Cldr.Unit.round MyApp.Cldr.Unit.new(:yard, 1031.61), 1, :up
#Unit<:yard, 1031.7>

```

### Available units

Available units are returned by `MyApp.Cldr.Unit.units/0`.

```elixir
iex> MyApp.Cldr.Unit.units
[:acre, :acre_foot, :ampere, :arc_minute, :arc_second, :astronomical_unit, :bit,
 :bushel, :byte, :calorie, :carat, :celsius, :centiliter, :centimeter, :century,
 :cubic_centimeter, :cubic_foot, :cubic_inch, :cubic_kilometer, :cubic_meter,
 :cubic_mile, :cubic_yard, :cup, :cup_metric, :day, :deciliter, :decimeter,
 :degree, :fahrenheit, :fathom, :fluid_ounce, :foodcalorie, :foot, :furlong,
 :g_force, :gallon, :gallon_imperial, :generic, :gigabit, :gigabyte, :gigahertz,
 :gigawatt, :gram, :hectare, :hectoliter, :hectopascal, :hertz, :horsepower,
 :hour, :inch, ...]
```

### Unit types

Units are grouped by unit type which defines the convertibility of different types.  In general, units of the same time are convertible to each other. The function `MyApp.Cldr.Unit.unit_types/0` returns the unit types.  `MyApp.Cldr.Unit.unit_tree/0` returns the map of all unit types and their child units.

```elixir
iex> MyApp.Cldr.Unit.unit_types
[:acceleration, :angle, :area, :concentr, :consumption, :coordinate, :digital,
 :duration, :electric, :energy, :frequency, :length, :light, :mass, :power,
 :pressure, :speed, :temperature, :volume]
```

### Further information
For help in `iex`:

```elixir
iex> h MyApp.Cldr.Unit.new
iex> h MyApp.Cldr.Unit.to_string
iex> h MyApp.Cldr.Unit.convert
iex> h MyApp.Cldr.Unit.units
iex> h MyApp.Cldr.Unit.unit_types
```

## Installation

Note that `:ex_cldr_units` requires Elixir 1.5 or later.

Add `ex_cldr_units` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_units, "~> 2.0"}
      ]
    end

then retrieve `ex_cldr_units` from [hex](https://hex.pm/packages/ex_cldr_units):

    mix deps.get
    mix deps.compile
