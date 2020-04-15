defmodule Cldr.Unit do
  @moduledoc """
  Supports the CLDR Units definitions which provide for the localization of many
  unit types.

  The primary public API defines:

  * `Cldr.Unit.to_string/3` which, given a number and a unit name or unit list will
    output a localized string

  * `Cldr.Unit.units/0` identifies the available units for localization

  * `Cldr.Unit.{add, sub, mult, div}/2` to support basic unit mathematics between
    units of compatible type (like length or volume)

  * `Cldr.Unit.compare/2` to compare one unit to another unit as long as they
    are convertable.

  * `Cldr.Unit.convert/2` to convert one unit to another unit as long as they
    are convertable.

  * `Cldr.Unit.decompose/2` to take a unit and return a list of units decomposed
    by a list of smaller units.

  """

  alias Cldr.Unit
  alias Cldr.Locale
  alias Cldr.LanguageTag
  alias Cldr.Substitution
  alias Cldr.Unit.{Math, Alias, Parser, Conversion, Conversions, Preference}

  @enforce_keys [:unit, :value, :base_conversion, :usage, :format_options]

  defstruct unit: nil,
            value: 0,
            base_conversion: [],
            usage: :default,
            format_options: []

  @type unit :: atom()
  @type usage :: atom()
  @type style :: atom()
  @type value :: Cldr.Math.number_or_decimal() | Ratio.t()
  @type conversion :: Conversion.t() | list()
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

  @doc """
  Returns a new `Unit.t` struct.

  ## Arguments

  * `value` is any float, integer, `Ratio` or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.units/0`

  * `options` is Keyword list of options. The default
    is `[]`

  ## Options

  * `:use` is the intended use of the unit. This
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
  defp validate_category_usage(category, usage) do
    usage_list = Map.get(unit_category_usage(), category, @default_category_usage)

    if usage in usage_list do
      {:ok, usage}
    else
      {:error, unknown_usage_error(category, usage)}
    end
  end

  @doc """
  Returns a new `Unit.t` struct or raises on error.

  ## Arguments

  * `value` is any float, integer or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.units/0`

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
  @spec compatible?(unit(), unit()) :: boolean
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
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list of options.

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.units/0`. Ignored if
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

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :gallon
      {:ok, "123 gallons"}

      iex> Cldr.Unit.to_string 1, MyApp.Cldr, unit: :gallon
      {:ok, "1 gallon"}

      iex> Cldr.Unit.to_string 1, MyApp.Cldr, unit: :gallon, locale: "af"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.to_string 1, MyApp.Cldr, unit: :gallon, locale: "bs"
      {:ok, "1 galon"}

      iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: :gallon, format: :long
      {:ok, "1 thousand gallons"}

      iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: :gallon, format: :short
      {:ok, "1K gallons"}

      iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: :megahertz
      {:ok, "1,234 megahertz"}

      iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: :megahertz, style: :narrow
      {:ok, "1,234MHz"}

      iex> unit = Cldr.Unit.new!(123, :foot)
      iex> Cldr.Unit.to_string unit, MyApp.Cldr
      {:ok, "123 feet"}

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :blabber, locale: "en"
      {:error, {Cldr.UnknownUnitError,
        "Unknown unit was detected at \\"blabber\\""}}

  """

  @spec to_string(
          list_or_number :: value | t() | list(t()),
          backend_or_options :: Cldr.backend() | Keyword.t(),
          options :: Keyword.t()
        ) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(list_or_number, backend, options \\ [])

  # Options but no backend
  def to_string(list_or_number, options, []) when is_list(options) do
    locale = Cldr.get_locale()
    to_string(list_or_number, locale.backend, options)
  end

  # It's a list of units
  def to_string(unit_list, backend, options) when is_list(unit_list) do
    with {locale, _style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale) do
      options =
        options
        |> Map.to_list()
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

  # Now we have a unit, a backend and some options
  def to_string(%Unit{value: %Ratio{}} = unit, backend, options) when is_list(options) do
    unit = ratio_to_float(unit)
    to_string(unit, backend, options)
  end

  def to_string(%Unit{unit: unit, value: value, format_options: format_options}, backend, options)
      when is_list(options) do
    options =
      format_options
      |> Keyword.merge(options)
      |> Keyword.put(:unit, unit)

    to_string(value, backend, options)
  end

  # Finally we have the right shape to execute
  def to_string(number, backend, options) when is_list(options) do
    with {locale, style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale),
         {:ok, style} <- validate_style(style),
         {:ok, unit, _conversion} <- validate_unit(options[:unit]),
         {:ok, string} <- to_string(number, unit, locale, style, backend, options) do
      {:ok, string}
    end
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string!/3` for full details.

  """
  @spec to_string!(list_or_number :: value | t() | [t()]) ::
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
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.units/1`. Ignored if
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

      iex> Cldr.Unit.to_string! 123, MyApp.Cldr, unit: :gallon
      "123 gallons"

      iex> Cldr.Unit.to_string! 1, MyApp.Cldr, unit: :gallon
      "1 gallon"

      iex> Cldr.Unit.to_string! 1, MyApp.Cldr, unit: :gallon, locale: "af"
      "1 gelling"

  """
  @spec to_string!(value(), Cldr.backend() | Keyword.t(), Keyword.t()) :: String.t() | no_return()

  def to_string!(number, backend, options \\ []) do
    case to_string(number, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @spec to_string(
          value(),
          unit(),
          locale(),
          style(),
          Cldr.backend(),
          map()
        ) :: {:ok, String.t()} | {:error, {module(), String.t()}}

  # Concrete implementation of to_string
  # Atom units are tanslatable. String ones are not.
  # This function is for those units which are known
  # to be translatable
  defp to_string(number, unit, locale, style, backend, %{per: nil} = options)
       when is_atom(unit) do
    with {:ok, number_string} <-
           Cldr.Number.to_string(number, backend, Map.to_list(options)),
         {:ok, patterns} <- pattern_for(locale, style, unit, backend) do
      cardinal_module = Module.concat(backend, Number.Cardinal)
      pattern = cardinal_module.pluralize(number, locale, patterns)

      [number_string]
      |> Substitution.substitute(pattern)
      |> :erlang.iolist_to_binary()
      |> wrap_ok
    end
  end

  # Its a compound unit which can't be translated directly
  # So we split it on the `_per_` boundary and try again
  # with a `:per` options (which is now a private option)
  defp to_string(number, unit, locale, style, backend, %{per: nil} = options)
       when is_binary(unit) do
    [unit, per_unit] =
      unit
      |> String.split("_per_", parts: 2)
      |> Enum.map(&String.to_existing_atom/1)

    options = Map.put(options, :per, per_unit)
    to_string(number, unit, locale, style, backend, options)
  rescue
    ArgumentError ->
      {:error, unit_not_translatable_error(unit)}
  end

  # If its a compound option then we pass through here after
  # the unit has been split. Since its after a split
  # we need to check that we can in fact translate each of the parts.
  defp to_string(number, unit, locale, style, backend, %{per: per} = options) do
    with {:ok, unit, _} <- validate_unit(unit),
         {:ok, per, _} <- validate_unit(per),
         {:ok, per_pattern} <- per_pattern_for(locale, style, per, backend),
         {:ok, unit_string} <-
           to_string(number, unit, locale, style, backend, Map.put(options, :per, nil)) do
      if length(per_pattern) <= 2 do
        [unit_string]
        |> Substitution.substitute(per_pattern)
      else
        [unit_string, localize_per_unit(per, locale, style)]
        |> Substitution.substitute(per_pattern)
      end
      |> :erlang.iolist_to_binary()
      |> wrap_ok
    end
  end

  defp localize_per_unit(unit, %LanguageTag{cldr_locale_name: locale_name}, style) do
    locale_name
    |> Cldr.Unit.units_for(style)
    |> get_in([unit, :one])
    |> Enum.reject(&is_integer/1)
    |> hd
    |> String.trim()
  end

  def wrap_ok({:error, _} = error) do
    error
  end

  def wrap_ok(other) do
    {:ok, other}
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

  @app_name Cldr.Config.app_name()
  @data_dir [:code.priv_dir(@app_name), "/cldr/locales"] |> :erlang.iolist_to_binary()
  @config %{data_dir: @data_dir, locales: ["en"], default_locale: "en"}

  @unit_tree "en"
             |> Cldr.Config.get_locale(@config)
             |> Map.get(:units)
             |> Map.get(:short)
             |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
             |> Map.new()

  @doc """
  Decomposes a unit into subunits.

  Any list compatible units can be provided
  however a list of units of decreasing scale
  is recommended.  For example `[:foot, :inch]`
  or `[:kilometer, :meter, :centimeter, :millimeter]`

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `unit_list` is a list of valid units (one or
    more from the list returned by `Cldr.units/0`. All
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
  def localize(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    localize(unit, backend, locale)
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
    to the unit category.  See `Cldr.Unit.unit_preferences/0`.

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
    Cldr.Math.decimal_compare(value, @decimal_0) == :eq
  end

  # Ratios that are zero are just integers
  # so anything that is a %Ratio{} is not zero
  def zero?(%Unit{value: %Ratio{}}) do
    false
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
  @measurement_systems Cldr.Config.measurement_systems()
  def known_measurement_systems do
    @measurement_systems
  end

  @category_usage Cldr.Config.units()
                  |> Map.get(:preferences)
                  |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
                  |> Map.new()

  @doc """
  Returns a mapping between Unit categories
  and the uses they define.

  """
  def unit_category_usage do
    @category_usage
  end

  @doc """
  Returns a list of the known unit categories.

  ## Example

      iex> Cldr.Unit.known_unit_categories
      [:acceleration, :angle, :area, :compound, :concentr, :consumption, :coordinate, :digital,
       :duration, :electric, :energy, :force, :frequency, :graphics, :length, :light, :mass,
       :power, :pressure, :speed, :temperature, :torque, :volume]

  """
  @unit_categories Map.keys(@unit_tree)
  def known_unit_categories do
    @unit_categories
  end

  @doc """
  Returns a mapping from unit categories to the
  base unit.

  """
  @base_units Cldr.Config.units() |> Map.get(:base_units) |> Map.new()
  def base_units do
    @base_units
  end

  @doc """
  Returns the base unit for a given `t:Cldr.Unit.t()
  or `atom()`.

  ## Argument

  * `unit` is either a `t:Cldr.Unit.t()` or an `atom`

  ## Returns

  * `{:ok, base_unit}` or

  * `{:error, {exception, reason}}`

  ## Example

      iex> Cldr.Unit.base_unit :square_kilometer
      {:ok, "square_meter"}

      iex> Cldr.Unit.base_unit :square_table
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"table\\""}}

  """
  def base_unit(unit_name) when is_atom(unit_name) or is_binary(unit_name) do
    with {:ok, _unit, conversion} <- validate_unit(unit_name) do
      base_unit(conversion)
    end
  end

  def base_unit(%{base_unit: [base_name]}) when is_atom(base_name) do
    {:ok, base_name}
  end

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
          {:ok, atom()} | {:error, {module(), String.t()}}

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
  @units @unit_tree
         |> Map.delete(:compound)
         |> Map.values()
         |> List.flatten()

  @spec known_units :: [atom, ...]
  def known_units do
    @units
  end

  @deprecated "Use Cldr.Unit.known_units/0"
  def units, do: known_units()

  @doc """
  Returns the known styles for a unit.

  ## Example

      iex> Cldr.Unit.styles
      [:long, :short, :narrow]

  """
  def styles do
    @styles
  end

  @doc """
  Returns the default formatting style.

  ## Example

      iex> Cldr.Unit.default_style
      :long

  """
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
  # opportunity to convert a give unit to meet this
  # requirement.
  #
  # Unit preferences can vary by usage, not just territory,
  # Therefore the data is structured according to unit
  # category andunit usage.

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
  def units_for(locale, style \\ default_style(), backend \\ Cldr.default_backend()) do
    module = Module.concat(backend, :"Elixir.Unit")
    module.units_for(locale, style)
  end

  @measurement_systems Cldr.Config.territories()
                       |> Enum.map(fn {k, v} -> {k, v.measurement_system} end)
                       |> Map.new()

  @doc """
  Returns a map of measurement systems by territory

  """
  @spec measurement_systems() :: map()
  def measurement_systems do
    @measurement_systems
  end

  @doc """
  Returns the default measurement system for a territory
  in a given category.

  ## Arguments

  * `territory` is any valid territory returned by
    `Cldr.validate_territory/1`

  * `category` is any measurement system category.
    The known categories are `:default`, `:temperature`
    and `:paper_size`. The default category is `:default`.

  ## Examples

      iex> Cldr.Unit.measurement_system_for :US
      :ussystem

      iex> Cldr.Unit.measurement_system_for :GB
      :uksystem

      iex> Cldr.Unit.measurement_system_for :AU
      :metric

      iex> Cldr.Unit.measurement_system_for :US, :temperature
      :ussystem

      iex> Cldr.Unit.measurement_system_for :GB, :temperature
      :uksystem

  """
  @spec measurement_system_for(atom(), atom()) ::
          :metric | :ussystem | :uk_system | {:error, {module(), String.t()}}

  def measurement_system_for(territory, category \\ :default) do
    with {:ok, territory} <- Cldr.validate_territory(territory) do
      measurement_systems()
      |> get_in([territory, category])
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
    with {:ok, per_unit, _} <- validate_per_unit(options[:per]) do
      locale = Keyword.get(options, :locale, backend.get_locale())
      style = Keyword.get(options, :style, @default_style)

      options =
        options
        |> Keyword.delete(:locale)
        |> Keyword.put(:style, style)
        |> Keyword.put(:per, per_unit)

      {locale, style, Map.new(options)}
    end
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

  * `unit_name` is an `atom()` or `String.t()`

  ## Returns

  * `{:ok, canonical_unit_name, conversion}` where
    `canonical_unit_name` is the normalized unit name
    and `conversion` is an opaque structure used
    to convert this this unit into its base unit or

  * `{:error, {exception, reason}}`

  """
  def validate_unit(unit_name) when unit_name in @units do
    {:ok, unit_name, Conversions.conversion_for!(unit_name)}
  end

  @aliases Alias.aliases() |> Map.keys()
  def validate_unit(unit_name) when unit_name in @aliases do
    unit_name
    |> Alias.alias()
    |> validate_unit
  end

  def validate_unit(unit_name) when is_binary(unit_name) do
    with {:ok, parsed} <- Parser.parse_unit(unit_name) do
      name = Parser.canonical_unit_name(parsed)
      canonical_name = maybe_atomize_unit(name)
      {:ok, canonical_name, parsed}
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

  def maybe_atomize_unit(name) do
    if (atom_name = String.to_existing_atom(name)) && atom_name in @units do
      atom_name
    else
      name
    end
  rescue
    ArgumentError ->
      name
  end

  defp validate_per_unit(nil) do
    {:ok, nil, nil}
  end

  defp validate_per_unit(unit) do
    validate_unit(unit)
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
      "Operations can only be performed between units of the same category. " <>
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

  def unit_not_translatable_error(unit) do
    {
      Cldr.Unit.UnitNotTranslatableError,
      "The unit #{inspect(unit)} is not translatable"
    }
  end

  defp int_rem(unit) do
    integer = Unit.round(unit, 0, :down) |> Math.trunc()
    remainder = Math.sub(unit, integer)
    {integer, remainder}
  end
end
