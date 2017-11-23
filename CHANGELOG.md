# Changelog for Cldr_Units v1.0.0-rc.0

This is the changelog for Cldr_Units v1.0.0-rc.0 released on November 21st, 2017.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

This version signals API stability and the first release candidate.

## Breaking changes

* `Cldr.Unit.to_string/3` is now `Cldr.Unit.to_string/2`.  The unit is now supplied as an option.  For example:

```
iex> Cldr.Unit.to_string 23, unit: :gram
{:ok, "23 grams"}

iex> Cldr.Unit.to_string 23, unit: :gram, locale: "zh"
{:ok, "23克"}
```

* Rename `Cldr.Unit.available_units` to `Cldr.Unit.units`

## Enhancements

* Add `Cldr.Unit.new/2` and `Cldr.Unit.new!/2` to create a new `%Cldr.Unit{}` struct

* Add `Cldr.Unit.convert/2` to provide unit conversion for compatible unit types

* Add `Cldr.Unit.add/2`, `Cldr.Unit.sub/2`, `Cldr.Unit.mult/2`, `Cldr.Unit.div/2` basic arithmetic for compatible unit types

* Add `Cldr.Unit.jaro_match/2` and `Cldr.Unit.best_match/2` functions that facilitate finding units by name

* Add `Cldr.Unit.compatible_units/1` to return the list of units that can be converted into each other

* Add `Cldr.Unit.compatible?/2` that returns a boolean indicating if two units are of the same type and are convertible to each other

* Add `Cldr.Unit.Alias` module to manage unit name aliases which is helpful for user interfaces that use a combination of US spelling and British spelling

