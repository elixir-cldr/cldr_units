# Changelog for Cldr_Units v1.1.1

This is the changelog for Cldr v1.1.1 released on January 26th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

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