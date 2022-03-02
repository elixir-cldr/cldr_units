# Cldr for Units
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_units)
[![Hex.pm](https://img.shields.io/hexpm/v/ex_cldr_units.svg)](https://hex.pm/packages/ex_cldr_units)
[![Hex.pm](https://img.shields.io/hexpm/dw/ex_cldr_units.svg?)](https://hex.pm/packages/ex_cldr_units)
[![Hex.pm](https://img.shields.io/hexpm/l/ex_cldr_units.svg)](https://hex.pm/packages/ex_cldr_units)

## Installation

Note that `:ex_cldr_units` requires Elixir 1.6 or later.

Add `ex_cldr_units` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_units, "~> 3.0"}
      ]
    end

then retrieve `ex_cldr_units` from [hex](https://hex.pm/packages/ex_cldr_units):

    mix deps.get
    mix deps.compile

## Getting Started

`ex_cldr_units` is an add-on library for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for units such as weights, lengths, areas, volumes and so on. It also provides unit conversion and simple arithmetic for compatible units.

### Configuration

From [ex_cldr](https://hex.pm/packages/ex_cldr) version 2.0, a backend module must be defined into which the public API and the [CLDR](https://cldr.unicode.org) data is compiled.  See the [ex_cldr documentation](https://hexdocs.pm/ex_cldr/readme.html) for further information on configuration.

In the following examples we assume the presence of a module called `MyApp.Cldr` defined as:
```elixir
defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]
end
```

### Supporting the String.Chars protocol

The `String.Chars` protocol underpins `Kernel.to_string/1` and is also used in string interpolation such as `#{my_unit}`.  In order for this to be supported by `Cldr.Unit`, a default backend module must be configured in `config.exs`.  For example:
```
config :ex_cldr_units,
  default_backend: MyApp.Cldr
```

## Public API

The primary api is defined by three functions:

* `MyApp.Cldr.Unit.to_string/2` for formatting units

* `MyApp.Cldr.Unit.new/2` to create a new `Unit.t` struct that encapsulated a unit and a value that can be used for arithmetic, comparison and conversion

* `MyApp.Cldr.Unit.convert/2` to convert one compatible unit to another

* `MyApp.Cldr.Unit.localize/3` to localize a unit by converting it to units customary for a given territory

* `MyApp.Cldr.Unit.add/2`, `MyApp.Cldr.Unit.sub/2`, `MyApp.Cldr.Unit.mult/2`, `MyApp.Cldr.Unit.div/2` provide basic arithmetic operations on compatible `Unit.t` structs.

### Creating a new unit

A `Cldr.Unit.t()` struct is created with the `Cldr.Unit.new/2` function. The two parameters are a unit name and a number (expressed as a `float`, `integer`, `Decimal` or `Ratio`) in either order.

Naming units is quite flexible combining:

* One or more base unit names. These are the names returned from `Cldr.Unit.known_units/0`

* An optional SI prefix (from `yokto` to `yotta`)

* An optional power prefix of `square` or `cubic`

Names can be expressed as strings with any of `-`, `_` or ` ` as separators between words.

Some examples:

```elixir
iex> Cldr.Unit.new :meter, 1
{:ok, #Cldr.Unit<:meter, 1>}

iex> Cldr.Unit.new "square meter", 1
{:ok, #Cldr.Unit<:square_meter, 1>}

iex> Cldr.Unit.new "square liter", 1
{:ok, #Cldr.Unit<"square_liter", 1>}

iex> Cldr.Unit.new "square yottaliter", 1
{:ok, #Cldr.Unit<"square_yottaliter", 1>}

iex> Cldr.Unit.new "cubic light year", 1
{:ok, #Cldr.Unit<"cubic_light_year", 1>}

iex> Cldr.Unit.new "squre meter", 1
{:error,
 {Cldr.UnknownUnitError, "Unknown unit was detected at \"squre_meter\""}}
```

You will note that the unit make not make logical sense (`cubic light-year`?) but they do make mathematical sense.

Units can also be described as the product of one or more base units. For example:

```elixir
iex> Cldr.Unit.new "liter ampere", 1
{:ok, #Cldr.Unit<"ampere_liter", 1>}

iex> Cldr.Unit.new "mile lux", 1
{:ok, #Cldr.Unit<"mile_lux", 1>}
```

Again, this may not have a logical meaning but they do have an arithmetic meaning and they can be formatted as strings:

```elixir
iex> Cldr.Unit.new!("liter ampere", 1) |> Cldr.Unit.to_string
{:ok, "1 ampere⋅litre"}

iex> Cldr.Unit.new!("mile lux", 3) |> Cldr.Unit.to_string
{:ok, "3 miles⋅lux"}
```

Lastly, there are units formed by division where are called "per" units. For example:

```elixir
iex> Cldr.Unit.new "mile per hour", 1
{:ok, #Cldr.Unit<:mile_per_hour, 1>}

iex> Cldr.Unit.new "liter per second", 1
{:ok, #Cldr.Unit<"liter_per_second", 1>}

iex> Cldr.Unit.new "cubic gigalux per inch", 1
{:ok, #Cldr.Unit<"cubic_gigalux_per_inch", 1>}
```

### Unit formatting and localization

`MyApp.Cldr.Unit.to_string/2` provides localized unit formatting. It supports two arguments:

  * `number` is any number (integer, float or Decimal) or a `Unit.t` struct returned by `Cldr.Unit.new/2`

  * `options` which are:

    * `:unit` is any unit returned by `Cldr.Unit.known_units/0`.  This option is required unless a `Unit.t` is passed as the first argument.

    * `:locale` is any configured locale. See `Cldr.known_locale_names/0`. The default
      is `locale: Cldr.get_current_locale()`

    * `:style` is one of those returned by `Cldr.Unit.available_styles`.
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

iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: "foot_per_second", style: :narrow, per: :second
{:ok, "1,234′/s"}

iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: "foot_per_second"
{:ok, "1,234 feet per second"}

```
### Unit decomposition

Sometimes its a requirement to decompose a unit into one or more subunits.  For example, if someone is 6.3 feet height we would normally say "6 feet, 4 inches".  This can be achieved with `Cldr.Unit.decompose/2`. Using our example:

```elixir
iex> height = Cldr.Unit.new(:foot, 6.3)
#Cldr.Unit<:foot, 6.3>
iex(2)> Cldr.Unit.decompose height, [:foot, :inch]
[#Cldr.Unit<:foot, 6.0>, #Cldr.Unit<:inch, 4.0>]
```

A localised string representing this decomposition can also be produced.  `Cldr.Unit.to_string/3` will process a unit list, using the function `Cldr.List.to_string/2` to perform the list combination.  Again using the example:

```elixir
iex> c = Cldr.Unit.decompose height, [:foot, :inch]
[#Cldr.Unit<:foot, 6.0>, #Cldr.Unit<:inch, 4.0>]

iex> Cldr.Unit.to_string c, MyApp.Cldr
"6 feet and 4 inches"

iex> Cldr.Unit.to_string c, MyApp.Cldr, list_options: [format: :unit_short]
"6 feet, 4 inches"
# And of course full localisation is supported
iex> Cldr.Unit.to_string c, MyApp.Cldr, locale: "fr"
"6 pieds et 4 pouces"
```

### Converting Units

`t:Unit` structs can be converted to other compatible units.  For example, `feet` can be converted to `meters` since they are both of the `length` unit type.

```elixir
# Test for unit compatibility
iex> Cldr.Unit.compatible? :foot, :meter
true
iex> Cldr.Unit.compatible? :foot, :liter
false

# Convert a unit
iex> Cldr.Unit.convert Cldr.Unit.new!(:foot, 3), :meter
{:ok, #Cldr.Unit<:meter, 16472365997070327 <|> 18014398509481984>}

```

### Localising units for a given locale or territory

Different locales or territories use different measurement systems and sometimes different measurement scales that also vary based upon usage. For example, in the US a person's height is considered in `inches` up to a certain point and `feet and inches` after that. For distances when driving, the length is considered in `yards` for certain distances and `miles` after that. For most other countries the same quantity would be expressed in `centimeters` or `meters` or `kilometers`.

`ex_cldr_units` makes it easy to take a unit and convert it to the units appropriate for a given locale and usage.

Consider this example:

```elixir
iex> height = Cldr.Unit.new!(1.81, :meter)
#Cldr.Unit<:meter, 1.81>

iex> us_height = Cldr.Unit.localize height, usage: :person_height, territory: :US
[#Cldr.Unit<:foot, 5>,
 #Cldr.Unit<:inch, 1545635392113553812 <|> 137269716642252725>]

iex> Cldr.Unit.to_string us_height
{:ok, "5 feet and 11.26 inches"}
```

Note that conversion is dependent on context. The context above is `:person_height` reflecting that we are referring to the height of a person. For units of `length` category, the other contexts available are `:rainfall`, `:snowfall`, `:vehicle`, `:visibility` and `:road`. Using the above example with the context of `:rainfall` we see

```elixir
iex> length = Cldr.Unit.localize height, usage: :rainfall, territory: :US
[#Cldr.Unit<:inch, 9781818390648717312 <|> 137269716642252725>]

iex> Cldr.Unit.to_string length
{:ok, "71.26 inches"}
```

See `Cldr.Unit.preferred_units/3` to see what mappings are available, in particular what context usage is supported for conversion.

### Unit arithmetic

Basic arithmetic is provided by `Cldr.Unit.add/2`, `Cldr.Unit.sub/2`, `Cldr.Unit.mult/2`, `Cldr.Unit.div/2` as well as `Cldr.Unit.round/3`

```elixir
iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:foot, 1)
#Cldr.Unit<:foot, 2>

iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:mile, 1)
#Cldr.Unit<:foot, 5280.945925937846>

iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:gallon, 1)
{:error, {Cldr.Unit.IncompatibleUnitError,
 "Operations can only be performed between units of the same type. Received #Cldr.Unit<:foot, 1> and #Cldr.Unit<:gallon, 1>"}}

iex> Cldr.Unit.round Cldr.Unit.new(:yard, 1031.61), 1
#Cldr.Unit<:yard, 1031.6>

iex> Cldr.Unit.round Cldr.Unit.new(:yard, 1031.61), 1, :up
#Cldr.Unit<:yard, 1031.7>

```

### Available units

Available units are returned by `Cldr.Unit.known_units/0`.

```elixir
iex> Cldr.Unit.known_units
[:acre, :acre_foot, :ampere, :arc_minute, :arc_second, :astronomical_unit, :bit,
 :bushel, :byte, :calorie, :carat, :celsius, :centiliter, :centimeter, :century,
 :cubic_centimeter, :cubic_foot, :cubic_inch, :cubic_kilometer, :cubic_meter,
 :cubic_mile, :cubic_yard, :cup, :cup_metric, :day, :deciliter, :decimeter,
 :degree, :fahrenheit, :fathom, :fluid_ounce, :foodcalorie, :foot, :furlong,
 :g_force, :gallon, :gallon_imperial, :generic, :gigabit, :gigabyte, :gigahertz,
 :gigawatt, :gram, :hectare, :hectoliter, :hectopascal, :hertz, :horsepower,
 :hour, :inch, ...]
```

### Unit categories

Units are grouped by unit category which defines the convertibility of different types.  In general, units of the same category are convertible to each other. The function `Cldr.Unit.known_unit_categories/0` returns the unit categories.

```elixir
iex> Cldr.Unit.known_unit_categories
[:acceleration, :angle, :area, :concentr, :consumption, :coordinate, :digital,
 :duration, :electric, :energy, :frequency, :length, :light, :mass, :power,
 :pressure, :speed, :temperature, :volume]
```

See also `Cldr.Unit.known_units_by_category/0` and `Cldr.Unit.known_units_for_category/1`.

### Measurement systems

Units generally fall into one of three measurement systems in use around the world. In CLDR these are known as `:metric`, `:ussystem` and `:uksystem`. The following functions allow identifying measurement systems for units, territories and locales.

* The measurement systems are returned with `Cldr.Unit.known_measurement_systems/0`.

* The measurement systems for a given unit are returned by `Cldr.Unit.measurement_systems_for_unit/1`.

* A boolean indicating membership in a given measurement system is returned by `Cldr.Unit.measurement_system?/2`.

* All units belonging to a measurement system are returned by `Cldr.Unit.measurement_system_units/1`.

* The measurement system in use for a given territory is returned by `Cldr.Unit.measurement_system_for_territory/1`.

* The measurement system in use for a given locale is returned by `Cldr.Unit.measurement_system_from_locale/1`.

#### Localisation with measurement systems

Knowledge of the measurement system in place for a given user helps create a better user experience. For example, a user who prefers units of measure in the US system can be shown different but compatible units from a user who prefers metric units.

In this example, the list of units in the volume category are filtered based upon the users preference as expressed by their locale.
```elixir
# For a user preferring US english
iex> system = Cldr.Unit.measurement_system_from_locale "en"
:ussystem

iex> {:ok, units} = Cldr.Unit.known_units_for_category(:volume)
iex> Enum.filter(units, &Cldr.Unit.measurement_system?(&1, system))
[:dessert_spoon, :cup, :drop, :dram, :cubic_foot, :teaspoon, :tablespoon,
 :cubic_inch, :bushel, :quart, :pint, :cubic_yard, :cubic_mile, :fluid_ounce,
 :pinch, :barrel, :jigger, :gallon, :acre_foot]

# For a user preferring australian english
iex> system = Cldr.Unit.measurement_system_from_locale "en-AU"
:metric

iex> Enum.filter(units, &Cldr.Unit.measurement_system?(&1, system))
[:cubic_centimeter, :centiliter, :cubic_meter, :pint_metric, :megaliter,
 :cubic_kilometer, :hectoliter, :milliliter, :deciliter, :liter, :cup_metric]

# For a user expressing an explicit measurement system
iex> system = Cldr.Unit.measurement_system_from_locale "en-AU-u-ms-uksystem"
:uksystem

iex> Enum.filter(units, &Cldr.Unit.measurement_system?(&1, system))
[:quart_imperial, :cubic_foot, :cubic_inch, :dessert_spoon_imperial,
 :cubic_yard, :cubic_mile, :fluid_ounce_imperial, :acre_foot, :gallon_imperial]
```

## Additional units (custom units)

Additional domain-specific  units can be defined to suit application requirements. In the context
of `ex_cldr` there are two parts to configuring additional units.

1. Configure the unit, base unit and conversion in `config.exs`. This is a requirement since units are compiled into code.

2. Configure the localizations for the additional unit in a CLDR backend module. Once configured, additional units act and behave like any of the predefined units of measure defined by CLDR.

### Configuring a unit in config.exs

Under the application  `:ex_cldr_units`, define a key `:additional_units` with the required unit
definitions.

For  example:
```elixir
config :ex_cldr_units,  :additional_units,
  vehicle: [base_unit: :unit, factor: 1,  offset: 0, sort_before: :all],
  person: [base_unit: :unit, factor:  1, offset: 0, sort_before: :all]
```
This example defines  two additional units: `:vehicle` and  `:person`.

* The keys `:base_unit`, and  `:factor` are required. The  key `:offset` is optional and  defaults to `0`.

* The key `:sort_before` is optional and defaults to `:none`.

### Configuration keys

* `:base_unit` is the common denominator that is used to support conversion between like units. It can be any atom value. For example `:liter` is the base unit for volume units, `:meter` is the base unit for length units.

*  `:factor` is used to convert a unit to its base unit in order to support conversion. When converting a unit to another compatible unit, the unit is first  multiplied by this units factor then divided by the target units factor.

* `:offset` is added to a unit after applying its base factor in order to convert to another unit.

* `:sort_before` determines where in this *base unit* sorts relative to other base units. Typically this is set to `:all` in which  case this base unit sorts before all other base units or`:none` in which case this base unit sorted after all other base units. The default is `:none`. If in doubt, leave this key to its default.

*  `:systems` is list of measurement systems to which this unit belongs. The known measurement systems are `:metric`, `:uksystem` and `:ussystem`.  The  default is `[:metric,  :ussystem, :uksystem]`.

### Defining localizations

Although defining a unit in `config.exs` is enough to create, operate on and serialize an additional unit, it cannot be localised without defining localizations in an `ex_cldr` backend module.  For example:

```elixir
defmodule MyApp.Cldr do
  # Note that this line should come before the `use Cldr` line
  use Cldr.Unit.Additional

  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]

  unit_localization(:person, "en", :long,
    one: "{0} person",
    other: "{0} people",
    display_name: "people"
  )

  unit_localization(:person, "en", :short,
    one: "{0} per",
    other: "{0} pers",
    display_name: "people"
  )

  unit_localization(:person, "en", :narrow,
    one: "{0} p",
    other: "{0} p",
    display_name: "p"
  )
end
```

Note the additions to a typical `ex_cldr` backend module:

* `use Cldr.Unit.Additional` is required to define additional units

* use of the `Cldr.Unit.Additional.unit_localization/4` macro in order to define a localization.

* The use templates for the localization. Templates are a string with both a placeholder (for units it is always `{0}`) and some fixed text that reflects the grammatical requirements of the particular locale.

One invocation of `Cldr.Unit.Additional.unit_localization/4` should made for each combination of unit, locale and style.

#### Parameters to unit_localization/4

* `unit` is the name of the additional unit as an `atom`.

* `locale` is the locale name for this localization. It should be one of the locale configured in this backend although this cannot currently be confirmed at compile time.

* `style` is one of `:long`, `:short`, or `:narrow`.

* `localizations` is a keyword like of localization strings. Two keys - `:display_name` and `:other` are mandatory. They represent the localizations for a non-count display name and `:other` is the localization for a unit when no other pluralization is defined.

#### Localisation definition

Localization keyword list defines localizations that match the plural rules for a given locale. Plural rules for a given number in a given locale resolve to one of
six keys:

* `:zero`
* `:one` (singular)
* `:two` (dual)
* `:few` (paucal)
* `:many` (also used for fractions if they have a separate class)
* `:other` (required — general plural form. Also used if the language only has a single form)

Only the `:other` key is required. For english, providing keys for `:one` and `:other` is enough. Other languages have different grammatical requirements.

The key `:display_name` is used by the function `Cldr.Unit.display_name/1` which is primarily used to support UI applications.

### Sorting Units

From Elixir 1.10, `Enum.sort/2` supports module-based comparisons to provide a simpler API for sorting structs. `ex_cldr_units` supports Elixir 1.10 as the following example shows:
```elixir
iex> alias Cldr.Unit
Cldr.Unit

iex> unit_list = [Unit.new!(:millimeter, 100), Unit.new!(:centimeter, 100), Unit.new!(:meter, 100), Unit.new!(:kilometer, 100)]
[#Unit<:millimeter, 100>, #Unit<:centimeter, 100>, #Unit<:meter, 100>,
 #Unit<:kilometer, 100>]

iex> Enum.sort unit_list, Cldr.Unit
[#Unit<:millimeter, 100>, #Unit<:centimeter, 100>, #Unit<:meter, 100>,
 #Unit<:kilometer, 100>]

iex> Enum.sort unit_list, {:desc, Cldr.Unit}
[#Unit<:kilometer, 100>, #Unit<:meter, 100>, #Unit<:centimeter, 100>,
 #Unit<:millimeter, 100>]

iex> Enum.sort unit_list, {:asc, Cldr.Unit}
[#Unit<:millimeter, 100>, #Unit<:centimeter, 100>, #Unit<:meter, 100>,
 #Unit<:kilometer, 100>]
```

Note that the items being sorted must be all of the same unit category (length, volume, ...). Where units are of the same category but different units, conversion to a common unit will occur before the comparison. If units of different categories are encountered an exception will be raised as the following example shows:
```elixir
iex> unit_list = [Unit.new!(:millimeter, 100), Unit.new!(:centimeter, 100), Unit.new!(:meter, 100), Unit.new!(:liter, 100)]
[#Cldr.Unit<:millimeter, 100>, #Cldr.Unit<:centimeter, 100>,
 #Cldr.Unit<:meter, 100>, #Cldr.Unit<:liter, 100>]

iex> Enum.sort unit_list, Cldr.Unit
** (Cldr.Unit.IncompatibleUnitsError) Operations can only be performed between units with the same category and base unit. Received :liter and :meter
```

### Serializing to a database with Ecto

The companion package [ex_cldr_units_sql](https://hex.pm/packages/ex_cldr_units_sql) provides functions for the serialization of `Unit` data.  See the [README](https://hexdocs.pm/ex_cldr_units_sql/readme.html) for further information.
