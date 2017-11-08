defmodule Cldr.Unit do
  @moduledoc """
  Supports the CLDR Units definitions which provide for the localization of many
  unit types.

  The public API defines two primary functions:

  * `Cldr.Unit.to_string/3` which, given a number and a unit name will output a localized string

  * `Cldr.Unit.available_units/0` identifies the available units for localization
  """

  require Cldr
  alias Cldr.Substitution
  alias Cldr.LanguageTag
  alias Cldr.Locale

  @unit_styles [:long, :short, :narrow]
  @default_style :long

  @doc """
  Formats a number into a string according to a unit definition for a locale.

  * `number` is any number (integer, float or Decimal)

  * `unit` is any unit returned by `Cldr.Unit.available_units/2`

  * `options` are:

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct

    * `style` is one of those returned by `Cldr.Unit.available_styles`.
      The current styles are `:long`, `:short` and `:narrow`.  The default is `style: :long`

    * Any other options are passed to `Cldr.Number.to_string/2` which is used to format the `number`

  ## Examples

      iex> Cldr.Unit.to_string 123, :gallon
      {:ok, "123 gallons"}

      iex> Cldr.Unit.to_string 1, :gallon
      {:ok, "1 gallon"}

      iex> Cldr.Unit.to_string 1, :gallon, locale: "af"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.to_string 1, :gallon, locale: "af-NA"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.to_string 1, :gallon, locale: "bs"
      {:ok, "1 galona"}

      iex> Cldr.Unit.to_string 1234, :gallon, format: :long
      {:ok, "1 thousand gallons"}

      iex> Cldr.Unit.to_string 1234, :gallon, format: :short
      {:ok, "1K gallons"}

      iex> Cldr.Unit.to_string 1234, :megahertz
      {:ok, "1,234 megahertz"}

      iex> Cldr.Unit.to_string 1234, :megahertz, style: :narrow
      {:ok, "1,234MHz"}

      iex> Cldr.Unit.to_string 123, :megabyte, locale: "en-XX"
      {:error, {Cldr.UnknownLocaleError, "The locale \\"en-XX\\" is not known."}}

      iex> Cldr.Unit.to_string 123, :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

      iex> Cldr.Unit.to_string 123, :blabber, locale: "en"
      {:error, {Cldr.UnknownUnitError, "The unit :blabber is not known."}}

  """
  @spec to_string(Cldr.Math.number_or_decimal, atom, Keyword.t) ::
    {:ok, String.t} | {:error, {atom, binary}}
  def to_string(number, unit, options \\ []) do
    with \
      {locale, style, options} <- normalize_options(options),
      {:ok, locale} <- Cldr.validate_locale(locale),
      {:ok, style} <- validate_style(style),
      {:ok, unit} <- validate_unit(locale, style, unit)
    do
      {:ok, to_string(number, unit, locale, style, options)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Formats a list using `to_string/3` but raises if there is
  an error.

  ## Examples

      iex> Cldr.Unit.to_string! 123, :gallon
      "123 gallons"

      iex> Cldr.Unit.to_string! 1, :gallon
      "1 gallon"

      iex> Cldr.Unit.to_string! 1, :gallon, locale: "af"
      "1 gelling"

  """
  @spec to_string!(List.t, atom, Keyword.t) :: String.t | Exception.t
  def to_string!(number, unit, options \\ []) do
    case to_string(number, unit, options) do
      {:error, {exception, message}} ->
        raise exception, message
      {:ok, string} ->
        string
    end
  end

  defp to_string(number, unit, locale, style, options) do
    with \
      {:ok, number_string} <- Cldr.Number.to_string(number, options ++ [locale: locale]),
      {:ok, patterns} <- pattern_for(locale, style, unit)
    do
      pattern = Cldr.Number.Ordinal.pluralize(number, locale, patterns)
      Substitution.substitute([number_string], pattern) |> :erlang.iolist_to_binary
    else
      {:error,reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the available units for a given locale and style.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct

  * `style` is one of those returned by `Cldr.Unit.available_styles`.
    The current styles are `:long`, `:short` and `:narrow`.  The default is `style: :long`

  ## Example

      Cldr.Unit.available_units
      [:acre, :acre_foot, :ampere, :arc_minute, :arc_second, :astronomical_unit, :bit,
       :bushel, :byte, :calorie, :carat, :celsius, :centiliter, :centimeter, :century,
       :cubic_centimeter, :cubic_foot, :cubic_inch, :cubic_kilometer, :cubic_meter,
       :cubic_mile, :cubic_yard, :cup, :cup_metric, :day, :deciliter, :decimeter,
       :degree, :fahrenheit, :fathom, :fluid_ounce, :foodcalorie, :foot, :furlong,
       :g_force, :gallon, :gallon_imperial, :generic, :gigabit, :gigabyte, :gigahertz,
       :gigawatt, :gram, :hectare, :hectoliter, :hectopascal, :hertz, :horsepower,
       :hour, :inch, ...]

  """
  def available_units(locale \\ Cldr.get_current_locale(), style \\ @default_style)
  def available_units(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
    available_units(cldr_locale_name, style)
  end

  @doc """
  Returns the available unit types for a given locale and style.

  * `locale` is any configured locale. See `Cldr.known_locales()`. The default
    is `locale: Cldr.get_current_locale()`

  * `style` is one of those returned by `Cldr.Unit.available_styles`.
    The current styles are `:long`, `:short` and `:narrow`.  The default is `style: :long`

  ## Example

      iex> Cldr.Unit.available_unit_types
      [:acceleration, :angle, :area, :concentr, :consumption, :coordinate, :digital,
       :duration, :electric, :energy, :frequency, :length, :light, :mass, :power,
       :pressure, :speed, :temperature, :volume]

  """
  def available_unit_types(locale \\ Cldr.get_current_locale(), style \\ @default_style)
  def available_unit_types(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
    available_unit_types(cldr_locale_name, style)
  end

  def units_for(locale \\ Cldr.get_current_locale(), style \\ @default_style)
  def units_for(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
    units_for(cldr_locale_name, style)
  end

  defp validate_style(style) when style in @unit_styles, do: {:ok, style}
  defp validate_style(style), do: {:error, style_error(style)}

  defp validate_unit(locale, style, unit) do
    if unit in available_units(locale, style) do
      {:ok, unit}
    else
      {:error, unit_error(unit)}
    end
  end

  # Generate the functions that encapsulate the unit data from CDLR
  for locale_name <- Cldr.known_locale_names() do
    locale_data =
      locale_name
      |> Cldr.Config.get_locale
      |> Map.get(:units)

    for style <- @unit_styles do
      units =
        Map.get(locale_data, style)
        |> Enum.map(fn {_k, v} -> v end)
        |> Cldr.Map.merge_map_list
        |> Enum.into(%{})

      unit_types =
        Map.get(locale_data, style)
        |> Map.keys

      def units_for(unquote(locale_name), unquote(style)) do
        unquote(Macro.escape(units))
      end

      def available_unit_types(unquote(locale_name), unquote(style)) do
        unquote(unit_types)
      end

      def available_units(unquote(locale_name), unquote(style)) do
        unquote(Map.keys(units) |> Enum.sort)
      end
    end
  end

  defp pattern_for(locale, style, unit) do
    pattern =
      locale.cldr_locale_name
      |> units_for(style)
      |> Map.get(unit)

    if pattern do
      {:ok, pattern}
    else
      {:error, Locale.locale_error(locale)}
    end
  end

  @doc """
  Returns the available styles for a unit localiation.

  ## Example

      iex> Cldr.Unit.available_styles
      [:long, :short, :narrow]

  """
  def available_styles do
    @unit_styles
  end

  defp normalize_options(options) do
    locale = options[:locale] || Cldr.get_current_locale()
    style = options[:style] || @default_style

    options =
      options
      |> Keyword.delete(:locale)
      |> Keyword.delete(:style)

    {locale, style, options}
  end

  @doc false
  def unit_error(unit) do
    {Cldr.UnknownUnitError, "The unit #{inspect unit} is not known."}
  end

  @doc false
  def style_error(style) do
    {Cldr.UnknownFormatError, "The unit style #{inspect style} is not known."}
  end

end
