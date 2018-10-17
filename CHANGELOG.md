# Changelog for Cldr_Units v1.3.0

This is the changelog for Cldr v1.3.0 released on October 18th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* Update [ex_cldr](https://hex.pm/packages/ex_cldr) dependency to version 1.8.0 which uses CLDR data version 34.

* Adds `petabyte` and `atmosphere` units

# Changelog for Cldr_Units v1.2.2

This is the changelog for Cldr v1.2.2 released on August 26th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

## Bug Fixes

* `Cldr.Unit.Conversion.convert/2` now correctly accepts units with a decimal value. Fixes #8.  Thanks to @lostkobrakai.

# Changelog for Cldr_Units v1.2.1

This is the changelog for Cldr v1.2.1 released on May 9th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

## Bug Fixes

* `to_string/3` now performs cardinal rather than ordinal pluralization. Thanks to @lostkobrakai. Closes #7

# Changelog for Cldr_Units v1.2.0

This is the changelog for Cldr v1.2.0 released on March 29th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* Update ex_cldr dependency to version 1.5.0 which uses CLDR data version 33.

* Update ex_cldr_numbers dependency to 1.4.0

# Changelog for Cldr_Units v1.1.1

## Bug Fixes

* Moves protocol implementations to a separate source file so that recompilation on locale configuration change will work.

# Changelog for Cldr_Units v1.1.0

## Bug Fixes

* Fixes the documentation for `Cldr.Units.convert/2` and adds the correct spec.  Thanks to @lostbokrakai.  Closes #5.

## Enhancements

* Add `Cldr.Unit.value(Unit.t)` to return the value of the `Unit`.  Closes #6.

* Format the code with `mix format`

# Changelog for Cldr_Units v1.0.1

## Bug Fixes

* Fixes the conversion rates for `:centimeter` and `:picometer`