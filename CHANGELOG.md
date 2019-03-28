# Changelog for Cldr_Units v2.5.0

This is the changelog for Cldr_units v2.5.0 released on March 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* Updates to [CLDR version 35.0.0](http://cldr.unicode.org/index/downloads/cldr-35) released on March 27th 2019.

# Changelog for Cldr_Units v2.4.0

This is the changelog for Cldr_units v2.4.0 released on March 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* Supports `Cldr.default_backend()` as a default for `backend` parameters in `Cldr.Unit`

# Changelog for Cldr_Units v2.3.3

This is the changelog for Cldr_units v2.3.2 released on March 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Bug Fixes

* Include `priv` directory in the hex package (thats where the conversion json exists)

# Changelog for Cldr_Units v2.3.2

This is the changelog for Cldr_units v2.3.2 released on March 20th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Bug Fixes

* Fix dialyzer warnings

# Changelog for Cldr_Units v2.3.1

This is the changelog for Cldr_units v2.3.1 released on March 15th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

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

# Changelog for Cldr_Units v2.3.0

This is the changelog for Cldr_units v2.3.0 released on March 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* The conversion tables are now stored as json and updates may be downloaded at any time with the mix task `mix cldr.unit.download`. This means that updates to the conversion table may be made without requiring a new release of `Cldr.Unit`.

# Changelog for Cldr_Units v2.2.0

This is the changelog for Cldr_units v2.2.0 released on February 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

This release is primarily about improving the conversion of units without introducing precision errors that accumulate for floats. The strategy is to define the conversion value between individual unit pairs.

Currently the implementation uses a static map.  In order to give users a better experience a future release will allow for both specifying mappings as a parameter to `Cldr.Unit.convert/2` and as compile time configuration options including the option to download conversion tables from the internet.

* Direct conversions are now supported. For some calculations, the process of diving and multiplying by conversion factors produces an unexpected result. Some direct conversions are now defined which produce a more expected result.

* In most cases, return integer values from conversion and decomposition when the originating unit value is also an integer

# Changelog for Cldr_Units v2.1.0

This is the changelog for Cldr_units v2.1.0 released on December 8th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_units/tags)

### Enhancements

* Add `Cldr.Unit.Conversion.convert!/2`

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