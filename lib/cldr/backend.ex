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

        defdelegate units, to: Cldr.Unit
        defdelegate units(type), to: Cldr.Unit
        defdelegate unit_tree, to: Cldr.Unit
        defdelegate styles, to: Cldr.Unit
        defdelegate default_style, to: Cldr.Unit
        defdelegate validate_unit(unit), to: Cldr.Unit
        defdelegate validate_style(unit), to: Cldr.Unit
        defdelegate unit_type(unit), to: Cldr.Unit
        defdelegate jaro_match(unit), to: Cldr.Unit
        defdelegate jaro_match(unit, distance), to: Cldr.Unit
        defdelegate best_match(unit), to: Cldr.Unit
        defdelegate best_match(unit, distance), to: Cldr.Unit

        defdelegate compatible_units(unit), to: Cldr.Unit
        defdelegate compatible_units(unit, options), to: Cldr.Unit

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
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_current_locale/0`

        * `:style` is one of those returned by `Cldr.Unit.available_styles`.
          The current styles are `:long`, `:short` and `:narrow`.
          The default is `style: :long`

        * `:list_options` is a keyword list of options for formatting a list
          which is passed through to `Cldr.List.to_string/3`. This is only
          applicable when formatting a list of units.

        * Any other options are passed to `Cldr.Number.to_string/2`
          which is used to format the `number`

        ## Returns

        * `{:ok, formatted_string}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect __MODULE__}.to_string 123, unit: :gallon
            {:ok, "123 gallons"}

            iex> #{inspect __MODULE__}.to_string 1, unit: :gallon
            {:ok, "1 gallon"}

            iex> #{inspect __MODULE__}.to_string 1, unit: :gallon, locale: "af"
            {:ok, "1 gelling"}

            iex> #{inspect __MODULE__}.to_string 1, unit: :gallon, locale: "af-NA"
            {:ok, "1 gelling"}

            iex> #{inspect __MODULE__}.to_string 1, unit: :gallon, locale: "bs"
            {:ok, "1 galon"}

            iex> #{inspect __MODULE__}.to_string 1234, unit: :gallon, format: :long
            {:ok, "1 thousand gallons"}

            iex> #{inspect __MODULE__}.to_string 1234, unit: :gallon, format: :short
            {:ok, "1K gallons"}

            iex> #{inspect __MODULE__}.to_string 1234, unit: :megahertz
            {:ok, "1,234 megahertz"}

            iex> #{inspect __MODULE__}.to_string 1234, unit: :megahertz, style: :narrow
            {:ok, "1,234MHz"}

            iex> #{inspect __MODULE__}.to_string 123, unit: :megabyte, locale: "en", style: :unknown
            {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

            iex> #{inspect __MODULE__}.to_string 123, unit: :blabber, locale: "en"
            {:error, {Cldr.UnknownUnitError, "The unit :blabber is not known."}}

        """
        @spec to_string(Cldr.Math.number_or_decimal() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
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
          or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_current_locale/0`

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

            iex> #{inspect __MODULE__}.to_string! 123, unit: :gallon
            "123 gallons"

            iex> #{inspect __MODULE__}.to_string! 1, unit: :gallon
            "1 gallon"

            iex> #{inspect __MODULE__}.to_string! 1, unit: :gallon, locale: "af"
            "1 gelling"

        """
        @spec to_string!(Cldr.Math.number_or_decimal(), Keyword.t()) :: String.t() | no_return()

        def to_string!(number, options \\ []) do
          Cldr.Unit.to_string!(number, unquote(backend), options)
        end

        # Generate the functions that encapsulate the unit data from CDLR
        @doc false
        def units_for(locale \\ unquote(backend).get_locale(), style \\ Cldr.Unit.default_style)

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