# Changelog

## Cldr_Units v0.2.1 October 30th, 2017

### Enhancements

* Move to `ex_cldr` 0.8.2 which changes Cldr.Number.PluralRule.plural_rule/3 implementation for Float so that it no longer casts to a Decimal nor delegates to the Decimal path".  This will have a small positive impact on performance

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