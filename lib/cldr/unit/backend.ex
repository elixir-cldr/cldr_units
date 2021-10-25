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
        defdelegate localize(unit, usage, options), to: Cldr.Unit

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
          define all genders. The default gender is `#{inspect __MODULE__}.default_gender/1`
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
          define all genders. The default gender is `#{inspect __MODULE__}.default_gender/1`
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
          define all genders. The default gender is `#{inspect __MODULE__}.default_gender/1`
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
          define all genders. The default gender is `#{inspect __MODULE__}.default_gender/1`
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

          grammatical_features = Map.get(@grammatical_features, language, %{})
          grammatical_gender = Map.get(@grammatical_gender, language, [@default_gender])
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
              additional_units =
                additional_units.units_for(locale_name, style)

              units =
                units_for_style.(additional_units, style)
                |> Cldr.Map.prune(fn
                   {k, _v} when k in [:per_unit_pattern, :per, :times] ->
                     true
                   {k, _v} ->
                     if String.starts_with?(Atom.to_string(k), "10"), do: true, else: false
                   _other -> false
                end)
                |> Enum.map(fn {k, v} -> {k, Cldr.Map.extract_strings(v)} end)
                |> Map.new()
            end
            |> Cldr.Map.merge_map_list(&Cldr.Map.combine_list_resolver/3)
            |> Enum.map(fn {k, v} -> {k, Enum.map(v, &String.trim/1)} end)
            |> Enum.map(fn {k, v} -> {k, Enum.map(v, &String.downcase/1)} end)
            |> Enum.map(fn {k, v} -> {k, Enum.uniq(v)} end)
            |> Map.new
            |> Cldr.Map.invert(duplicates: :shortest)

            def unit_strings_for(unquote(locale_name)) do
              {:ok, unquote(Macro.escape(unit_strings))}
            end
        end

        def unit_strings_for(locale) when is_binary(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end

        def unit_strings_for(%LanguageTag{cldr_locale_name: cldr_locale_name}) do
          unit_strings_for(cldr_locale_name)
        end

        def units_for(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
          units_for(cldr_locale_name, style)
        end

        def grammatical_features(%LanguageTag{language: language}) do
          grammatical_features(language)
        end

        def grammatical_features(language) do
          {:error, Cldr.Locale.locale_error(language)}
        end

        def grammatical_gender(%LanguageTag{language: language}) do
          grammatical_gender(language)
        end

        def grammatical_gender(language) do
          {:error, Cldr.Locale.locale_error(language)}
        end

        def default_gender(%LanguageTag{language: language}) do
          default_gender(language)
        end

        def default_gender(language) do
          {:error, Cldr.Locale.locale_error(language)}
        end
      end
    end
  end
end
