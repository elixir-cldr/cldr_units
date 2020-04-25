defmodule Cldr.Unit.Backend do
  def define_unit_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
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
        defdelegate localize(unit, usage, options), to: Cldr.Unit

        defdelegate unit_preferences, to: Cldr.Unit
        defdelegate measurement_system_for(territory), to: Cldr.Unit
        defdelegate measurement_system_for(territory, category), to: Cldr.Unit

        defdelegate known_units, to: Cldr.Unit
        defdelegate known_unit_categories, to: Cldr.Unit
        defdelegate styles, to: Cldr.Unit
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

        @doc """
        Formats a number into a string according to a unit definition for a locale.

        ## Arguments

        * `list_or_number` is any number (integer, float or Decimal) or a
          `Cldr.Unit.t()` struct or a list of `Cldr.Unit.t()` structs

        * `options` is a keyword list

        ## Options

        * `:unit` is any unit returned by `Cldr.Unit.units/1`. Ignored if
          the number to be formatted is a `Cldr.Unit.t()` struct

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.available_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`

        * `:per` allows compound units to be formatted. For example, assume
          we want to format a string which represents "kilograms per second".
          There is no such unit defined in CLDR (or perhaps anywhere!).
          If however we define the unit `unit = Cldr.Unit.new!(:kilogram, 20)`
          we can then execute `Cldr.Unit.to_string(unit, per: :second)`.
          Each locale defines a specific way to format such a compount unit.
          Usually it will return something like `20 kilograms/second`

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `{:ok, formatted_string}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string 123, unit: :gallon
            {:ok, "123 gallons"}

            iex> #{inspect(__MODULE__)}.to_string 1, unit: :gallon
            {:ok, "1 gallon"}

            iex> #{inspect(__MODULE__)}.to_string 1, unit: :gallon, locale: "af"
            {:ok, "1 gelling"}

            iex> #{inspect(__MODULE__)}.to_string 1, unit: :gallon, locale: "af-NA"
            {:ok, "1 gelling"}

            iex> #{inspect(__MODULE__)}.to_string 1, unit: :gallon, locale: "bs"
            {:ok, "1 galon"}

            iex> #{inspect(__MODULE__)}.to_string 1234, unit: :gallon, format: :long
            {:ok, "1 thousand gallons"}

            iex> #{inspect(__MODULE__)}.to_string 1234, unit: :gallon, format: :short
            {:ok, "1K gallons"}

            iex> #{inspect(__MODULE__)}.to_string 1234, unit: :megahertz
            {:ok, "1,234 megahertz"}

            iex> #{inspect(__MODULE__)}.to_string 1234, unit: :megahertz, style: :narrow
            {:ok, "1,234MHz"}

            iex> #{inspect(__MODULE__)}.to_string 123, unit: :megabyte, locale: "en", style: :unknown
            {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

            iex> #{inspect(__MODULE__)}.to_string 123, unit: :blabber, locale: "en"
            {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"blabber\\""}}

        """
        @spec to_string(
                Cldr.Math.number_or_decimal() | Cldr.Unit.t() | [Cldr.Unit.t(), ...],
                Keyword.t()
              ) ::
                {:ok, String.t()} | {:error, {atom, binary}}

        def to_string(number, options \\ []) do
          Cldr.Unit.to_string(number, unquote(backend), options)
        end

        @doc """
        Formats a list using `to_string/3` but raises if there is
        an error.

        ## Arguments

        * `list_or_number` is any number (integer, float or Decimal) or a
          `Cldr.Unit.t()` struct or a list of `Cldr.Unit.t()` structs

        * `options` is a keyword list

        ## Options

        * `:unit` is any unit returned by `Cldr.Unit.units/1`. Ignored if
          the number to be formatted is a `Cldr.Unit.t()` struct

        * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.available_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `formatted_string` or

        * raises and exception

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! 123, unit: :gallon
            "123 gallons"

            iex> #{inspect(__MODULE__)}.to_string! 1, unit: :gallon
            "1 gallon"

            iex> #{inspect(__MODULE__)}.to_string! 1, unit: :gallon, locale: "af"
            "1 gelling"

        """
        @spec to_string!(Cldr.Math.number_or_decimal(), Keyword.t()) :: String.t() | no_return()

        def to_string!(number, options \\ []) do
          Cldr.Unit.to_string!(number, unquote(backend), options)
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
          be seen with `Cldr.Config.unit_preferences/0`. The default is `nil`

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
            {:ok, [:foot], [round_nearest: 10]}
            iex> #{inspect(__MODULE__)}.preferred_units meter, locale: "en-AU", usage: :road
            {:ok, [:meter], [round_nearest: 10]}

        """
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
          be seen with `Cldr.Config.unit_preferences/0`. The default is `nil`.

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

        # Generate the functions that encapsulate the unit data from CDLR
        @doc false
        def units_for(locale \\ unquote(backend).get_locale(), style \\ Cldr.Unit.default_style())

        for locale_name <- Cldr.Config.known_locale_names(config) do
          locale_data =
            locale_name
            |> Cldr.Config.get_locale(config)
            |> Map.get(:units)

          for style <- @styles do
            units =
              Map.get(locale_data, style)
              |> Enum.map(&elem(&1, 1))
              |> Cldr.Map.merge_map_list()
              |> Enum.into(%{})

            def units_for(unquote(locale_name), unquote(style)) do
              unquote(Macro.escape(units))
            end
          end
        end

        def units_for(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
          units_for(cldr_locale_name, style)
        end
      end
    end
  end
end
