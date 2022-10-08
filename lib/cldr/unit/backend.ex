defmodule Cldr.Unit.Backend do
  def define_unit_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    additional_units = Module.concat(backend, Unit.Additional)
    config = Macro.escape(config)

    quote location: :keep,
          bind_quoted: [
            module: module,
            backend: backend,
            config: config,
            additional_units: additional_units
          ] do
      # Create an empty additional units module if it wasn't previously
      # defined
      unless Code.ensure_loaded?(additional_units) do
        defmodule additional_units do
          @moduledoc false
          def known_locales do
            []
          end

          def units_for(_locale, _style) do
            %{}
          end

          def additional_units do
            []
          end
        end
      end

      defmodule Unit do
        @moduledoc false
        if Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc """
          Supports the CLDR Units definitions which provide for the localization of many
          unit types.

          """
        end

        @styles [:long, :short, :narrow]

        alias Cldr.Math

        defdelegate new(unit, value), to: Cldr.Unit
        defdelegate new!(unit, value), to: Cldr.Unit
        defdelegate compatible?(unit_1, unit_2), to: Cldr.Unit
        defdelegate value(unit), to: Cldr.Unit
        defdelegate zero(unit), to: Cldr.Unit
        defdelegate zero?(unit), to: Cldr.Unit
        defdelegate decompose(unit, list), to: Cldr.Unit

        defdelegate measurement_system_from_locale(locale), to: Cldr.Unit
        defdelegate measurement_system_from_locale(locale, category), to: Cldr.Unit
        defdelegate measurement_system_from_locale(locale, backend, category), to: Cldr.Unit

        defdelegate measurement_systems_for_unit(unit), to: Cldr.Unit

        defdelegate measurement_system_for_territory(territory), to: Cldr.Unit
        defdelegate measurement_system_for_territory(territory, key), to: Cldr.Unit

        defdelegate measurement_system?(unit, systems), to: Cldr.Unit

        @deprecated "Use #{inspect(__MODULE__)}.measurement_system_for_territory/1"
        defdelegate measurement_system_for(territory),
          to: Cldr.Unit,
          as: :measurement_system_for_territory

        @deprecated "Use #{inspect(__MODULE__)}.measurement_system_for_territory/2"
        defdelegate measurement_system_for(territory, key),
          to: Cldr.Unit,
          as: :measurement_system_for_territory

        defdelegate known_units, to: Cldr.Unit
        defdelegate known_unit_categories, to: Cldr.Unit
        defdelegate known_styles, to: Cldr.Unit
        defdelegate styles, to: Cldr.Unit, as: :known_styles
        defdelegate default_style, to: Cldr.Unit

        defdelegate validate_unit(unit), to: Cldr.Unit
        defdelegate validate_style(unit), to: Cldr.Unit
        defdelegate unit_category(unit), to: Cldr.Unit

        defdelegate add(unit_1, unit_2), to: Cldr.Unit.Math
        defdelegate sub(unit_1, unit_2), to: Cldr.Unit.Math
        defdelegate mult(unit_1, unit_2), to: Cldr.Unit.Math
        defdelegate div(unit_1, unit_2), to: Cldr.Unit.Math

        defdelegate add!(unit_1, unit_2), to: Cldr.Unit.Math
        defdelegate sub!(unit_1, unit_2), to: Cldr.Unit.Math
        defdelegate mult!(unit_1, unit_2), to: Cldr.Unit.Math
        defdelegate div!(unit_1, unit_2), to: Cldr.Unit.Math

        defdelegate round(unit, places, mode), to: Cldr.Unit.Math
        defdelegate round(unit, places), to: Cldr.Unit.Math
        defdelegate round(unit), to: Cldr.Unit.Math

        defdelegate convert(unit_1, to_unit), to: Cldr.Unit.Conversion
        defdelegate convert!(unit_1, to_unit), to: Cldr.Unit.Conversion

        @doc """
        Formats a number into a string according to a unit definition for a locale.

        ## Arguments

        * `list_or_number` is any number (integer, float or Decimal) or a
          `t:Cldr.Unit` struct or a list of `t:Cldr.Unit` structs

        * `options` is a keyword list

        ## Options

        * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
          the number to be formatted is a `t:Cldr.Unit` struct

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.known_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`

        * `:grammatical_case` indicates that a localisation for the given
          locale and given grammatical case should be used. See `Cldr.Unit.known_grammatical_cases/0`
          for the list of known grammatical cases. Note that not all locales
          define all cases. However all locales do define the `:nominative`
          case, which is also the default.

        * `:gender` indicates that a localisation for the given
          locale and given grammatical gender should be used. See `Cldr.Unit.known_grammatical_genders/0`
          for the list of known grammatical genders. Note that not all locales
          define all genders. The default gender is `#{inspect(__MODULE__)}.default_gender/1`
          for the given locale.

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `{:ok, formatted_string}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 123)
            {:ok, "123 gallons"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 1)
            {:ok, "1 gallon"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 1), locale: "af"
            {:ok, "1 gelling"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 1), locale: "af-NA"
            {:ok, "1 gelling"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 1), locale: "bs"
            {:ok, "1 galon"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 1234), format: :long
            {:ok, "1 thousand gallons"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:gallon, 1234), format: :short
            {:ok, "1K gallons"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:megahertz, 1234)
            {:ok, "1,234 megahertz"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:megahertz, 1234), style: :narrow
            {:ok, "1,234MHz"}

            iex> #{inspect(__MODULE__)}.to_string Cldr.Unit.new!(:megabyte, 1234), locale: "en", style: :unknown
            {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

        """
        @spec to_string(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
                {:ok, String.t()} | {:error, {atom, binary}}

        def to_string(number, options \\ []) do
          Cldr.Unit.Format.to_string(number, unquote(backend), options)
        end

        @doc """
        Formats a list using `to_string/3` but raises if there is
        an error.

        ## Arguments

        * `list_or_number` is any number (integer, float or Decimal) or a
          `t:Cldr.Unit` struct or a list of `t:Cldr.Unit` structs

        * `options` is a keyword list

        ## Options

        * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
          the number to be formatted is a `t:Cldr.Unit` struct

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.known_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`

        * `:grammatical_case` indicates that a localisation for the given
          locale and given grammatical case should be used. See `Cldr.Unit.known_grammatical_cases/0`
          for the list of known grammatical cases. Note that not all locales
          define all cases. However all locales do define the `:nominative`
          case, which is also the default.

        * `:gender` indicates that a localisation for the given
          locale and given grammatical gender should be used. See `Cldr.Unit.known_grammatical_genders/0`
          for the list of known grammatical genders. Note that not all locales
          define all genders. The default gender is `#{inspect(__MODULE__)}.default_gender/1`
          for the given locale.

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `formatted_string` or

        * raises an exception

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! 123, unit: :gallon
            "123 gallons"

            iex> #{inspect(__MODULE__)}.to_string! 1, unit: :gallon
            "1 gallon"

            iex> #{inspect(__MODULE__)}.to_string! 1, unit: :gallon, locale: "af"
            "1 gelling"

        """
        @spec to_string!(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
                String.t() | no_return()

        def to_string!(number, options \\ []) do
          Cldr.Unit.Format.to_string!(number, unquote(backend), options)
        end

        @doc """
        Formats a number into an iolist according to a unit definition
        for a locale.

        ## Arguments

        * `list_or_number` is any number (integer, float or Decimal) or a
          `t:Cldr.Unit` struct or a list of `t:Cldr.Unit` structs

        * `options` is a keyword list

        ## Options

        * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
          the number to be formatted is a `t:Cldr.Unit` struct

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.known_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`

        * `:grammatical_case` indicates that a localisation for the given
          locale and given grammatical case should be used. See `Cldr.Unit.known_grammatical_cases/0`
          for the list of known grammatical cases. Note that not all locales
          define all cases. However all locales do define the `:nominative`
          case, which is also the default.

        * `:gender` indicates that a localisation for the given
          locale and given grammatical gender should be used. See `Cldr.Unit.known_grammatical_genders/0`
          for the list of known grammatical genders. Note that not all locales
          define all genders. The default gender is `#{inspect(__MODULE__)}.default_gender/1`
          for the given locale.

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `{:ok, io_list}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.to_iolist Cldr.Unit.new!(:gallon, 123)
            {:ok, ["123", " gallons"]}

        """
        @spec to_iolist(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
                {:ok, list()} | {:error, {atom, binary}}

        def to_iolist(number, options \\ []) do
          Cldr.Unit.Format.to_iolist(number, unquote(backend), options)
        end

        @doc """
        Formats a unit using `to_iolist/3` but raises if there is
        an error.

        ## Arguments

        * `list_or_number` is any number (integer, float or Decimal) or a
          `t:Cldr.Unit` struct or a list of `t:Cldr.Unit` structs

        * `options` is a keyword list

        ## Options

        * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
          the number to be formatted is a `t:Cldr.Unit` struct

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.known_styles/0`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`.

        * `:grammatical_case` indicates that a localisation for the given
          locale and given grammatical case should be used. See `Cldr.Unit.known_grammatical_cases/0`
          for the list of known grammatical cases. Note that not all locales
          define all cases. However all locales do define the `:nominative`
          case, which is also the default.

        * `:gender` indicates that a localisation for the given
          locale and given grammatical gender should be used. See `Cldr.Unit.known_grammatical_genders/0`
          for the list of known grammatical genders. Note that not all locales
          define all genders. The default gender is `#{inspect(__MODULE__)}.default_gender/1`
          for the given locale.

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `io_list` or

        * raises an exception

        ## Examples

            iex> #{inspect(__MODULE__)}.to_iolist! 123, unit: :gallon
            ["123", " gallons"]

        """
        @spec to_iolist!(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
                list() | no_return()

        def to_iolist!(number, options \\ []) do
          Cldr.Unit.Format.to_iolist!(number, unquote(backend), options)
        end

        @doc """
        Returns the localized display name
        for a unit.

        The returned text is generally suitable
        for including in UI elements such as
        selection boxes.

        ## Arguments

        * `unit` is any `t:Cldr.Unit` or any
          unit name returned by `Cldr.Unit.known_units/0`.

        * `options` is a keyword list of options.

        ## Options

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

        * `:style` is one of those returned by `Cldr.Unit.available_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`.

        ## Examples

            iex> #{inspect(__MODULE__)}.display_name :liter
            "liters"

            iex> #{inspect(__MODULE__)}.display_name :liter, locale: "fr"
            "litres"

            iex> #{inspect(__MODULE__)}.display_name :liter, locale: "fr", style: :short
            "l"

        """
        @spec display_name(Cldr.Unit.value() | Cldr.Unit.t(), Keyword.t()) ::
                String.t() | {:error, {module, binary}}

        def display_name(unit, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Unit.display_name(unit, options)
        end

        @doc """
        Localizes a unit according to the current
        processes locale and backend.

        The current process's locale is set with
        `Cldr.put_locale/1`.

        See `Cldr.Unit.localize/3` for further
        details.

        """
        @spec localize(Cldr.Unit.t()) :: [Cldr.Unit.t(), ...]
        def localize(%Cldr.Unit{} = unit) do
          Cldr.Unit.localize(unit)
        end

        @doc """
        Localizes a unit according to a territory

        A territory can be derived from a `t:Cldr.Locale.locale_name`
        or `t:Cldr.LangaugeTag`.

        Use this function if you have a unit which
        should be presented in a user interface using
        units relevant to the audience. For example, a
        unit `#Cldr.Unit100, :meter>` might be better
        presented to a US audience as `#Cldr.Unit<328, :foot>`.

        ## Arguments

        * `unit` is any unit returned by `Cldr.Unit.new/2`

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `backend.get_locale/0`

        * `:territory` is any valid territory code returned by
          `Cldr.known_territories/0`. The default is the territory defined
          as part of the `:locale`. The option `:territory` has a precedence
          over the territory in a locale.

        * `:usage` is the way in which the unit is intended
          to be used.  The available `usage` varyies according
          to the unit category.  See `Cldr.Unit.preferred_units/3`.

        ## Examples

            iex> unit = Cldr.Unit.new!(1.83, :meter)
            iex> #{inspect(__MODULE__)}.localize(unit, usage: :person_height, territory: :US)
            [
              Cldr.Unit.new!(:foot, 6, usage: :person_height),
              Cldr.Unit.new!(:inch, Ratio.new(6485183463413016, 137269716642252725), usage: :person_height)
            ]

        """
        @spec localize(Cldr.Unit.t(), Keyword.t()) :: [Cldr.Unit.t(), ...]
        def localize(unit, options \\ []) do
          Cldr.Unit.localize(unit, unquote(backend), options)
        end

        @doc """
        Parse a string to create a new unit.

        This function attempts to parse a string
        into a `number` and `unit type`. If successful
        it attempts to create a new unit using
        `Cldr.Unit.new/3`.

        The parsed `unit type` is aliased against all the
        known unit names for a give locale (or the current
        locale if no locale is specified). The known
        aliases for unit types can be returned with
        `MyApp.Cldr.Unit.unit_strings_for/1` where `MyApp.Cldr`
        is the name of a backend module.

        ## Arguments

        * `unit string` is any string to be parsed and if
          possible used to create a new `t:Cldr.Unit`

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        ## Returns

        * `{:ok, unit}` or

        * `{:error, {exception, reason}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.parse "1kg"
            Cldr.Unit.new(1, :kilogram)

            iex> #{inspect(__MODULE__)}.parse "1 tages", locale: "de"
            Cldr.Unit.new(1, :day)

            iex> #{inspect(__MODULE__)}.parse "1 tag", locale: "de"
            Cldr.Unit.new(1, :day)

            iex> #{inspect(__MODULE__)}.parse("42 millispangels")
            {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"spangels\\""}}

        """
        @spec parse(binary) :: {:ok, Cldr.Unit.t()} | {:error, {module(), binary()}}

        @doc since: "3.10.0"
        def parse(unit_string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Unit.parse(unit_string, options)
        end

        @doc since: "3.13.4"
        @doc """
        Parse a string to find a matching unit-atom.

        This function attempts to parse a string and
        extract the `unit type`.

        The parsed `unit type` is aliased against all the
        known unit names for a give locale (or the current
        locale if no locale is specified). The known
        aliases for unit types can be returned with
        `MyApp.Cldr.Unit.unit_strings_for/1` where `MyApp.Cldr`
        is the name of a backend module.

        ## Arguments

        * `unit_name_string` is any string to be parsed and converted into a `unit type`

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

        * `:backend` is any module that includes `use Cldr` and therefore
          is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

        * `:only` is a unit category or unit, or a list of unit categories and units.
          The parsed unit must match one of the categories or units in order to
          be valid. This is helpful when disambiguating parsed units. For example,
          parsing "w" could be either `:watt` or `:weeks`. Specifying `only: :duration`
          would return `:weeks`. Specifying `only: :power` would return `:watt`

        * `:except` is the oppostte of `:only`. The parsed unit must *not*
          match the specified unit or category, or unit categories and units.

        ## Returns

        * `{:ok, unit_name}` or

        * `{:error, {exception, reason}}`

        ## Notes

        * When both `:only` and `:except` options are passed, both
          conditions must be true in order to return a parsed result.

        * Only units returned by `Cldr.Unit.known_units/0` can be
          used in the `:only` and `:except` filters.

        ## Examples

            iex> #{inspect(__MODULE__)}.parse_unit_name "kg"
            {:ok, :kilogram}

            iex> #{inspect(__MODULE__)}.parse_unit_name "w"
            {:ok, :watt}

            iex> #{inspect(__MODULE__)}.parse_unit_name "w", only: :duration
            {:ok, :week}

            iex> #{inspect(__MODULE__)}.parse_unit_name "m", only: [:year, :month, :day]
            {:ok, :month}

            iex> #{inspect(__MODULE__)}.parse_unit_name "tages", locale: "de"
            {:ok, :day}

            iex> #{inspect(__MODULE__)}.parse_unit_name "tag", locale: "de"
            {:ok, :day}

            iex> #{inspect(__MODULE__)}.parse_unit_name("millispangels")
            {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"spangels\\""}}

        """
        @spec parse_unit_name(binary, Keyword.t()) :: {:ok, atom} | {:error, {module(), binary()}}
        def parse_unit_name(unit_name_string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Unit.parse_unit_name(unit_name_string, options)
        end

        @doc """
        Parse a string to create a new unit or
        raises an exception.

        This function attempts to parse a string
        into a `number` and `unit type`. If successful
        it attempts to create a new unit using
        `Cldr.Unit.new/3`.

        The parsed `unit type` is un-aliased against all the
        known unit names for a give locale (or the current
        locale if no locale is specified). The known
        aliases for unit types can be returned with
        `MyApp.Cldr.Unit.unit_strings_for/1` where `MyApp.Cldr`
        is the name of a backend module.

        ## Arguments

        * `unit string` is any string to be parsed and if
          possible used to create a new `t:Cldr.Unit`

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        ## Returns

        * `unit` or

        * raises an exception

        ## Examples

            iex> #{inspect(__MODULE__)}.parse! "1kg"
            Cldr.Unit.new!(1, :kilogram)

            iex> #{inspect(__MODULE__)}.parse! "1 tages", locale: "de"
            Cldr.Unit.new!(1, :day)

            iex> #{inspect(__MODULE__)}.parse!("42 candela per lux")
            Cldr.Unit.new!(42, "candela per lux")

            iex> #{inspect(__MODULE__)}.parse!("42 millispangels")
            ** (Cldr.UnknownUnitError) Unknown unit was detected at "spangels"

        """
        @spec parse!(binary) :: Cldr.Unit.t() | no_return()

        @doc since: "3.10.0"
        def parse!(unit_string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Unit.parse!(unit_string, options)
        end

        @doc since: "3.13.4"
        @doc """
        Parse a string to find a matching unit-atom.

        This function attempts to parse a string and
        extract the `unit type`.

        The parsed `unit type` is aliased against all the
        known unit names for a give locale (or the current
        locale if no locale is specified). The known
        aliases for unit types can be returned with
        `MyApp.Cldr.Unit.unit_strings_for/1` where `MyApp.Cldr`
        is the name of a backend module.

        ## Arguments

        * `unit_name_string` is any string to be parsed and converted into a `unit type`

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `t:Cldr.LanguageTag` struct. The default is `Cldr.get_locale/0`

        * `:backend` is any module that includes `use Cldr` and therefore
          is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

        * `:only` is a unit category or unit, or a list of unit categories and units.
          The parsed unit must match one of the categories or units in order to
          be valid. This is helpful when disambiguating parsed units. For example,
          parsing "w" could be either `watts` or `:week`. Specifying `only: :duration`
          would return `:week`. Specifying `only: :power` would return `:watts`

        * `:except` is the oppostte of `:only`. The parsed unit must *not*
          match the specified unit or category, or unit categories and units.

        ## Returns

        * `unit_name` or

        * raises an exception

        ## Notes

        * When both `:only` and `:except` options are passed, both
          conditions must be true in order to return a parsed result.

        * Only units returned by `Cldr.Unit.known_units/0` can be
          used in the `:only` and `:except` filters.

        ## Examples

            iex> #{inspect(__MODULE__)}.parse_unit_name! "kg"
            :kilogram

            iex> #{inspect(__MODULE__)}.parse_unit_name! "w"
            :watt

            iex> #{inspect(__MODULE__)}.parse_unit_name! "w", only: :duration
            :week

            iex> #{inspect(__MODULE__)}.parse_unit_name! "m", only: [:year, :month, :day]
            :month

            iex> #{inspect(__MODULE__)}.parse_unit_name! "tages", locale: "de"
            :day

            iex> #{inspect(__MODULE__)}.parse_unit_name! "tag", locale: "de"
            :day

            iex> #{inspect(__MODULE__)}.parse_unit_name!("millispangels")
            ** (Cldr.UnknownUnitError) Unknown unit was detected at "spangels"

        """
        @spec parse_unit_name!(binary) :: atom() | no_return()
        def parse_unit_name!(unit_name_string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Unit.parse_unit_name!(unit_name_string, options)
        end

        @doc """
        Returns a list of the preferred units for a given
        unit, locale, use case and scope.

        The units used to represent length, volume and so on
        depend on a given territory, measurement system and usage.

        For example, in the US, people height is most commonly
        referred to in `inches`, or informally as `feet and inches`.
        In most of the rest of the world it is `centimeters`.

        ## Arguments

        * `unit` is any unit returned by `Cldr.Unit.new/2`.

        * `backend` is any Cldr backend module. That is, any module
          that includes `use Cldr`. The default is `Cldr.default_backend/0`

        * `options` is a keyword list of options or a
          `Cldr.Unit.Conversion.Options` struct. The default
          is `[]`.

        ## Options

        * `:usage` is the unit usage. for example `;person` for a unit
          type of length. The available usage for a given unit category can
          be seen with `Cldr.Unit.unit_category_usage/0`. The default is `nil`

        * `:scope` is either `:small` or `nil`. In some usage, the units
          used are different when the unit size is small. It is up to the
          developer to determine when `scope: :small` is appropriate.

        * `:alt` is either `:informal` or `nil`. Like `:scope`, the units
          in use depend on whether they are being used in a formal or informal
          context.

        * `:locale` is any locale returned by `Cldr.validate_locale/2`

        ## Returns

        * `{:ok, unit_list, formatting_options}` or

        * `{:error, {exception, reason}}`

        ## Notes

        `formatting_options` is a keyword list of options
        that can be passed to `Cldr.Unit.to_string/3`. Its
        primary intended usage is for localizing a unit that
        decomposes into more than one unit (for example when
        2 meters might become 6 feet 6 inches.) In such
        cases, the last unit in the list (in this case the
        inches) is formatted with the `formatting_options`.

        ## Examples

            iex> meter = Cldr.Unit.new!(:meter, 1)
            iex> #{inspect(__MODULE__)}.preferred_units meter, locale: "en-US", usage: :person_height
            {:ok, [:foot, :inch], []}
            iex> #{inspect(__MODULE__)}.preferred_units meter, locale: "en-US", usage: :person
            {:ok, [:inch], []}
            iex> #{inspect(__MODULE__)}.preferred_units meter, locale: "en-AU", usage: :person
            {:ok, [:centimeter], []}
            iex> #{inspect(__MODULE__)}.preferred_units meter, locale: "en-US", usage: :road
            {:ok, [:foot], [round_nearest: 1]}
            iex> #{inspect(__MODULE__)}.preferred_units meter, locale: "en-AU", usage: :road
            {:ok, [:meter], [round_nearest: 1]}

        """
        @spec preferred_units(Cldr.Unit.t(), Keyword.t()) ::
                {:ok, String.t()} | {:error, {module, binary}}

        def preferred_units(unit, options \\ []) do
          Cldr.Unit.Preference.preferred_units(unit, unquote(backend), options)
        end

        @doc """
        Returns a list of the preferred units for a given
        unit, locale, use case and scope.

        The units used to represent length, volume and so on
        depend on a given territory, measurement system and usage.

        For example, in the US, people height is most commonly
        referred to in `inches`, or informally as `feet and inches`.
        In most of the rest of the world it is `centimeters`.

        ## Arguments

        * `unit` is any unit returned by `Cldr.Unit.new/2`.

        * `backend` is any Cldr backend module. That is, any module
          that includes `use Cldr`. The default is `Cldr.default_backend/0`

        * `options` is a keyword list of options or a
          `Cldr.Unit.Conversion.Options` struct. The default
          is `[]`.

        ## Options

        * `:usage` is the unit usage. for example `;person` for a unit
          type of length. The available usage for a given unit category can
          be seen with `Cldr.Unit.unit_category_usage/0`. The default is `nil`

        * `:scope` is either `:small` or `nil`. In some usage, the units
          used are different when the unit size is small. It is up to the
          developer to determine when `scope: :small` is appropriate.

        * `:alt` is either `:informal` or `nil`. Like `:scope`, the units
          in use depend on whether they are being used in a formal or informal
          context.

        * `:locale` is any locale returned by `Cldr.validate_locale/2`

        ## Returns

        * `unit_list` or

        * raises an exception

        ## Examples

            iex> meter = Cldr.Unit.new!(:meter, 2)
            iex> #{inspect(__MODULE__)}.preferred_units! meter, locale: "en-US", usage: :person_height
            [:foot, :inch]
            iex> #{inspect(__MODULE__)}.preferred_units! meter, locale: "en-AU", usage: :person
            [:centimeter]
            iex> #{inspect(__MODULE__)}.preferred_units! meter, locale: "en-US", usage: :road
            [:foot]
            iex> #{inspect(__MODULE__)}.preferred_units! meter, locale: "en-AU", usage: :road
            [:meter]

        """
        def preferred_units!(unit, options \\ []) do
          Cldr.Unit.Preference.preferred_units!(unit, unquote(backend), options)
        end

        @grammatical_features Cldr.Config.grammatical_features()
        @grammatical_gender Cldr.Config.grammatical_gender()
        @default_gender :masculine

        # Generate the functions that encapsulate the unit data from CDLR
        @doc false
        def units_for(locale \\ unquote(backend).get_locale(), style \\ Cldr.Unit.default_style())

        for locale_name <- Cldr.Locale.Loader.known_locale_names(config) do
          locale_data =
            locale_name
            |> Cldr.Locale.Loader.get_locale(config)
            |> Map.get(:units)

          units_for_style = fn additional_units, style ->
            Map.get(locale_data, style)
            |> Enum.map(&elem(&1, 1))
            |> Cldr.Map.merge_map_list()
            |> Map.merge(additional_units)
            |> Map.new()
          end

          for style <- @styles do
            additional_units = additional_units.units_for(locale_name, style)
            units = units_for_style.(additional_units, style)

            def units_for(unquote(locale_name), unquote(style)) do
              unquote(Macro.escape(units))
            end
          end

          language_tag = Cldr.Config.language_tag(locale_name)
          language = Map.fetch!(language_tag, :language)

          grammatical_features = Map.get(@grammatical_features, language) || %{}
          grammatical_gender = Map.get(@grammatical_gender, language) || [@default_gender]
          default_gender = Enum.find(grammatical_gender, &(&1 == :neuter)) || @default_gender

          def grammatical_features(unquote(locale_name)) do
            unquote(Macro.escape(grammatical_features))
          end

          def grammatical_gender(unquote(locale_name)) do
            {:ok, unquote(Macro.escape(grammatical_gender))}
          end

          def default_gender(unquote(locale_name)) do
            {:ok, unquote(default_gender)}
          end

          unit_strings =
            for style <- @styles do
              additional_units = additional_units.units_for(locale_name, style)

              units =
                units_for_style.(additional_units, style)
                |> Cldr.Map.prune(fn
                  {k, _v} when k in [:per_unit_pattern, :per, :times, :unit] ->
                    true

                  {k, _v} ->
                    if String.starts_with?(Atom.to_string(k), "10"), do: true, else: false

                  _other ->
                    false
                end)
                |> Enum.map(fn {k, v} -> {k, Cldr.Map.extract_strings(v)} end)
                |> Map.new()
            end
            |> Cldr.Map.merge_map_list(&Cldr.Map.combine_list_resolver/3)
            |> Enum.map(fn {k, v} -> {k, Enum.map(v, &String.trim/1)} end)
            |> Enum.map(fn {k, v} -> {k, Enum.map(v, &String.downcase/1)} end)
            |> Enum.map(fn {k, v} -> {k, Enum.uniq(v)} end)
            |> Map.new()
            |> Cldr.Map.invert(duplicates: :keep)

          def unit_strings_for(unquote(locale_name)) do
            {:ok, unquote(Macro.escape(unit_strings))}
          end
        end

        def unit_strings_for(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
          unit_strings_for(cldr_locale_name)
        end

        def unit_strings_for(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end

        def units_for(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
          units_for(cldr_locale_name, style)
        end

        def grammatical_features(%LanguageTag{cldr_locale_name: locale_name}) do
          grammatical_features(locale_name)
        end

        def grammatical_features(locale_name) do
          {:error, Cldr.Locale.locale_error(locale_name)}
        end

        def grammatical_gender(%LanguageTag{cldr_locale_name: locale_name}) do
          grammatical_gender(locale_name)
        end

        def grammatical_gender(locale_name) do
          {:error, Cldr.Locale.locale_error(locale_name)}
        end

        def default_gender(%LanguageTag{cldr_locale_name: locale_name}) do
          default_gender(locale_name)
        end

        def default_gender(locale_name) do
          {:error, Cldr.Locale.locale_error(locale_name)}
        end
      end
    end
  end
end
