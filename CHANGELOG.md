# Changelog

## Cldr_Units v3.15.0

This is the changelog for Cldr_units v3.15.0 released on October 24th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Updates to [CLDR 42](https://cldr.unicode.org/index/downloads/cldr-42).

## Cldr_Units v3.14.0

This is the changelog for Cldr_units v3.14.0 released on October 8th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.parse_unit_name/2` to parse a string as unit name. Also adds `MyApp.Cldr.parse_unit_name/2` as well as the `!` versions of these functions.  Thanks to @Awlexus for the PR. Closes #31.

## Cldr_Units v3.13.3

This is the changelog for Cldr_units v3.13.3 released on August 3rd, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix unit comparison for unit values built from decimal strings. Thanks to @seantanly for the report. Closes #29.

## Cldr_Units v3.13.2

This is the changelog for Cldr_units v3.13.2 released on June 7th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `MyApp.Cldr.Unit.localize/2` which was previously delegating incorrectly to `Cldr.Unit`.

## Cldr_Units v3.13.1

This is the changelog for Cldr_units v3.13.1 released on June 7th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `Cldr.Unit.Math.*` to respect unit `:usage` of the input parameters

* Fix `Cldr.Math.localize/2` to respect unit `:usage` of the options parameter if provided

## Cldr_Units v3.13.0

This is the changelog for Cldr_units v3.13.0 released on April 6th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Update [CLDR](https://cldr.unicode.org) to [release 41](https://cldr.unicode.org/index/downloads/cldr-41) in [ex_cldr version 2.28.0](https://hex.pm/packages/ex_cldr/2.28.0) and [ex_cldr_numbers 2.26.0](https://hex.pm/packages/ex_cldr_numbers/2.26.0).

## Cldr_Units v3.12.2

This is the changelog for Cldr_units v3.12.2 released on February 27th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fixes conversions where the base units don't match (string match) but the units are of the same unit category and therefore are convertible. Thanks to @narrowtux for the report. Fixes #27.

## Cldr_Units v3.12.1

This is the changelog for Cldr_units v3.12.1 released on February 23rd, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Remove compilation warning for `Phoenix.HTML.Safe` that was emitted since the `:phoenix_html` library is not a dependency. Thanks for @maennchen for the report. Fixes #26.

## Cldr_Units v3.12.0

This is the changelog for Cldr_units v3.12.0 released on February 21st, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `Cldr.Unit.measurement_system_from_locale/2` to allow the second parameter to be either a backend or a measurement system key.

### Enhancements

* Add `Cldr.Unit.from_map/1` to create a unit from a map. This can be used to consume the results of serializing a unit to JSON. The input parameter is designed to mirror the output of the custom Jason encoder.

* Updates to [ex_cldr version 2.26.0](https://hex.pm/packages/ex_cldr/2.26.0) and [ex_cldr_numbers version 2.25.0](https://hex.pm/packages/ex_cldr_numbers/2.25.0) which use atoms for locale names and rbnf locale names. This is consistent with other elements of `t:Cldr.LanguageTag` where atoms are used when the cardinality of the data is fixed and relatively small and strings where the data is free format.

## Cldr_Units v3.11.0

This is the changelog for Cldr_units v3.11.0 released on January 6th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix canonical base unit calculation when the unit is a `per per` form like `candela per lux`.

### Enhancements

* Add unit filters for `Cldr.Unit.parse/2`.  This means that the options `:only` and `:except` can comprise both unit categories and unit names as part of the filter.

## Cldr_Units v3.10.0

This is the changelog for Cldr_units v3.10.0 released on December 27th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Further refinement to `Cldr.Unit.unit_category/1` to return a result in a broader range of cases.

### Enhancements

* Adds `:only` and `:except` options to `Cldr.Unit.parse/2`. These options provide a mechanism to disambiguate the unit when a unit string could refer to more than one unit. For example, "2w" could refer to either "2 weeks" or "2 watts". If neither option is provided then the result is the same as in prior releases: the unit with the lexically shorter and alphabetically earlier unit is returned.

## Cldr_Units v3.9.2

This is the changelog for Cldr_units v3.9.2 released on December 26th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `Cldr.Unit.unit_category/1`. Thanks to @DaTrader for the report. Closes #24.

## Cldr_Units v3.9.1

This is the changelog for Cldr_units v3.9.1 released on November 15th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Support parsing units with multiple "per" clauses like "gallon per feet per second".

* Fix canonical unit name for currency units. This also fixes unit math with currency units.

* Add `display_name/2` to backend modules.

## Cldr_Units v3.9.0

This is the changelog for Cldr_units v3.9.0 released on November 14th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Use `import Config` not deprecated `use Mix.Config` in config files. Only significant for developers of `ex_cldr_units`.

* Make `decimal` a required dependency, not optional, since various pattern matches expect its presence.

### Enhancements

* Add support for currency-based units.  This allows for calculations and formatting of units such as "$2 per gallon". For this example, the unit would be created with `Cldr.Unit.new(2, "curr-usd-per-gallon")`. The inverse is also possible, for example:

```elixir
iex> MyApp.Cldr.Unit.to_string(Cldr.Unit.new!(2, "curr-usd-per-gallon"))
{:ok, "$2.00 per gallon"}

iex> MyApp.Cldr.Unit.to_string(Cldr.Unit.new!(2, "gallon-per-curr-usd"))
{:ok, "2 gallons per US dollar"}
```

* Add support for binary factor prefixed units. These units are factors of 1024 and include "kibi", "mebi", "gibi", "tebi", "pebi", "exbi", "zebi" and "yobi". For example:

```elixir
iex> MyApp.Cldr.Unit.to_string Cldr.Unit.new!(3, :gibibyte)
{:ok, "3 gibibytes"}
```

* Add support for integer prefixes for units. This is useful for units like "liters per 100 kilometers" or "25 calories per 100 grams".  For example:

```elixir
iex> MyApp.Cldr.Unit.to_string Cldr.Unit.new!(25, "calorie_per_100-gram")
{:ok, "25 calories per 100 grams"}
```

## Cldr_Units v3.8.0

This is the changelog for Cldr_units v3.8.0 released on October 27th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Updates to use [CLDR 40](https://cldr.unicode.org/index/downloads/cldr-40) data. The release notes say:

> In CLDR v40, the focus is on Grammatical features (gender and case) for units of measurement in additional locales. In many languages, forming grammatical phrases requires dealing with grammatical gender and case. Without that, it can sound as bad as "on top of 3 hours" instead of "in 3 hours":

  * Phase 1 (CLDR v39) of grammatical features included just 12 locales (da, de, es, fr, hi, it, nl, no, pl, pt, ru, sv).

  * Phase 2 (CLDR v40, this release) has expanded the number of locales by 29 (am, ar, bn, ca, cs, el, fi, gu, he, hr, hu, hy, is, kn, lt, lv, ml, mr, nb, pa, ro, si, sk, sl, sr, ta, te, uk, ur), but for a more restricted number of units.

### Deprecations

* Don't call deprecated `Cldr.Config.get_locale/2`, use `Cldr.Locale.Loader.get_config/2` instead.

* Don't call deprecated `Cldr.Config.known_locale_names/1`, call `Cldr.Locale.Loader.known_locale_names/1` instead.

## Cldr_Units v3.8.0-rc.2

This is the changelog for Cldr_units v3.8.0-rc.2 released on October 25th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Deprecations

* Don't call deprecated `Cldr.Config.known_locale_names/1`, call `Cldr.Locale.Loader.known_locale_names/1` instead.

## Cldr_Units v3.8.0-rc.1

This is the changelog for Cldr_units v3.8.0-rc.1 released on October 24th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Deprecations

* Don't call deprecated `Cldr.Config.get_locale/2`, use `Cldr.Locale.Loader.get_config/2` instead.

## Cldr_Units v3.8.0-rc.0

This is the changelog for Cldr_units v3.8.0-rc.0 released on October 3rd, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Updates to use [CLDR 40](https://cldr.unicode.org/index/downloads/cldr-40) data. The release notes say:

In CLDR v40, the focus is on Grammatical features (gender and case) for units of measurement in additional locales. In many languages, forming grammatical phrases requires dealing with grammatical gender and case. Without that, it can sound as bad as "on top of 3 hours" instead of "in 3 hours":

* Phase 1 (CLDR v39) of grammatical features included just 12 locales (da, de, es, fr, hi, it, nl, no, pl, pt, ru, sv).
* Phase 2 (CLDR v40, this release) has expanded the number of locales by 29 (am, ar, bn, ca, cs, el, fi, gu, he, hr, hu, hy, is, kn, lt, lv, ml, mr, nb, pa, ro, si, sk, sl, sr, ta, te, uk, ur), but for a more restricted number of units.

## Cldr_Units v3.7.1

This is the changelog for Cldr_units v3.7.1 released on August 20th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix doc errors. Thanks to @maennchen for the report. Doc errors in other `ex_cldr` packages are also updated.

## Cldr_Units v3.7.0

This is the changelog for Cldr_units v3.7.0 released on July 1st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Add support for the `Cldr.DisplayName` protocol for `t:Cldr.Unit` structs.

* Updated to [ex_cldr version 2.23.0](https://hex.pm/packages/ex_cldr/2.23.0) which changes the names of some of the fields in the "-u-" extension to match the CLDR canonical name. In particular the field name `measurement_system` changes to `ms`. Also the value of `ms` for the UK System will be `:imperial` not `:uksystem`.

## Cldr_Units v3.6.0

This is the changelog for Cldr_units v3.6.0 released on June 12th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.parse/2` to parse unit strings of the form `1kg` into a `t:Cldr.Unit` struct.

## Cldr_Units v3.5.3

This is the changelog for Cldr_units v3.5.3 released on May 20th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fixes formatting units when invoking `MyApp.Cldr.Unit.to_string/2` (ie on the backend module) and no default backend is configured. Thanks again to @maennchen. Closes #22.  Require at least [ex_cldr version 2.22.1](https://hex.pm/packages/ex_cldr/2.22.1)

## Cldr_Units v3.5.2

This is the changelog for Cldr_units v3.5.2 released on April 12th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix getting a unit pattern when the unit value is zero, one or two and there is no pattern for the default unit plural category. Thanks to @syfgkjasdkn for the report.  Closes #21.

## Cldr_Units v3.5.1

This is the changelog for Cldr_units v3.5.1 released on April 11th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Use `:other` plural category to format units which have a value of 0, 1 or 2 when the natural unit pattern has no substitutions. This corrects the situation in locales such as `he` and `ar` where the unit pattern for plural category `:one` has no substitutions. Previously this would means the formatted string for a unit with a value of `1` and `-1` would both output the same string.  Thanks to @jarrodmoldrich for the report and to @voltone for his family's help with hebrew grammar.

## Cldr_Units v3.5.0

This is the changelog for Cldr_units v3.5.0 released on April 8th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Overview

In this release the `Cldr.Unit.to_string/{1, 2, 3}` function has been rewritten and the concrete implementation is now in `Cldr.Unit.Format`.  The primary reasons for rewriting are:

1. Improves performance by 20% over the old implementation.
2. Supports grammatical case and grammatical gender. These allow for better sentence formation in a localised fashion. Only are few locales have the required data for now (for example, `fr` and `de`) however more locales will have data in upcoming CLDR releases.

Note that full testing of grammatical case and grammatical gender variations is not yet complete.

### Soft Deprecation

* The function `Cldr.Unit.to_iolist/{1, 2, 3}` is soft deprecated. It is still available and no deprecation warning is emitted. It will however be removed from the public API in a future release. This function is primarily used to support implementation of `Cldr.Unit.to_string/3`

* As of this release, argument checking in `Cldr.Unit.to_iolist/3` is less rigorous in order to avoid the relatively expensive argument normalization process happening twice (once in `Cldr.Unit.to_string/3` and then again in `Cldr.Unit.to_iolist/3`).

### Bug Fixes

* The new string formatter correctly assembles units with an SI prefix (ie `millimeter`) in languages such as German where the noun is capitalized.

* Fixes calculating the base unit when the unit is a complex compound unit.

* Remove double parsing when calling `Cldr.Unit.new/2` and the unit is not in `Cldr.Unit.known_units/0`

* Ensure `Cldr.Unit.unit_category/1` returns an error tuple if the category is unknown

### Enhancements

* Updated to require [ex_cldr version 2.20](https://hex.pm/packages/ex_cldr/2.20.0) which includes [CLDR 39](http://cldr.unicode.org/index/downloads/cldr-39) data.

* Add `Cldr.Unit.validate_grammatical_gender/2`

* Add `Cldr.Unit.known_grammatical_cases/0`

* Add `Cldr.Unit.known_grammatical_genders/0`

* Add `Cldr.Unit.known_measurement_system_names/0`

* Add `Cldr.Unit.invert/1` to invert a "per" unit. This allows for increased compatibility for conversions. For example, "liters per 100 kilometers" is a measure of consumption, as is "miles per gallon".  However these two units are not convertible without inverting one of them first since one is "volume per length" and the other is "length per volume".

* Add `Cldr.Unit.conversion_for/2` to return a conversion list used when converting one unit to another.

* Add `Cldr.Unit.grammatical_gender/2` to return the grammatical gender for a given unit and locale

* Add `Cldr.Unit.conversion_for/2` to return a conversion list used when converting one unit to another.

* Add support for grammatical cases for `Cldr.Unit.to_string/2` and `Cldr.Unit.to_iolist/2`. Not all locales support more than the nominative case. The nominative case is the default. Any configured "Additional Units" in a backend module will need to be modified to put the localisations a map with the key `:nominative`.  See the readme for more information on migrating additional units.  On example is:
```elixir
defmodule MyApp.Cldr do
  use Cldr.Unit.Additional

  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]

  unit_localization(:person, "en", :long,
    nominative: %{
      one: "{0} person",
      other: "{0} people"
    },
    display_name: "people"
  )
end
```

* Support conversions where one of the base units is the inverted conversion of the other. This allows conversion between, for example, `mile per gallon` and `liter per 100 kilometer`. These are both compound units of `length` and `volume` but are inverse representations from each other.

## Cldr_Units v3.5.0-rc.1

This is the changelog for Cldr_units v3.5.0-rc.1 released on March 21st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Overview

In this release the `Cldr.Unit.to_string/{1, 2, 3}` function has been rewritten and the concrete implementation is now in `Cldr.Unit.Format`.  The primary reasons for rewriting are:

1. Improves performance by 20% over the old implementation.
2. Supports grammatical case and grammatical gender. These allow for better sentence formation in a localised fashion. Only are few locales have the required data for now (for example, `fr` and `de`) however more locales will have data in upcoming CLDR releases.

Note that full testing of grammatical case and grammatical gender variations is not yet complete.

### Soft Deprecation

* The function `Cldr.Unit.to_iolist/{1, 2, 3}` is soft deprecated. It is still available and no deprecation warning is emitted. It will however be removed from the public API in a future release. This function is primarily used to support implementation of `Cldr.Unit.to_string/3`

* As of this release, argument checking in `Cldr.Unit.to_iolist/3` is less rigorous in order to avoid the relatively expensive argument normalization process happening twice (once in `Cldr.Unit.to_string/3` and then again in `Cldr.Unit.to_iolist/3`).

### Bug Fixes

* The new string formatter correctly assembles units with an SI prefix (ie `millimeter`) in languages such as German where the noun is capitalized.

## Cldr_Units v3.5.0-rc.0

This is the changelog for Cldr_units v3.5.0-rc.0 released on March 19th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fixes calculating the base unit when the unit is a complex compound unit.

* Remove double parsing when calling `Cldr.Unit.new/2` and the unit is not in `Cldr.Unit.known_units/0`

* Ensure `Cldr.Unit.unit_category/1` returns an error tuple if the category is unknown

### Enhancements

* Updated to require [ex_cldr version 2.20](https://hex.pm/packages/ex_cldr/2.20.0) which includes [CLDR 39](http://cldr.unicode.org/index/downloads/cldr-39) data.

* Add `Cldr.Unit.known_grammatical_cases/0`

* Add `Cldr.Unit.known_grammatical_genders/0`

* Add `Cldr.Unit.known_measurement_system_names/0`

* Add `Cldr.Unit.invert/1` to invert a "per" unit. This allows for increased compatibility for conversions. For example, "liters per 100 kilometers" is a measure of consumption, as is "miles per gallon".  However these two units are not convertible without inverting one of them first since one is "volume per length" and the other is "length per volume".

* Add `Cldr.Unit.conversion_for/2` to return a conversion list used when converting one unit to another.

* Add `Cldr.Unit.grammatical_gender/2` to return the grammatical gender for a given unit and locale

* Add `Cldr.Unit.conversion_for/2` to return a conversion list used when converting one unit to another.

* Add support for grammatical cases for `Cldr.Unit.to_string/2` and `Cldr.Unit.to_iolist/2`. Not all locales support more than the nominative case. The nominative case is the default. Any configured "Additional Units" in a backend module will need to be modified to put the localisations a map with the key `:nominative`.  See the readme for more information on migrating additional units.  On example is:
```elixir
defmodule MyApp.Cldr do
  use Cldr.Unit.Additional

  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]

  unit_localization(:person, "en", :long,
    nominative: %{
      one: "{0} person",
      other: "{0} people"
    },
    display_name: "people"
  )
end
```

* Support conversions where one of the base units is the inverted conversion of the other. This allows conversion between, for example, `mile per gallon` and `liter per 100 kilometer`. These are both compound units of `length` and `volume` but are inverse representations from each other.

## Cldr_Units v3.4.0

This is the changelog for Cldr_units v3.4.0 released on February 9th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix readme example for `MyApp.Cldr.Unit.convert/2`.  Thanks to @DamienFF. Closes #16.

* Add missing `<backend>.convert!/2`

### Enhancements

* Supports the definition of custom units in `config.exs`.

* Add `Cldr.Unit.display_name/2`

* Add `Cldr.Unit.known_units_by_category/0`

* Add `Cldr.Unit.known_units_for_category/1`

* Add `Cldr.Unit.measurement_system_units/0`

* Add `Cldr.Unit.measurement_system_from_locale/{2, 3}`

* Add `Cldr.Unit.measurement_system_for_territory/1`

* Add `Cldr.Unit.measurement_systems_for_unit/1`

* Improve `Cldr.Unit.IncompatibleUnit` exception error message

* Deprecate `Cldr.Unit.measurement_systems/0` in favour of `Cldr.Unit.measurement_systems_by_territory/0`

* Requires `ex_cldr` version `~> 2.19` which includes the localised display name of units

## Cldr_Units v3.3.1

This is the changelog for Cldr_units v3.3.1 released on November 3rd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `Cldr.Unit.localize/2` when no options are provided

## Cldr_Units v3.3.0

This is the changelog for Cldr_units v3.3.0 released on November 1st, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Update to [CLDR38](http://cldr.unicode.org/index/downloads/cldr-38)

## Cldr_Units v3.2.1

This is the changelog for Cldr_units v3.2.1 released on September 26th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Use `Cldr.default_backend!/0` when available (as in later ex_cldr releases) since `Cldr.default_backend/0` is deprecated.

## Cldr_Units v3.2.0

This is the changelog for Cldr_units v3.2.0 released on September 5th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Support string form of unit usage when passed as option `:usage` to `Cldr.Unit.new/3`. This is required to support improved serialization in [ex_cldr_units_sql](https://hex.pm/packages/ex_cldr_units_sql)

### Bug Fixes

* Correct the documentation to reflect the option `:usage` to `Cldr.Unit.new/3` rather than the incorrect `:use`.

* Fix spec for `Cldr.Units.compatible?/2`. Thanks to @lostkobrakai.

## Cldr_Units v3.1.2

This is the changelog for Cldr_units v3.1.2 released on August 29th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fixes dialyzer warning on `Cldr.Unit.to_string/3` and `Cldr.Unit.to_string!/3`. Thanks to @maennchen for the report. Closes #15.

* Support `Decimal` numbers in `Cldr.Unit.to_string/3` and `Cldr.Unit.to_string!/3`.

## Cldr_Units v3.1.1

This is the changelog for Cldr_units v3.1.1 released on June 29th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Ensure that `:locale` is passed through to `Cldr.Number.to_string/3`. Thanks for the PR to @Zurga. Closes #14.

## Cldr_Units v3.1.0

This is the changelog for Cldr_units v3.1.0 released on May 18th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.to_iolist/3` and `Cldr.Unit.to_iolist!/3` to return the formatted unit as an iolist rather than a string. This allows for formatting the number and the unit name differently. It also allows some efficiency in inserting formatted content into a Phoenix workflow since it handles iolists efficiently.

### Bug Fixes

* Fix resolving translatable unit names from strings

* Fix converting translatable units that have a "per" conversion

## Cldr_Units v3.0.1

This is the changelog for Cldr_units v3.0.1 released on May 15th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Corrects unit creation when the unit itself is directly translatable (like `:kilowatt_hour`) but there is no explicit conversion, just an implicit calculated conversion. Thanks to @syfgkjasdkn.

## Cldr_Units v3.0.0

This is the changelog for Cldr_units v3.0.0 released on May 4th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Summary

* New unit creation including rational numbers

* Base unit calculation

* New unit preferences

* New conversion engine

### Breaking changes

* `Cldr.Unit.new/2` is now `Cldr.Unit/{2, 3}` and it returns a standard `{:ok, unit}` tuple on success. Use `Cldr.Unit.new!/{2,3}` if you want to retain the previous behaviour.

* Removed `Cldr.Unit.unit_tree/0`

* Removed `Cldr.Unit.units/1`

* Removed `Cldr.Unit.compatible_units/2`

* Removed `Cldr.Unit.best_match/1`

* Removed `Cldr.Unit.jaro_match/1`

* Removed `Cldr.Unit.unit_category_map/0` (replaced with `Cldr.Unit.base_unit_category_map/0`)

### Deprecations

* Deprecate `Cldr.Unit.unit_categories/0` in favour of `Cldr.Unit.known_unit_categories/0` to be consistent across CLDR.

### Enhancements

* Incorporate CLDR's unit conversion data into the new conversion engine

* Unit values may now be rational numbers.  Conversion data and the results of conversions are executed and retained as rationals. New units can be created with integer, float, Decimal or rational numbers. Conversion to floats is done only when the unit is output via `Cldr.Unit.to_string/3` or explicitly through the new function `Cldr.Unit.ratio_to_float/1`

* Add an option `:usage` to `Cldr.Unit.new/{2,3}`. This defines an expected usage for a given unit that will be applied during localization. The default is `:default`. See `Cldr.Unit.unit_category_map/0` for what usage is defined for a unit category.

* Add `Cldr.Unit.known_measurement_sytems/0` to return the known measurement systems

* Add `Cldr.Unit.Conversion.preferred_units/3` that returns a list of preferred units for a given unit. This makes it straight forward to take a unit and convert it to the units preferred by the user for a given unit type, locale and use case.

* Add `Cldr.Unit.base_category_map/0` that maps base units to their unit categories. For example, map `mile_per_hour` to `:speed` or `kilogram_square_meter_per_cubic_second_ampere` to `:voltage`. Base units are derived from a unit name and are not normally the concern of the consumer of `ex_cldr_units`.

## Cldr_Units v2.8.1

This is the changelog for Cldr_units v2.8.1 released on April 25th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Updates data management to be compatible with data from both both CLDR 36 (ex_cldr 2.13) and CLDR 37 (ex_cldr 2.14)

## Cldr_Units v2.8.0

This is the changelog for Cldr_units v2.8.0 released on January 27th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Support the new `Enum.sort/2` in Elixir 1.10. The function `Cldr.Math.cmp/2` is deprecated in favour of `Cldr.Math.compare/2` that has the same function signature and returns the same result that is compatible with Elixir 1.10.

* Adds `Cldr.Unit.compare/2` that is required for `Enum.sort/2` to work as expected with units.

As an example:
```
iex> alias Cldr.Unit                                                                             Cldr.Unit

iex> unit_list = [Unit.new(:millimeter, 100), Unit.new(:centimeter, 100), Unit.new(:meter, 100), Unit.new(:kilometer, 100)]
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

## Cldr_Units v2.7.0

This is the changelog for Cldr_units v2.7.0 released on October 10th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Update [ex_cldr](https://github.com/elixir-cldr/cldr) to version `2.11.0` which encapsulates [CLDR](https://cldr.unicode.org) version `36.0.0` data.

* Update minimum Elixir version to `1.6`

* Adds conversion for `newton meter`, `dalton`, `solar luminosity`, `pound foot`, `bar`, `newton`, `electron volt`, `barrel`, `dunam`, `decade`, `mole`, `pound force`, `megapascal`, `pascal`, `kilopascal`, `solar radius`, `therm US`, `British thermal unit`, `earth mass`.

## Cldr_Units v2.6.1

This is the changelog for Cldr_units v2.6.1 released on August 31st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `Cldr.Unit.to_string/3` to ensure that `{:ok, string}` is returned when formatting a list of units

## Cldr_Units v2.6.0

This is the changelog for Cldr_units v2.6.0 released on August 25th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.localize/3` to support converting a given unit into units that are familiar to a given territory. For example, given a unit of `#Unit<2, :meter>` is would normally be expected to show this as `[#Unit<:foot, 5>, #Unit<:inch, 11>]`. The data to support these conversions is returned by `Cldr.Unit.unit_preferences/0`. An example:

```elixir
  iex> height = Cldr.Unit.new(1.8, :meter)
  iex> Cldr.Unit.localize height, :person, territory: :US, style: :informal
  [#Unit<:foot, 5>, #Unit<:inch, 11>]
```

  * Note that conversion is dependent on context. The context above is `:person` reflecting that we are referring to the height of a person. For units of `length` category, the other contexts available are `:rainfall`, `:snowfall`, `:vehicle`, `:visibility` and `:road`. Using the above example with the context of `:rainfall` we see

```elixir
  iex> Cldr.Unit.localize height, :rainfall, territory: :US
  [#Unit<:inch, 71>]
```

* Adds a `:per` option to `Cldr.Unit.to_string/3`. This option leverages the `per` formatting style to allow compound units to be printed.  For example, assume want to emit a string which represents "kilograms per second". There is no such unit defined in CLDR (or perhaps anywhere!). But if we define the unit `unit = Cldr.Unit.new(:kilogram, 20)` we can then execute `Cldr.Unit.to_string(unit, per: :second)`.  Each locale defines a specific way to format such a compound unit.  Usually it will return something like `20 kilograms/second`

* Adds `Cldr.Unit.unit_preferences/0` to map units into a territory preference alternative unit

* Adds `Cldr.Unit.measurement_systems/0` that identifies the unit system in use for a territory

* Adds `Cldr.Unit.measurement_system_for/1` that returns the measurement system in use for a given territory.  The result will be one of `:metric`, `:US` or `:UK`.

### Deprecation

* Add `Cldr.Unit.unit_category/1` and deprecate `Cldr.Unit.unit_type/1` in order to be consistent with the nomenclature of CLDR

## Cldr_Units v2.5.3

This is the changelog for Cldr_units v2.5.3 released on August 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix `@spec` for `Cldr.Unit.to_string/3` and `Cldr.Unit.to_string!/3`

## Cldr_Units v2.5.2

This is the changelog for Cldr_units v2.5.2 released on August 21st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Replace `Cldr.get_current_locale/0` with `Cldr.get_locale/0`in docs

* Fix dialyzer warnings

## Cldr_Units v2.5.1

This is the changelog for Cldr_units v2.5.1 released on June 18th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Standardize the development cldr backend as `MyApp.Cldr` which makes for more understandable and readable examples and doc tests

* `Cldr.Unit.to_string/3` now allows for the `backend` parameter to default to `Cldr.default_backend/0`

## Cldr_Units v2.5.0

This is the changelog for Cldr_units v2.5.0 released on March 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Updates to [CLDR version 35.0.0](http://cldr.unicode.org/index/downloads/cldr-35) released on March 27th 2019.

## Cldr_Units v2.4.0

This is the changelog for Cldr_units v2.4.0 released on March 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Supports `Cldr.default_backend()` as a default for `backend` parameters in `Cldr.Unit`

## Cldr_Units v2.3.3

This is the changelog for Cldr_units v2.3.2 released on March 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Include `priv` directory in the hex package (that's where the conversion json exists)

## Cldr_Units v2.3.2

This is the changelog for Cldr_units v2.3.2 released on March 20th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Bug Fixes

* Fix dialyzer warnings

## Cldr_Units v2.3.1

This is the changelog for Cldr_units v2.3.1 released on March 15th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Makes generation of documentation for backend modules optional.  This is implemented by the `:generate_docs` option to the backend configuration.  The default is `true`. For example:

```
defmodule MyApp.Cldr do
  use Cldr,
    default_locale: "en-001",
    locales: ["en", "ja"],
    gettext: MyApp.Gettext,
    generate_docs: false
end
```

## Cldr_Units v2.3.0

This is the changelog for Cldr_units v2.3.0 released on March 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* The conversion tables are now stored as json and updates may be downloaded at any time with the mix task `mix cldr.unit.download`. This means that updates to the conversion table may be made without requiring a new release of `Cldr.Unit`.

## Cldr_Units v2.2.0

This is the changelog for Cldr_units v2.2.0 released on February 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

This release is primarily about improving the conversion of units without introducing precision errors that accumulate for floats. The strategy is to define the conversion value between individual unit pairs.

Currently the implementation uses a static map.  In order to give users a better experience a future release will allow for both specifying mappings as a parameter to `Cldr.Unit.convert/2` and as compile time configuration options including the option to download conversion tables from the internet.

* Direct conversions are now supported. For some calculations, the process of diving and multiplying by conversion factors produces an unexpected result. Some direct conversions are now defined which produce a more expected result.

* In most cases, return integer values from conversion and decomposition when the originating unit value is also an integer

## Cldr_Units v2.1.0

This is the changelog for Cldr_units v2.1.0 released on December 8th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.Conversion.convert!/2`

* Add `Cldr.Unit.Math.cmp/2`

* Add `Cldr.Unit.decompose/2`

* Add `Cldr.Unit.zero/1`

* Add `Cldr.Unit.zero?/1`

The appropriate backend equivalents are also added.

## Cldr_Units v2.0.0

This is the changelog for Cldr_units v2.0.0 released on November 24th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_units/tags)

### Breaking changes

* `Cldr.Unit` now requires a `Cldr` backend module to be configured

* In order for the `String.Chars` protocol to be supported (which is used in string interpolation and by `Kernel.to_string/1`) a default backend must be configured.  For example in `config.exs`:
```
config :ex_cldr_units,
  default_backend: MyApp.Cldr
```

### Enhancements

* Move to a backend module structure with [ex_cldr](https://hex.pm/packages/ex_cldr) version 2.0