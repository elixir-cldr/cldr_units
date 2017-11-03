# Changelog

## Cldr_Units v0.4.1 November 3rd, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.11.0 in which the term `territory` is preferred over `region`

## Cldr_Units v0.4.0 November 2nd, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.10.0 which incorporates CLDR data version 32 released on November 1st, 2017.  For further information on the changes in CLDR 32 release consult the [release notes](http://cldr.unicode.org/index/downloads/cldr-32).

## Cldr_Units v0.3.0 November 1st, 2017

* Update to ex_cldr v0.9.0

## Cldr_Units v0.3.0 October 31st, 2017

### Breaking Change

* The unit names are now shortened by removing the unit type prefix.  Where in previous releases it would be `:volume_gallon` the unit is now `:gallon`.  The unit types can be retrieved by `Cldr.Unit.available_unit_types/2`.

* This change internally keeps a linkage between unit types (like `:volume`, `:mass` and so on) and the available units to support upcoming unit conversion.

## Cldr_Units v0.2.1 October 30th, 2017

### Enhancements

* Move to `ex_cldr` 0.8.2 which changes Cldr.Number.PluralRule.plural_rule/3 implementation for Float so that it no longer casts to a Decimal nor delegates to the Decimal path.  This will have a small positive impact on performance

## Cldr_Units v0.2.0 October 25th, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.8.0 for compatibility with the new `%Cldr.LanguageTag{}` representation of a locale

## Cldr_Units v0.1.3 September 18th, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.7.0 and add [ex_cldr_numbers](https://hex.pm/packages/ex_numbers) version 0.1.0

## Cldr_Units v0.1.2 September 4th, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.6.2

## Cldr_Units v0.1.1 August 24, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.5.2 which correctly serialises the locale downloading process

## Cldr_Units v0.1.0 August 19, 2017

### Enhancements

* Initial release