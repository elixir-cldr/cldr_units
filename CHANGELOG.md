# Changelog for Cldr_Units v2.2.0

This is the changelog for Cldr_units v2.1.0 released on February 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

This release is primarily about improving the conversion of units without introducing precision errors that accumulate for floats. The strategy is to define the conversion value between individual unit pairs.

Currently the implementation uses a static map.  In order to give users a better experience a future release will allow for both specifying mappings as a parameter to `Cldr.Unit.convert/2` and as compile time configuration options including the option to download conversion tables from the internet.

* Direct conversions are now supported. For some calculations, the process of diving and multiplying by conversion factors produces an unexpected result. Some direct conversions are now defined which produce a more expected result.

* In most cases, return integer values from conversion and decomposition when the originating unit value is also an integer

# Changelog for Cldr_Units v2.1.0

This is the changelog for Cldr_units v2.1.0 released on December 8th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.Conversion.convert!/3`

* Add `Cldr.Unit.Math.cmp/2`

* Add `Cldr.Unit.decompose/2`

* Add `Cldr.Unit.zero/1`

* Add `Cldr.Unit.zero?/1`

The appropriate backend equivalents are also added.

# Changelog for Cldr_Units v2.0.0

This is the changelog for Cldr_units v2.0.0 released on November 24th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Breaking changes

* `Cldr.Unit` now requires a `Cldr` backend module to be configured

* In order for the `String.Chars` protocol to be supported (which is used in string interpolation and by `Kernel.to_string/1`) a default backend must be configured.  For example in `config.exs`:
```
config :ex_cldr_units,
  default_backend: MyApp.Cldr
```

### Enhancements

* Move to a backend module structure with [ex_cldr](https://hex.pm/packages/ex_cldr) version 2.0