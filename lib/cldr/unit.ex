defmodule Cldr.Unit do
  @moduledoc """
  Supports the CLDR Units definitions which provide for the localization of many
  unit types.

  The primary public API defines:

  * `Cldr.Unit.to_string/3` which, given a unit or unit list will
    output a localized string

  * `Cldr.Unit.known_units/0` identifies the available units for localization

  * `Cldr.Unit.{add, sub, mult, div}/2` to support basic unit mathematics between
    units of compatible type (like length or volume)

  * `Cldr.Unit.compare/2` to compare one unit to another unit as long as they
    are convertable.

  * `Cldr.Unit.convert/2` to convert one unit to another unit as long as they
    are convertable.

  * `Cldr.Unit.localize/3` will convert a unit into the units preferred for a
    given locale and usage

  * `Cldr.Unit.preferred_units/3` which, for a given unit and locale,
    will return a list of preferred units that can be applied to
    `Cldr.Unit.decompose/2`

  * `Cldr.Unit.decompose/2` to take a unit and return a list of units decomposed
    by a list of smaller units.

  """

  alias Cldr.Unit
  alias Cldr.{Locale, LanguageTag, Substitution}
  alias Cldr.Unit.{Math, Alias, Parser, Conversion, Conversions, Preference, Prefix}

  @enforce_keys [:unit, :value, :base_conversion, :usage, :format_options]

  defstruct unit: nil,
            value: 0,
            base_conversion: [],
            usage: :default,
            format_options: []

  @type translatable_unit :: atom()
  @type unit :: translatable_unit | String.t()
  @type category :: atom()
  @type usage :: atom()
  @type measurement_system :: :metric | :ussystem | :uksystem
  @type style :: :narrow | :short | :long
  @type value :: Cldr.Math.number_or_decimal() | Ratio.t()
  @type conversion :: Conversion.t() | {[Conversion.t(), ...], [Conversion.t(), ...]} | list()
  @type locale :: Locale.locale_name() | LanguageTag.t()

  @type t :: %__MODULE__{
          unit: unit(),
          value: value(),
          base_conversion: conversion(),
          usage: usage(),
          format_options: []
        }

  @default_style :long
  @styles [:long, :short, :narrow]

  defdelegate convert(unit_1, to_unit), to: Conversion
  defdelegate convert!(unit_1, to_unit), to: Conversion

  defdelegate preferred_units(unit, backend, options), to: Preference
  defdelegate preferred_units!(unit, backend, options), to: Preference

  defdelegate add(unit_1, unit_2), to: Math
  defdelegate sub(unit_1, unit_2), to: Math
  defdelegate mult(unit_1, unit_2), to: Math
  defdelegate div(unit_1, unit_2), to: Math

  defdelegate add!(unit_1, unit_2), to: Math
  defdelegate sub!(unit_1, unit_2), to: Math
  defdelegate mult!(unit_1, unit_2), to: Math
  defdelegate div!(unit_1, unit_2), to: Math

  defdelegate round(unit, places, mode), to: Math
  defdelegate round(unit, places), to: Math
  defdelegate round(unit), to: Math

  defdelegate compare(unit_1, unit_2), to: Math

  @app_name Cldr.Config.app_name()
  @data_dir [:code.priv_dir(@app_name), "/cldr/locales"] |> :erlang.iolist_to_binary()
  @config %{data_dir: @data_dir, locales: ["en"], default_locale: "en"}

  @units Cldr.Config.units()

  @unit_tree "en"
             |> Cldr.Config.get_locale(@config)
             |> Map.get(:units)
             |> Map.get(:short)
             |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
             |> Map.new()

  @units_by_category @unit_tree
                     |> Map.delete(:compound)
                     |> Map.delete(:coordinate)

  @unit_categories Map.keys(@units_by_category) -- [:"10p", :compound, :coordinate]

  @translatable_units @units_by_category
                      |> Map.values()
                      |> List.flatten()
                      |> List.delete(:generic)

  @measurement_systems Cldr.Config.measurement_systems()
  @system_names Map.keys(@measurement_systems)

  @doc """
  Returns the known units.

  Known units means units that can
  be localised directly.

  ## Example

      => Cldr.Unit.known_units
      [:acre, :acre_foot, :ampere, :arc_minute, :arc_second, :astronomical_unit, :bit,
       :bushel, :byte, :calorie, :carat, :celsius, :centiliter, :centimeter, :century,
       :cubic_centimeter, :cubic_foot, :cubic_inch, :cubic_kilometer, :cubic_meter,
       :cubic_mile, :cubic_yard, :cup, :cup_metric, :day, :deciliter, :decimeter,
       :degree, :fahrenheit, :fathom, :fluid_ounce, :foodcalorie, :foot, :furlong,
       :g_force, :gallon, :gallon_imperial, :generic, :gigabit, :gigabyte, :gigahertz,
       :gigawatt, :gram, :hectare, :hectoliter, :hectopascal, :hertz, :horsepower,
       :hour, :inch, ...]

  """

  @spec known_units :: [translatable_unit(), ...]
  def known_units do
    @translatable_units
  end

  @deprecated "Use Cldr.Unit.known_units/0"
  def units, do: known_units()

  @doc """
  Returns a list of the known unit categories.

  ## Example

      iex> Cldr.Unit.known_unit_categories
      [:acceleration, :angle, :area, :concentr, :consumption, :digital,
       :duration, :electric, :energy, :force, :frequency, :graphics, :length, :light, :mass,
       :power, :pressure, :speed, :temperature, :torque, :volume]

  """
  @spec known_unit_categories :: list(category())
  def known_unit_categories do
    @unit_categories
  end

  @doc """
  Returns the units that are defined for
  a given category (such as :volume, :length)

  See also `Cldr.Unit.known_unit_categories/0`.

  ## Example

      => Cldr.Unit.known_units_by_category
      %{
        acceleration: [:g_force, :meter_per_square_second],
        angle: [:arc_minute, :arc_second, :degree, :radian, :revolution],
        area: [:acre, :dunam, :hectare, :square_centimeter, :square_foot,
         :square_inch, :square_kilometer, :square_meter, :square_mile, :square_yard],
        concentr: [:karat, :milligram_per_deciliter, :millimole_per_liter, :mole,
         :percent, :permille, :permillion, :permyriad], ...
       }

  """
  @doc since: "3.4.0"
  @spec known_units_by_category :: %{category() => [translatable_unit(), ...]}

  def known_units_by_category do
    @units_by_category
  end

  @doc """
  Returns the list of units defined for a given
  category.

  ## Arguments

  * `category` is any unit category returned by
    `Cldr.Unit.known_unit_categories/0`.

  * `options` is a keyword list of options. The
    default is `[]`.

  See also `Cldr.Unit.known_units_by_category/1`.

  ## Example

      => Cldr.Unit.known_units_for_category :volume
      {
        :ok,
        [
          :cubic_centimeter,
          :centiliter,
          :hectoliter,
          :cubic_kilometer,
          :acre_foot,
          ...
        ]
      }

  """
  @doc since: "3.4.0"
  @spec known_units_for_category(category()) ::
          {:ok, [atom(), ...]} | {:error, {module(), String.t()}}

  def known_units_for_category(category) when category in @unit_categories do
    with {:ok, units} <- Map.fetch(known_units_by_category(), category) do
      {:ok, units}
    end
  end

  def known_units_for_category(category) do
    {:error, unit_category_error(category)}
  end

  @doc """
  Returns a new `Unit.t` struct.

  ## Arguments

  * `value` is any float, integer, `Ratio` or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.known_units/0`

  * `options` is Keyword list of options. The default
    is `[]`

  ## Options

  * `:usage` is the intended use of the unit. This
    is used during localization to convert the unit
    to that appropriate for the unit category,
    usage, target territory and unit value. The `:use`
    must be known for the unit's category. See
    `Cldr.Unit` for more information.

  ## Returns

  * `unit` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.new(23, :gallon)
      {:ok, Cldr.Unit.new!(:gallon, 23)}

      iex> Cldr.Unit.new(:gallon, 23)
      {:ok, Cldr.Unit.new!(:gallon, 23)}

      iex> Cldr.Unit.new(14, :gadzoots)
      {:error, {Cldr.UnknownUnitError,
        "Unknown unit was detected at \\"gadzoots\\""}}

      iex> Cldr.Unit.new(:gallon, 23, usage: :fluid)

      iex> Cldr.Unit.new(:gallon, 23, usage: "fluid")

  """
  @spec new(unit() | value(), value() | unit(), Keyword.t()) ::
          {:ok, t()} | {:error, {module(), String.t()}}

  def new(value, unit, options \\ [])

  def new(value, unit, options) when is_number(value) do
    create_unit(value, unit, options)
  end

  def new(unit, value, options) when is_number(value) do
    new(value, unit, options)
  end

  def new(%Decimal{} = value, unit, options) do
    create_unit(value, unit, options)
  end

  def new(unit, %Decimal{} = value, options) do
    new(value, unit, options)
  end

  def new(%Ratio{} = value, unit, options) do
    create_unit(value, unit, options)
  end

  def new(unit, %Ratio{} = value, options) do
    new(value, unit, options)
  end

  @default_use :default
  @default_format_options []

  defp create_unit(value, unit, options) do
    usage = Keyword.get(options, :usage, @default_use)
    format_options = Keyword.get(options, :format_options, @default_format_options)

    with {:ok, unit, base_conversion} <- validate_unit(unit),
         {:ok, usage} <- validate_usage(unit, usage) do
      unit = %Unit{
        unit: unit,
        value: value,
        base_conversion: base_conversion,
        usage: usage,
        format_options: format_options
      }

      {:ok, unit}
    end
  end

  defp validate_usage(unit, usage) do
    with {:ok, category} <- unit_category(unit) do
      validate_category_usage(category, usage)
    end
  end

  defp validate_category_usage(:substance_amount, _) do
    {:ok, nil}
  end

  @default_category_usage [@default_use]
  defp validate_category_usage(category, usage) when is_atom(usage) do
    usage_list = Map.get(unit_category_usage(), category, @default_category_usage)

    if usage in usage_list do
      {:ok, usage}
    else
      {:error, unknown_usage_error(category, usage)}
    end
  end

  defp validate_category_usage(category, "") do
    validate_category_usage(category, @default_use)
  end

  defp validate_category_usage(category, usage) when is_binary(usage) do
    atom_usage = String.to_existing_atom(usage)
    validate_category_usage(category, atom_usage)
  rescue
    ArgumentError ->
      {:error, unknown_usage_error(category, usage)}
  end

  @doc """
  Returns a new `Unit.t` struct or raises on error.

  ## Arguments

  * `value` is any float, integer or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.known_units/0`

  ## Returns

  * `unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.new! 23, :gallon
      #Cldr.Unit<:gallon, 23>

      Cldr.Unit.new! 14, :gadzoots
      ** (Cldr.UnknownUnitError) The unit :gadzoots is not known.
          (ex_cldr_units) lib/cldr/unit.ex:57: Cldr.Unit.new!/2

  """
  @spec new!(unit() | value(), value() | unit()) :: t() | no_return()

  def new!(unit, value, options \\ []) do
    case new(unit, value, options) do
      {:ok, unit} -> unit
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @doc """
  Returns a boolean indicating if two units are
  of the same unit category.

  ## Arguments

  * `unit_1` and `unit_2` are any units returned by
    `Cldr.Unit.new/2` or a valid unit name.

  ## Returns

  * `true` or `false`

  ## Examples

      iex> Cldr.Unit.compatible? :foot, :meter
      true

      iex> Cldr.Unit.compatible? Cldr.Unit.new!(:foot, 23), :meter
      true

      iex> Cldr.Unit.compatible? :foot, :liter
      false

      iex> Cldr.Unit.compatible? "light_year_per_second", "meter_per_gallon"
      false

  """
  @spec compatible?(t() | unit(), t() | unit()) :: boolean
  def compatible?(unit_1, unit_2) do
    with {:ok, _unit_1, conversion_1} <- validate_unit(unit_1),
         {:ok, _unit_2, conversion_2} <- validate_unit(unit_2),
         {:ok, base_unit_1} <- base_unit(conversion_1),
         {:ok, base_unit_2} <- base_unit(conversion_2) do
      Kernel.to_string(base_unit_1) == Kernel.to_string(base_unit_2)
    else
      _ -> false
    end
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string/3` for full details.

  """
  @spec to_string(list_or_number :: value | t() | [t()]) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    to_string(unit, backend, locale: locale)
  end

  @doc """
  Formats a number into a string according to a unit definition for a locale.

  During processing any `:format_options` of a `Unit.t()` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `list_or_number` is any number (integer, float or Decimal) or a
    `Cldr.Unit.t()` struct or a list of `Cldr.Unit.t()` structs

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options.

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `Cldr.Unit.t()` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.styles`.
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

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:gallon, 123), MyApp.Cldr
      {:ok, "123 gallons"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:gallon, 1), MyApp.Cldr
      {:ok, "1 gallon"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:gallon, 1), MyApp.Cldr, locale: "af"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:gallon, 1), MyApp.Cldr, locale: "bs"
      {:ok, "1 galon"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:gallon, 1234), MyApp.Cldr, format: :long
      {:ok, "1 thousand gallons"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:gallon, 1234), MyApp.Cldr, format: :short
      {:ok, "1K gallons"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:megahertz, 1234), MyApp.Cldr
      {:ok, "1,234 megahertz"}

      iex> Cldr.Unit.to_string Cldr.Unit.new!(:megahertz, 1234), MyApp.Cldr, style: :narrow
      {:ok, "1,234MHz"}

      iex> unit = Cldr.Unit.new!(123, :foot)
      iex> Cldr.Unit.to_string unit, MyApp.Cldr
      {:ok, "123 feet"}

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :foot
      {:ok, "123 feet"}

      iex> Cldr.Unit.to_string Decimal.new(123), MyApp.Cldr, unit: :foot
      {:ok, "123 feet"}

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

  """

  @spec to_string(value | t() | list(t()), Cldr.backend() | Keyword.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(list_or_unit, backend, options \\ [])

  # Options but no backend
  def to_string(list_or_unit, options, []) when is_list(options) do
    locale = Cldr.get_locale()
    to_string(list_or_unit, locale.backend, options)
  end

  # It's a list of units so we format each of them
  # and combine the list
  def to_string(unit_list, backend, options) when is_list(unit_list) do
    with {locale, _style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale) do
      options =
        options
        |> Keyword.put(:locale, locale)

      list_options =
        options
        |> Keyword.get(:list_options, [])
        |> Keyword.put(:locale, locale)

      unit_list
      |> Enum.map(&to_string!(&1, backend, options))
      |> Cldr.List.to_string(backend, list_options)
    end
  end

  # It's a number, not a unit struct
  def to_string(number, backend, options) when is_number(number) do
    with {:ok, unit} <- new(options[:unit], number) do
      to_string(unit, backend, options)
    end
  end

  def to_string(%Decimal{} = number, backend, options) do
    with {:ok, unit} <- new(options[:unit], number) do
      to_string(unit, backend, options)
    end
  end

  # Now we have a unit, a backend and some options but ratio
  # values need to be converted to floats
  def to_string(%Unit{value: %Ratio{}} = unit, backend, options) when is_list(options) do
    unit = ratio_to_float(unit)
    to_string(unit, backend, options)
  end

  def to_string(%Unit{} = unit, backend, options) when is_list(options) do
    with {:ok, list} <- to_iolist(unit, backend, options) do
      list
      |> :erlang.iolist_to_binary()
      |> String.replace(~r/([\s])+/, "\\1")
      |> wrap(:ok)
    end
  end

  @doc """
  Formats a number into a iolist according to a unit definition
  for the current process's locale and backend.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_iolist/3` for full details.

  """
  @spec to_iolist(list_or_number :: value | t() | [t()]) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_iolist(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    to_iolist(unit, backend, locale: locale)
  end

  @doc """
  Formats a number into an `iolist` according to a unit definition
  for a locale.

  During processing any `:format_options` of a `Unit.t()` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `list_or_number` is any number (integer, float or Decimal) or a
    `Cldr.Unit.t()` struct or a list of `Cldr.Unit.t()` structs

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options.

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `Cldr.Unit.t()` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * `:list_options` is a keyword list of options for formatting a list
    which is passed through to `Cldr.List.to_string/3`. This is only
    applicable when formatting a list of units.

  * Any other options are passed to `Cldr.Number.to_string/2`
    which is used to format the `number`

  ## Returns

  * `{:ok, io_list}` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.to_iolist Cldr.Unit.new!(:gallon, 123), MyApp.Cldr
      {:ok, ["123", " gallons"]}

      iex> Cldr.Unit.to_iolist 123, MyApp.Cldr, unit: :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

  """
  @spec to_iolist(value() | t(), Cldr.backend() | Keyword.t(), Keyword.t()) ::
          {:ok, list()} | {:error, {module, binary}}

  def to_iolist(unit, backend, options \\ [])

  # Options but no backend
  def to_iolist(unit, options, []) when is_list(options) do
    locale = Cldr.get_locale()
    to_iolist(unit, locale.backend, options)
  end

  def to_iolist(%Unit{} = unit, backend, options) when is_list(options) do
    with {locale, style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale),
         {:ok, style} <- validate_style(style) do
      number = value(unit)

      options =
        unit.format_options
        |> Keyword.merge(options)
        |> Keyword.put(:locale, locale)

      {:ok, number_string} = Cldr.Number.to_string(number, backend, options)

      number
      |> extract_patterns(unit.base_conversion, locale, style, backend, options)
      |> combine_patterns(number_string, locale, style, backend, options)
      |> maybe_combine_per_unit(locale, style, backend, options)
      |> wrap(:ok)
    end
  end

  def to_iolist(number, backend, options) when is_number(number) do
    with {:ok, unit} <- new(options[:unit], number) do
      to_iolist(unit, backend, options)
    end
  end

  defp wrap(term, tag) do
    {tag, term}
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string!/3` for full details.

  """
  @spec to_string!(list_or_number :: value() | t() | [t()]) ::
          String.t() | no_return()

  def to_string!(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    to_string!(unit, backend, locale: locale)
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  During processing any `:format_options` of a `Unit.t()` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `number` is any number (integer, float or Decimal) or a
    `Cldr.Unit.t()` struct

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `Cldr.Unit.t()` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.available_styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * Any other options are passed to `Cldr.Number.to_string/2`
    which is used to format the `number`

  ## Returns

  * `formatted_string` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.to_string! Cldr.Unit.new!(:gallon, 123), MyApp.Cldr
      "123 gallons"

      iex> Cldr.Unit.to_string! Cldr.Unit.new!(:gallon, 1), MyApp.Cldr
      "1 gallon"

      iex> Cldr.Unit.to_string! Cldr.Unit.new!(:gallon, 1), MyApp.Cldr, locale: "af"
      "1 gelling"

  """
  @spec to_string!(value() | t() | list(t()), Cldr.backend() | Keyword.t(), Keyword.t()) ::
          String.t() | no_return()

  def to_string!(unit, backend, options \\ []) do
    case to_string(unit, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @doc """
  Formats a number into an iolist according to a unit definition
  for the current process's locale and backend or raises
  on error.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_iolist!/3` for full details.

  """
  @spec to_iolist!(list_or_number :: value | t() | [t()]) ::
          list() | no_return()

  def to_iolist!(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    to_iolist!(unit, backend, locale: locale)
  end

  @doc """
  Formats a number into an iolist according to a unit definition
  for the current process's locale and backend or raises
  on error.

  During processing any `:format_options` of a `Unit.t()` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `number` is any number (integer, float or Decimal) or a
    `Cldr.Unit.t()` struct

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `Cldr.Unit.t()` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.available_styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * Any other options are passed to `Cldr.Number.to_string/2`
    which is used to format the `number`

  ## Returns

  * `io_list` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.to_iolist! Cldr.Unit.new!(:gallon, 123), MyApp.Cldr
      ["123", " gallons"]

  """
  @spec to_iolist!(value() | t(), Cldr.backend() | Keyword.t(), Keyword.t()) ::
          list() | no_return()

  def to_iolist!(unit, backend, options \\ []) do
    case to_iolist(unit, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @dialyzer {:nowarn_function, {:extract_patterns, 6}}
  defp extract_patterns(number, {unit_list, per_list}, locale, style, backend, options) do
    {
      extract_patterns(number, unit_list, locale, style, backend, options),
      extract_patterns(1, per_list, locale, style, backend, options)
    }
  end

  # When extracting a list of patterns the objective is to use the singluar
  # form of the pattern for all except the last element which uses the
  # plural form indicated by the number
  defp extract_patterns(number, [{unit, _conversion}], locale, style, backend, options) do
    [to_pattern(number, unit, locale, style, backend, options)]
  end

  defp extract_patterns(number, [{unit, _conversion} | rest], locale, style, backend, options) do
    [
      to_pattern(1, unit, locale, style, backend, options)
      | extract_patterns(number, rest, locale, style, backend, options)
    ]
  end

  # Combine the patterns merging prefix and units, applying "times" for
  # compound units and the "per" pattern if required.  This are some heuristics
  # here than may not result in a grammatically correct result for some
  # languages
  @dialyzer {:nowarn_function, {:combine_patterns, 6}}
  defp combine_patterns({patterns, per_patterns}, number_string, locale, style, backend, options) do
    {
      combine_patterns(patterns, number_string, locale, style, backend, options),
      combine_patterns(per_patterns, "", locale, style, backend, options)
    }
  end

  defp combine_patterns([pattern], number_string, _locale, _style, _backend, _options) do
    Substitution.substitute(number_string, pattern)
  end

  defp combine_patterns([pattern | rest], number_string, locale, style, backend, _options) do
    units = units_for(locale, style, backend)
    times_pattern = get_in(units, [:times, :compound_unit_pattern])

    [
      Substitution.substitute(number_string, pattern)
      | Enum.map(rest, fn p ->
          Substitution.substitute("", p)
          |> Enum.map(&String.trim/1)
        end)
    ]
    |> join_list(times_pattern)
  end

  defp join_list([head, tail], times_pattern) do
    Substitution.substitute([head, tail], times_pattern)
  end

  defp join_list([head | rest], times_pattern) do
    tail = join_list(rest, times_pattern)
    join_list([head, tail], times_pattern)
  end

  @dialyzer {:nowarn_function, {:maybe_combine_per_unit, 5}}
  defp maybe_combine_per_unit({unit_list, per_units}, locale, style, backend, _options) do
    units = units_for(locale, style, backend)
    per_pattern = get_in(units, [:per, :compound_unit_pattern])

    Substitution.substitute([unit_list, per_units], per_pattern)
  end

  defp maybe_combine_per_unit(unit_list, _locale, _style, _backend, _options) do
    unit_list
  end

  @spec to_pattern(value(), unit(), locale(), style(), Cldr.backend(), Keyword.t()) ::
          list()

  defp to_pattern(number, unit, locale, style, backend, _options)
       when unit in @translatable_units do
    {:ok, patterns} = pattern_for(locale, style, unit, backend)
    cardinal_module = Module.concat(backend, Number.Cardinal)
    cardinal_module.pluralize(number, locale, patterns)
  end

  for {prefix, power} <- Prefix.power_units() do
    localize_key = String.to_atom("power#{power}")
    match = quote do: <<unquote(prefix), "_", var!(unit)::binary>>

    defp to_pattern(number, unquote(match), locale, style, backend, options) do
      units = units_for(locale, style, backend)
      pattern = get_in(units, [unquote(localize_key), :compound_unit_pattern1])
      unit = maybe_translatable_unit(unit)

      pattern
      |> merge_power_prefix(to_pattern(number, unit, locale, style, backend, options))
    end
  end

  # is there an SI prefix? If so, try reformatting the unit again
  for {prefix, power} <- Prefix.si_power_prefixes() do
    localize_key = "10p#{power}" |> String.replace("-", "_") |> String.to_atom()
    match = quote do: <<unquote(prefix), var!(unit)::binary>>

    defp to_pattern(number, unquote(match), locale, style, backend, options) do
      units = units_for(locale, style, backend)
      pattern = get_in(units, [unquote(localize_key), :unit_prefix_pattern])
      unit = maybe_translatable_unit(unit)

      pattern
      |> merge_SI_prefix(to_pattern(number, unit, locale, style, backend, options))
    end
  end

  # Merging power and SI prefixes into a pattern is a heuristic since the
  # underlying data does not convey those rules.

  @merge_SI_prefix ~r/([^\s]+)$/u
  defp merge_SI_prefix([prefix, place], [place, string]) when is_integer(place) do
    [place, String.replace(string, @merge_SI_prefix, "#{prefix}\\1")]
  end

  defp merge_SI_prefix([prefix, place], [string, place]) when is_integer(place) do
    [String.replace(string, @merge_SI_prefix, "#{prefix}\\1"), place]
  end

  defp merge_SI_prefix([place, prefix], [place, string]) when is_integer(place) do
    [place, String.replace(string, @merge_SI_prefix, "#{prefix}\\1")]
  end

  defp merge_SI_prefix([place, prefix], [string, place]) when is_integer(place) do
    [String.replace(string, @merge_SI_prefix, "#{prefix}\\1"), place]
  end

  @merge_power_prefix ~r/^(\s)+/u
  defp merge_power_prefix([prefix, place], [place, string]) when is_integer(place) do
    [place, String.replace(string, @merge_power_prefix, "\\1#{prefix}")]
  end

  defp merge_power_prefix([prefix, place], [string, place]) when is_integer(place) do
    [String.replace(string, @merge_power_prefix, "\\1#{prefix}"), place]
  end

  defp merge_power_prefix([place, prefix], [place, string]) when is_integer(place) do
    [place, String.replace(string, @merge_power_prefix, "\\1#{prefix}")]
  end

  defp merge_power_prefix([place, prefix], [string, place]) when is_integer(place) do
    [String.replace(string, @merge_power_prefix, "\\1#{prefix}"), place]
  end

  @doc """
  Return the value of the Unit struct

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Returns

  * an integer, float or Decimal representing the amount
  of the unit

  ## Example

      iex> Cldr.Unit.value Cldr.Unit.new!(:kilogram, 23)
      23

  """
  @spec value(unit :: t()) :: value()
  def value(%Unit{value: value}) do
    value
  end

  @doc """
  Decomposes a unit into subunits.

  Any list compatible units can be provided
  however a list of units of decreasing scale
  is recommended.  For example `[:foot, :inch]`
  or `[:kilometer, :meter, :centimeter, :millimeter]`

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `unit_list` is a list of valid units (one or
    more from the list returned by `Cldr.Unit.known_units/0`. All
    units must be from the same unit category.

  * `format_options` is a Keyword list of options
    that is added to the *last* unit in `unit_list`.
    The `format_options` will be applied when calling
    `Cldr.Unit.to_string/3` on the `unit`. The
    default is `[]`.

  ## Returns

  * a list of units after decomposition or an error
    tuple

  ## Examples

      iex> u = Cldr.Unit.new!(10.3, :foot)
      iex> Cldr.Unit.decompose u, [:foot, :inch]
      [Cldr.Unit.new!(:foot, 10), Cldr.Unit.new!(:inch, Ratio.new(18, 5))]

      iex> u = Cldr.Unit.new!(:centimeter, 1111)
      iex> Cldr.Unit.decompose u, [:kilometer, :meter, :centimeter, :millimeter]
      [Cldr.Unit.new!(:meter, 11), Cldr.Unit.new!(:centimeter, 11)]

  """
  @spec decompose(unit :: Unit.t(), unit_list :: [Unit.unit()], options :: Keyword.t()) ::
          [Unit.t()]

  def decompose(unit, unit_list, format_options \\ [])

  def decompose(unit, [], _format_options) do
    [unit]
  end

  # This is the last unit
  def decompose(unit, [h | []], format_options) do
    new_unit = Conversion.convert!(unit, h)

    if zero?(new_unit) do
      []
    else
      [%{new_unit | format_options: format_options}]
    end
  end

  def decompose(unit, [h | t], format_options) do
    new_unit = Conversion.convert!(unit, h)
    {integer_unit, remainder} = int_rem(new_unit)

    if zero?(integer_unit) do
      decompose(remainder, t, format_options)
    else
      [integer_unit | decompose(remainder, t, format_options)]
    end
  end

  @doc """
  Localizes a unit according to the current
  processes locale and backend.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.localize/3` for futher
  details.

  """
  def localize(%Unit{} = unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    localize(unit, backend, locale: locale)
  end

  @doc """
  Localizes a unit according to a territory

  A territory can be derived from a `locale_name`
  or `Cldr.LangaugeTag.t()`.

  Use this function if you have a unit which
  should be presented in a user interface using
  units relevant to the audience. For example, a
  unit `#Cldr.Unit100, :meter>` might be better
  presented to a US audiance as `#Cldr.Unit328, :foot>`.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module.

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
      iex> Cldr.Unit.localize(unit, usage: :person_height, territory: :US)
      [Cldr.Unit.new!(:foot, 6), Cldr.Unit.new!(:inch, Ratio.new(6485183463413016, 137269716642252725))]

  """

  def localize(unit, backend, options \\ [])

  def localize(%Unit{} = unit, options, []) when is_list(options) do
    locale = Cldr.get_locale()
    options = Keyword.merge([locale: locale], options)
    localize(unit, locale.backend, options)
  end

  def localize(%Unit{} = unit, backend, options) when is_atom(backend) do
    with {:ok, unit_list, format_options} <- Preference.preferred_units(unit, backend, options) do
      decompose(unit, unit_list, format_options)
    end
  end

  @doc """
  Returns the localized display name
  for a unit.

  The returned text is generally suitable
  for including in UI elements such as
  selection boxes.

  ## Arguments

  * `unit` is any `Cldr.Unit.t` or any
    unit name returned by `Cldr.Unit.known_units/0`.

  * `options` is a keyword list of options.

  ## Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:style` is one of those returned by `Cldr.Unit.available_styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`.

  ## Examples

      iex> Cldr.Unit.display_name :liter
      "liters"

      iex> Cldr.Unit.display_name :liter, locale: "fr"
      "litres"

      iex> Cldr.Unit.display_name :liter, locale: "fr", style: :short
      "l"

  """
  def display_name(unit, options \\ [])

  def display_name(%Unit{unit: unit}, options) do
    display_name(unit, options)
  end

  def display_name(unit, options) when unit in @translatable_units do
    style = Keyword.get(options, :style, @default_style)
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, style} <- validate_style(style) do
       locale
       |> units_for(style, backend)
       |> Map.fetch!(unit)
       |> Map.fetch!(:display_name)
    end
  end

  def display_name(unit, _options) do
    {:error, unit_error(unit)}
  end

  @doc """
  Returns a new unit of the same unit
  type but with a zero value.

  ## Argument

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Example

      iex> u = Cldr.Unit.new!(:foot, 23.3)
      #Cldr.Unit<:foot, 23.3>
      iex> Cldr.Unit.zero(u)
      #Cldr.Unit<:foot, 0.0>

  """
  def zero(%Unit{value: value} = unit) when is_integer(value) do
    %Unit{unit | value: 0}
  end

  def zero(%Unit{value: value} = unit) when is_float(value) do
    %Unit{unit | value: 0.0}
  end

  def zero(%Unit{} = unit) do
    %Unit{unit | value: Decimal.new(0)}
  end

  @doc """
  Returns a boolean indicating whether a given unit
  has a zero value.

  ## Argument

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Examples

      iex> u = Cldr.Unit.new!(:foot, 23.3)
      #Cldr.Unit<:foot, 23.3>
      iex> Cldr.Unit.zero?(u)
      false

      iex> u = Cldr.Unit.new!(:foot, 0)
      #Cldr.Unit<:foot, 0>
      iex> Cldr.Unit.zero?(u)
      true

  """
  def zero?(%Unit{value: value}) when is_number(value) do
    value == 0
  end

  @decimal_0 Decimal.new(0)
  def zero?(%Unit{value: %Decimal{} = value}) do
    Cldr.Decimal.compare(value, @decimal_0) == :eq
  end

  # Ratios that are zero are just integers
  # so anything that is a %Ratio{} is not zero
  def zero?(%Unit{value: %Ratio{}}) do
    false
  end

  @system_units @units
                |> Map.get(:conversions)
                |> Enum.flat_map(fn {unit, conversion} ->
                  Enum.map(conversion.systems, fn system -> {system, unit} end)
                end)
                |> Enum.group_by(fn {system, _unit} -> system end, fn {_system, unit} ->
                  unit
                end)

  @doc """
  Returns the list of units defined in a given
  measurement system.

  ## Arguments

  * `system` is any measurement system returned by
    `Cldr.Unit.known_measurement_systems/0`

  ## Returns

  * A list of translatable units as atoms or

  * `{:error, {exception, message}}`

  ## Example

      => Cldr.Unit.measurement_system_units :uksystem
      [
        :ton,
        :inch,
        :yard,
        ...
      ]

  """
  @doc since: "3.4.0"
  @spec measurement_system_units(measurement_system()) ::
    [translatable_unit(), ...] | {:error, {module(), String.t()}}

  def measurement_system_units(system) when system in @system_names do
    Map.get(@system_units, system)
  end

  def measurement_system_units(system) do
    {:error, unknown_measurement_system_error(system)}
  end

  @doc """
  Returns a boolean indicating if a given
  unit belongs to one or more measurement
  systems.

  When a list or more than one measurement
  system is provided, the test is one of
  inclusion. That is, if the unit belongs to
  any of the provided measurement systems
  the return is `true`.

  ## Arguments

  * `system` is any measurement system or list
    of measurement systems returned by
    `Cldr.Unit.known_measurement_systems/0`

  ## Returns

  * `true` or `false` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.measurement_system? :foot, :uksystem
      true

      iex> Cldr.Unit.measurement_system? :foot, [:uksystem, :ussystem]
      true

      iex> Cldr.Unit.measurement_system? :foot, [:metric]
      false

      iex> Cldr.Unit.measurement_system? :invalid, [:metric]
      {:error, {Cldr.UnknownUnitError, "The unit :invalid is not known."}}

  """
  @doc since: "3.4.0"
  @spec measurement_system?(t() | unit, measurement_system | list(measurement_system)) ::
    boolean() | {:error, {module(), String.t()}}

  def measurement_system?(unit, system) when is_atom(system) do
    measurement_system?(unit, [system])
  end

  def measurement_system?(%Unit{unit: unit}, systems) when is_list(systems) do
    measurement_system?(unit, systems)
  end

  def measurement_system?(unit, systems) when unit in @translatable_units and is_list(systems) do
    Enum.any?(measurement_systems_for_unit(unit), &(&1 in systems))
  end

  def measurement_system?(_unit, systems) when not is_list(systems) do
    {:error, unknown_measurement_system_error(systems)}
  end

  def measurement_system?(unit, _systems) do
    {:error, unit_error(unit)}
  end

  @systems_for_unit @units
                |> Map.get(:conversions)
                |> Enum.map(fn {unit, conversion} ->{unit, conversion.systems} end)
                |> Map.new

  @doc """
  Returns the measurement systems for a given
  unit.

  ## Arguments

  * `unit` is any `Cldr.Unit.t` or a unit
    name as an atom or string

  ## Returns

  * A list of measurement systems to which
    the `unit` belongs

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.measurement_systems_for_unit :foot
      [:ussystem, :uksystem]

      iex> Cldr.Unit.measurement_systems_for_unit :meter
      [:metric]

      iex> Cldr.Unit.measurement_systems_for_unit :invalid
      {:error, {Cldr.UnknownUnitError, "The unit :invalid is not known."}}

  """
  @doc since: "3.4.0"
  @spec measurement_systems_for_unit(t() | String.t()) ::
    [measurement_system(), ...] | {:error, {module(), String.t()}}

  def measurement_systems_for_unit(%Unit{unit: unit}) do
    measurement_systems_for_unit(unit)
  end

  def measurement_systems_for_unit(unit) when unit in @translatable_units do
    case Map.fetch(@systems_for_unit, unit) do
      {:ok, systems} -> systems
      :error -> measurement_systems_for_unit(Kernel.to_string(unit))
    end
  end

  # Strip SI and power factors amd try the root
  # unit
  for prefix <- Cldr.Unit.Prefix.prefixes do
    def measurement_systems_for_unit(unquote(prefix) <> unit) do
      with {:ok, unit, _conversion} <- Cldr.Unit.validate_unit(unit) do
        measurement_systems_for_unit(unit)
      end
    end
  end

  def measurement_systems_for_unit("per_" <> unit) do
    measurement_systems_for_unit(unit)
  end

  # Decompose the unit recursively until there is a match on
  # a base unit, otherwise return an error
  def measurement_systems_for_unit(unit) when is_binary(unit) do
    [first | rest] = String.split(unit, "_", parts: 2)

    with {:ok, part_unit, _conversion} <- Cldr.Unit.validate_unit(first) do
      measurement_systems_for_unit(part_unit)
    else
      _other ->
        if rest == [], do: {:error, unit_error(unit)}, else: measurement_systems_for_unit(rest)
    end
  end

  def measurement_systems_for_unit(unit) do
    {:error, unit_error(unit)}
  end

  @doc """
  Return a list of known measurement systems.

  ## Example

      iex> Cldr.Unit.known_measurement_systems()
      %{
        metric: %{alias: nil, description: "Metric System"},
        uksystem: %{
          alias: :imperial,
          description: "UK System of measurement: feet, pints, etc.; pints are 20oz"
        },
        ussystem: %{
          alias: nil,
          description: "US System of measurement: feet, pints, etc.; pints are 16oz"
        }
      }

  """

  def known_measurement_systems do
    @measurement_systems
  end

  @doc """
  Determines the preferred measurement system
  from a locale.

  See also `Cldr.known_measurement_systems/0`.

  ## Arguments

  *
  """
  @doc since: "3.4.0"
  def measurement_system_from_locale(locale, category \\ :default)

  def measurement_system_from_locale(locale, category) when is_binary(locale) do
    with {:ok, locale} <- Cldr.validate_locale(locale) do
      measurement_system_from_locale(locale, category)
    end
  end

  def measurement_system_from_locale(
        %Cldr.LanguageTag{locale: %{measurement_system: system}},
        _category
      )
      when not is_nil(system) do
    system
  end

  def measurement_system_from_locale(%Cldr.LanguageTag{} = locale, category) do
    territory = Cldr.Locale.territory_from_locale(locale)
    measurement_system_for_territory(territory, category)
  end

  def measurement_system_from_locale(locale, backend, category) when is_binary(locale) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend) do
      measurement_system_from_locale(locale, category)
    end
  end

  @category_usage @units
                  |> Map.get(:preferences)
                  |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
                  |> Map.new()

  @doc """
  Returns a mapping between Unit categories
  and the uses they define.

  ## Example

      iex> Cldr.Unit.unit_category_usage
      %{
        area: [:default, :geograph, :land],
        concentration: [:blood_glucose, :default],
        consumption: [:default, :vehicle_fuel],
        consumption_inverse: [:default, :vehicle_fuel],
        duration: [:default, :media],
        energy: [:default, :food],
        length: [:default, :focal_length, :person, :person_height, :rainfall, :road,
         :snowfall, :vehicle, :visiblty],
        mass: [:default, :person],
        mass_density: [:blood_glucose, :default],
        power: [:default, :engine],
        pressure: [:baromtrc, :default],
        speed: [:default, :wind],
        temperature: [:default, :weather],
        volume: [:default, :fluid, :oil, :vehicle],
        year_duration: [:default, :person_age]
      }

  """
  def unit_category_usage do
    @category_usage
  end

  @doc """
  Returns a mapping from unit categories to the
  base unit.

  """
  @base_units @units |> Map.get(:base_units) |> Map.new()
  def base_units do
    @base_units
  end

  @doc """
  Returns the base unit for a given unit.

  ## Argument

  * `unit` is either a `t:Cldr.Unit` or an `atom`

  ## Returns

  * `{:ok, base_unit}` or

  * `{:error, {exception, reason}}`

  ## Example

      iex> Cldr.Unit.base_unit :square_kilometer
      {:ok, :square_meter}

      iex> Cldr.Unit.base_unit :square_table
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"table\\""}}

  """
  def base_unit(unit_name) when is_atom(unit_name) or is_binary(unit_name) do
    with {:ok, _unit, conversion} <- validate_unit(unit_name) do
      base_unit(conversion)
    end
  end

  # def base_unit(%{base_unit: [base_name]}) when is_atom(base_name) do
  #   {:ok, base_name}
  # end

  def base_unit(%Unit{base_conversion: conversion}) do
    base_unit(conversion)
  end

  def base_unit(conversion) when is_list(conversion) or is_tuple(conversion) do
    Parser.canonical_base_unit(conversion)
  end

  def unknown_base_unit_error(unit_name) do
    {Cldr.Unit.UnknownBaseUnitError, "Base unit for #{inspect(unit_name)} is not known"}
  end

  @deprecated "Use `Cldr.Unit.known_unit_categories/0"
  defdelegate unit_categories(), to: __MODULE__, as: :known_unit_categories

  @doc """
  Returns the units category for a given unit

  ## Options

  * `unit` is any unit returned by
    `Cldr.Unit.new/2`

  ## Returns

  * `{:ok, category}` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.unit_category :pint_metric
      {:ok, :volume}

      iex> Cldr.Unit.unit_category :stone
      {:ok, :mass}

  """
  @spec unit_category(Unit.t() | String.t() | atom()) ::
          {:ok, category()} | {:error, {module(), String.t()}}

  def unit_category(unit) do
    with {:ok, _unit, conversion} <- validate_unit(unit),
         {:ok, base_unit} <- base_unit(conversion) do
      {:ok, Map.get(base_unit_category_map(), Kernel.to_string(base_unit))}
    end
  end

  @deprecated "Please use `Cldr.Unit.unit_category/1"
  def unit_type(unit) do
    unit_category(unit)
  end

  @base_unit_category_map Cldr.Config.units()
                          |> Map.get(:base_units)
                          |> Enum.map(fn {k, v} -> {to_string(v), k} end)
                          |> Map.new()

  @doc """
  Returns a mapping of base units to their respective
  unit categories.

  Base units are a common unit for a given unit
  category which are used in two scenarios:

  1. When converting between units.  If two units
    have the same base unit they can be converted
    to each other. See `Cldr.Unit.Conversion`.

  2. When identifying the preferred units for a given
    locale or territory, the base unit is used to
    aid identification of preferences for given use
    cases. See `Cldr.Unit.Preference`.

  ## Example

      => Cldr.Unit.base_unit_category_map
      %{
        "kilogram_square_meter_per_cubic_second_ampere" => :voltage,
        "kilogram_meter_per_meter_square_second" => :torque,
        "square_meter" => :area,
        "kilogram" => :mass,
        "kilogram_square_meter_per_square_second" => :energy,
        "revolution" => :angle,
        "candela_per_square_meter" => :luminance,
        ...
      }

  """
  @spec base_unit_category_map :: map()
  def base_unit_category_map do
    @base_unit_category_map
  end

  @doc """
  Returns the known styles for a unit.

  ## Example

      iex> Cldr.Unit.styles
      [:long, :short, :narrow]

  """
  @spec styles :: [style(), ...]
  def styles do
    @styles
  end

  @doc """
  Returns the default formatting style.

  ## Example

      iex> Cldr.Unit.default_style
      :long

  """
  @spec default_style :: style()
  def default_style do
    @default_style
  end

  # Returns a map of unit preferences
  #
  # Units of measure vary country by country. While
  # most countries standardize on the metric system,
  # others use the US or UK systems of measure.
  #
  # When presening a unit to an end user it is appropriate
  # to do so using units familiar and relevant to that
  # end user.
  #
  # The data returned by this function supports the
  # opportunity to convert a given unit to meet this
  # requirement.
  #
  # Unit preferences can vary by usage, not just territory,
  # Therefore the data is structured according to unit
  # category and unit usage.
  #
  # This function is called at compile time to generate
  # preference functions in `Cldr.Unit.Preference`.

  @doc false
  @unit_preferences Cldr.Config.units() |> Map.get(:preferences)
  @spec unit_preferences() :: map()
  @rounding 10
  def unit_preferences do
    for {category, usages} <- @unit_preferences, into: Map.new() do
      usages =
        for {usage, preferences} <- usages, into: Map.new() do
          preferences =
            Cldr.Enum.reduce_peeking(preferences, [], fn
              %{regions: regions} = pref, [%{regions: regions} | _rest], acc ->
                %{units: units, geq: geq} = pref

                value =
                  Unit.new!(hd(units), geq)
                  |> Conversion.convert_to_base_unit!()
                  |> Math.round(@rounding)
                  |> Map.get(:value)

                {:cont, acc ++ [%{pref | geq: Ratio.to_float(value)}]}

              pref, _rest, acc ->
                pref = %{pref | geq: 0}
                {:cont, acc ++ [pref]}
            end)

          {usage, preferences}
        end

      {category, usages}
    end
  end

  @doc false
  def rounding do
    @rounding
  end

  @doc false
  def units_for(locale, style \\ default_style(), backend \\ default_backend()) do
    module = Module.concat(backend, Elixir.Unit)
    module.units_for(locale, style)
  end

  @systems_by_territory Cldr.Config.territories()
                        |> Enum.map(fn {k, v} -> {k, v.measurement_system} end)
                        |> Map.new()

  @doc """
  Returns a map of measurement systems by territory.

  ## Example

      => Cldr.Unit.measurement_systems_by_territory
      %{
        KE: %{default: :metric, paper_size: :a4, temperature: :metric},
        GU: %{default: :metric, paper_size: :a4, temperature: :metric},
        ...
      }

  """
  @spec measurement_systems_by_territory() :: %{Cldr.territory() => map()}
  def measurement_systems_by_territory do
    @systems_by_territory
  end

  @deprecated "Use Cldr.Unit.measurement_systems_by_territory/0"
  defdelegate measurement_systems(), to: __MODULE__, as: :measurement_systems_by_territory

  @doc """
  Returns the default measurement system for a territory
  and a given system key.

  ## Arguments

  * `territory` is any valid territory returned by
    `Cldr.validate_territory/1`

  * `key` is any measurement system key.
    The known keys are `:default`, `:temperature`
    and `:paper_size`. The default key is `:default`.

  ## Examples

      iex> Cldr.Unit.measurement_system_for_territory :US
      :ussystem

      iex> Cldr.Unit.measurement_system_for_territory :GB
      :uksystem

      iex> Cldr.Unit.measurement_system_for_territory :AU
      :metric

      iex> Cldr.Unit.measurement_system_for_territory :US, :temperature
      :ussystem

      iex> Cldr.Unit.measurement_system_for_territory :GB, :temperature
      :uksystem

      iex> Cldr.Unit.measurement_system_for_territory :GB, :volume
      {:error,
       {Cldr.Unit.InvalidSystemKeyError,
        "The key :volume is not known. Valid keys are :default, :paper_size and :temperature"}}

  """
  @spec measurement_system_for_territory(atom(), atom()) ::
          :metric | :ussystem | :uksystem | :a4 | :us_letter |
          {:error, {module(), String.t()}}

  def measurement_system_for_territory(territory, category \\ :default)

  def measurement_system_for_territory(territory, :default = key) do
    do_measurement_system_for_territory(territory, key, :metric)
  end

  def measurement_system_for_territory(territory, :paper_size = key) do
    do_measurement_system_for_territory(territory, key, :a4)
  end

  def measurement_system_for_territory(territory, :temperature = key) do
    do_measurement_system_for_territory(territory, key, :metric)
  end

  def measurement_system_for_territory(_territory, key) do
    {:error, invalid_system_key_error(key)}
  end

  defp do_measurement_system_for_territory(territory, key, default) do
    with {:ok, territory} <- Cldr.validate_territory(territory) do
      get_in(measurement_systems_by_territory(),[territory, key]) || default
    end
  end

  @doc false
  def pattern_for(%LanguageTag{cldr_locale_name: locale_name}, style, unit, backend) do
    with {:ok, style} <- validate_style(style),
         {:ok, unit, _conversion} <- validate_unit(unit) do
      units = units_for(locale_name, style, backend)
      pattern = Map.get(units, unit)
      {:ok, pattern}
    end
  end

  def pattern_for(locale_name, style, unit, backend) do
    with {:ok, locale} <- backend.validate_locale(locale_name) do
      pattern_for(locale, style, unit, backend)
    end
  end

  def per_pattern_for(%LanguageTag{cldr_locale_name: locale_name}, style, unit, backend) do
    with {:ok, style} <- validate_style(style),
         {:ok, unit, _conversion} <- validate_unit(unit) do
      units = units_for(locale_name, style, backend)
      pattern = get_in(units, [unit, :per_unit_pattern])
      default_pattern = get_in(units, [:per, :compound_unit_pattern])
      {:ok, pattern || default_pattern}
    end
  end

  def per_pattern_for(locale_name, style, unit, backend) do
    with {:ok, locale} <- backend.validate_locale(locale_name) do
      per_pattern_for(locale, style, unit, backend)
    end
  end

  defp normalize_options(backend, options) do
    locale = Keyword.get(options, :locale, backend.get_locale())
    style = Keyword.get(options, :style, @default_style)

    options =
      options
      |> Keyword.delete(:locale)
      |> Keyword.put(:style, style)

    {locale, style, options}
  end

  @doc """
  Validates a unit name and normalizes it,

  A unit name can be expressed as:

  * an `atom()` in which case the unit must be
    localizable in CLDR directly

  * or a `String.t()` in which case it is parsed
    into a list of composable subunits that
    can be converted but are not guaranteed to
    be output as a localized string.

  ## Arguments

  * `unit_name` is an `atom()` or `String.t()`, supplied
    as is or as part of an `Cldr.Unit.t()` struct.

  ## Returns

  * `{:ok, canonical_unit_name, conversion}` where
    `canonical_unit_name` is the normalized unit name
    and `conversion` is an opaque structure used
    to convert this this unit into its base unit or

  * `{:error, {exception, reason}}`

  ## Notes

  A returned `unit_name` that is an atom is directly
  localisable (CLDR has translation data for the unit).

  A `unit_name` that is a `String.t()` is composed of
  one or more unit names that need to be resolved in
  order for the `unit_name` to be localised.

  The difference is an implementation detail and should
  not be of concern to the user of this library.

  ## Examples

      iex> Cldr.Unit.validate_unit :meter
      {
        :ok,
        :meter,
        [meter: %Cldr.Unit.Conversion{base_unit: [:meter], factor: 1, offset: 0}]
      }

      iex> Cldr.Unit.validate_unit "meter"
      {:ok, :meter,
       [meter: %Cldr.Unit.Conversion{base_unit: [:meter], factor: 1, offset: 0}]}

      iex> Cldr.Unit.validate_unit "miles_per_liter"
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"s\\""}}

      iex> Cldr.Unit.validate_unit "mile_per_liter"
      {:ok, "mile_per_liter",
       {[
          mile:
           %Cldr.Unit.Conversion{
             base_unit: [:meter],
             factor: Ratio.new(905980129838867985, 562949953421312),
             offset: 0
           }
        ],
        [
          liter:
           %Cldr.Unit.Conversion{
             base_unit: [:cubic_meter],
             factor: Ratio.new(1152921504606847, 1152921504606846976),
             offset: 0
           }
        ]}}

  """
  def validate_unit(unit_name) when unit_name in @translatable_units do
    {:ok, unit_name, [{unit_name, Conversions.conversion_for!(unit_name)}]}
  end

  @aliases Alias.aliases() |> Map.keys()
  def validate_unit(unit_name) when unit_name in @aliases do
    unit_name
    |> Alias.alias()
    |> validate_unit
  end

  # FIXME refactor this hacky conditional
  def validate_unit(unit_name) when is_binary(unit_name) do
    unit_name =
      unit_name
      |> normalize_unit_name
      |> maybe_translatable_unit

    if is_atom(unit_name) do
      validate_unit(unit_name)
    else
      with {:ok, parsed} <- Parser.parse_unit(unit_name) do
        name = Parser.canonical_unit_name(parsed)
        canonical_name = maybe_translatable_unit(name)
        {:ok, canonical_name, parsed}
      end
    end
  end

  def validate_unit(unit_name) when is_atom(unit_name) do
    unit_name
    |> Atom.to_string()
    |> validate_unit
  end

  def validate_unit(%Unit{unit: unit_name, base_conversion: base_conversion}) do
    {:ok, unit_name, base_conversion}
  end

  def validate_unit(unknown_unit) do
    {:error, unit_error(unknown_unit)}
  end

  @doc false
  def normalize_unit_name(name) when is_binary(name) do
    String.replace(name, [" ", "-"], "_")
  end

  def maybe_translatable_unit(name) do
    atom_name = String.to_existing_atom(name)

    if atom_name in known_units() do
      atom_name
    else
      name
    end
  rescue
    ArgumentError ->
      name
  end

  @doc """
  Validates a unit style and normalizes it to a
  standard downcased atom form

  """
  def validate_style(style) when style in @styles do
    {:ok, style}
  end

  def validate_style(style) when is_binary(style) do
    style
    |> String.downcase()
    |> String.to_existing_atom()
    |> validate_style()
  catch
    ArgumentError ->
      {:error, style_error(style)}
  end

  def validate_style(style) do
    {:error, style_error(style)}
  end

  @doc """
  Convert a ratio Unit to a float unit
  """
  def ratio_to_float(%Unit{value: %Ratio{} = value} = unit) do
    value = Ratio.to_float(value)
    %{unit | value: value}
  end

  def ratio_to_float(%Unit{} = unit) do
    unit
  end

  @doc false
  def unit_error(nil) do
    {
      Cldr.UnknownUnitError,
      "A unit must be provided, for example 'Cldr.Unit.string(123, unit: :meter)'."
    }
  end

  def unit_error(unit) do
    {Cldr.UnknownUnitError, "The unit #{inspect(unit)} is not known."}
  end

  @doc false
  def unit_category_error(category) do
    {Cldr.Unit.UnknownUnitCategoryError, "The unit category #{inspect(category)} is not known."}
  end

  @doc false
  def style_error(style) do
    {Cldr.UnknownFormatError, "The unit style #{inspect(style)} is not known."}
  end

  @doc false
  def incompatible_units_error(unit_1, unit_2) do
    {
      Unit.IncompatibleUnitsError,
      "Operations can only be performed between units with the same category and base unit. " <>
        "Received #{inspect(unit_1)} and #{inspect(unit_2)}"
    }
  end

  @doc false
  def unknown_usage_error(category, usage) do
    {
      Cldr.Unit.UnknownUsageError,
      "The unit category #{inspect(category)} does not define a usage #{inspect(usage)}"
    }
  end

  @doc false
  def unit_not_translatable_error(unit) do
    {
      Cldr.Unit.UnitNotTranslatableError,
      "The unit #{inspect(unit)} is not translatable"
    }
  end

  @doc false
  def unknown_measurement_system_error(system) do
    {
      Cldr.Unit.UnknownMeasurementSystemError,
      "The measurement system #{inspect(system)} is not known"
    }
  end

  @doc false
  def invalid_system_key_error(key) do
    {
      Cldr.Unit.InvalidSystemKeyError,
      "The key #{inspect(key)} is not known. " <>
      "Valid keys are :default, :paper_size and :temperature"
    }
  end

  defp int_rem(unit) do
    integer = Unit.round(unit, 0, :down) |> Math.trunc()
    remainder = Math.sub(unit, integer)
    {integer, remainder}
  end

  @doc false
  # TODO remove for Cldr 3.0
  if Code.ensure_loaded?(Cldr) && function_exported?(Cldr, :default_backend!, 0) do
    def default_backend do
      Cldr.default_backend!()
    end
  else
    def default_backend do
      Cldr.default_backend()
    end
  end
end
