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
    are convertible.

  * `Cldr.Unit.convert/2` to convert one unit to another unit as long as they
    are convertible.

  * `Cldr.Unit.localize/3` will convert a unit into the units preferred for a
    given locale and usage

  * `Cldr.Unit.preferred_units/3` which, for a given unit and locale,
    will return a list of preferred units that can be applied to
    `Cldr.Unit.decompose/2`

  * `Cldr.Unit.decompose/2` to take a unit and return a list of units decomposed
    by a list of smaller units.

  """
  import Kernel, except: [to_string: 1]

  alias Cldr.Unit
  alias Cldr.{Locale, LanguageTag}
  alias Cldr.Unit.{Math, Alias, Parser, Conversion, Conversions, Preference, BaseUnit, Format}

  @enforce_keys [:unit, :value, :base_conversion, :usage, :format_options]

  defstruct unit: nil,
            value: 0,
            base_conversion: [],
            usage: :default,
            format_options: [],
            backend: nil

  @root_locale_name Cldr.Config.root_locale_name()

  # See https://unicode.org/reports/tr35/tr35-general.html#Case
  @grammatical_case [
    :abessive,
    :ablative,
    :accusative,
    :adessive,
    :allative,
    :causal,
    :comitative,
    :dative,
    :delative,
    :elative,
    :ergative,
    :genitive,
    :illative,
    :inessive,
    :instrumental,
    :locative,
    :localtivecopulative,
    :nominative,
    :oblique,
    :partitive,
    :prepositional,
    :sociative,
    :sublative,
    :superessive,
    :terminative,
    :translative,
    :vocative
  ]

  @grammatical_gender [
    :animate,
    :inanimate,
    :personal,
    :common,
    :feminine,
    :masculine,
    :neuter
  ]

  @styles [
    :long,
    :short,
    :narrow
  ]

  @measurement_systems Cldr.Config.measurement_systems()
  @system_names Map.keys(@measurement_systems)

  @measurement_system_keys [
    :default,
    :temperature,
    :paper_size
  ]

  # Converts a list of atoms into a typespec
  type = &Enum.reduce(&1, fn x, acc -> {:|, [], [x, acc]} end)

  @type translatable_unit :: atom() | list(atom())
  @type unit :: translatable_unit | String.t()
  @type category :: atom()
  @type usage :: atom()
  @type grammatical_gender :: unquote(type.(@grammatical_gender))
  @type grammatical_case :: unquote(type.(@grammatical_case))
  @type measurement_system :: unquote(type.(@system_names))
  @type measurement_system_key :: unquote(type.(@measurement_system_keys))
  @type style :: unquote(type.(@styles))
  @type value :: Cldr.Math.number_or_decimal() | Ratio.t()
  @type locale :: Locale.locale_name() | LanguageTag.t()
  @type base_conversion :: {translatable_unit, Conversion.t()}
  @type conversion :: [base_conversion()] | {[base_conversion()], [base_conversion()]}

  @type t :: %__MODULE__{
          unit: unit(),
          value: value(),
          base_conversion: conversion(),
          usage: usage(),
          format_options: Keyword.t()
        }

  @default_style :long

  @app_name Cldr.Config.app_name()
  @data_dir [:code.priv_dir(@app_name), "/cldr/locales"] |> :erlang.iolist_to_binary()
  @config %{data_dir: @data_dir, locales: ["en"], default_locale: "en"}

  @unit_tree :en
             |> Cldr.Locale.Loader.get_locale(@config)
             |> Map.fetch!(:units)
             |> Map.fetch!(:long)
             |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
             |> Map.new()

  @units Cldr.Config.units()

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
  @units_by_category @unit_tree
                     |> Map.delete(:compound)
                     |> Map.delete(:coordinate)

  @doc since: "3.4.0"
  @spec known_units_by_category :: %{category() => [translatable_unit(), ...]}

  def known_units_by_category do
    @units_by_category
  end

  @doc """
  Returns the known units that are directly
  translatable.

  These units have localised content in CLDR
  and are used as a key to retrieving that
  content.

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
  @translatable_units @units_by_category
                      |> Map.values()
                      |> List.flatten()
                      |> List.delete(:generic)
                      |> Kernel.++(Cldr.Unit.Additional.additional_units())

  @spec known_units :: [translatable_unit(), ...]
  def known_units do
    @translatable_units
  end

  @deprecated "Use Cldr.Unit.known_units/0"
  defdelegate unit(), to: __MODULE__, as: :known_units

  @doc """
  Returns a list of the known unit categories.

  ## Example

      iex> Cldr.Unit.known_unit_categories
      [:acceleration, :angle, :area, :concentr, :consumption, :digital,
       :duration, :electric, :energy, :force, :frequency, :graphics, :length, :light, :mass,
       :power, :pressure, :speed, :temperature, :torque, :volume]

  """
  @unit_categories Map.keys(@units_by_category)

  @spec known_unit_categories :: list(category())
  def known_unit_categories do
    @unit_categories
  end

  @doc """
  Returns the list of units defined for a given
  category.

  ## Arguments

  * `category` is any unit category returned by
    `Cldr.Unit.known_unit_categories/0`.

  See also `Cldr.Unit.known_units_by_category/0`.

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
          {:ok, [translatable_unit(), ...]} | {:error, {module(), String.t()}}

  def known_units_for_category(category) when category in @unit_categories do
    units = Map.fetch!(known_units_by_category(), category)
    {:ok, units}
  end

  def known_units_for_category(category) do
    {:error, unit_category_error(category)}
  end

  @doc """
  Returns a list of the known grammatical
  cases.

  A grammatical case can be provided as an option to
  `Cldr.Unit.to_string/2` in order to localise a unit
  appropriate to the context in which it is used.

  ## Example

      iex> Cldr.Unit.known_grammatical_cases()
      [
        :abessive,
        :ablative,
        :accusative,
        :adessive,
        :allative,
        :causal,
        :comitative,
        :dative,
        :delative,
        :elative,
        :ergative,
        :genitive,
        :illative,
        :inessive,
        :instrumental,
        :locative,
        :localtivecopulative,
        :nominative,
        :oblique,
        :partitive,
        :prepositional,
        :sociative,
        :sublative,
        :superessive,
        :terminative,
        :translative,
        :vocative
      ]

  """
  @doc since: "3.5.0"
  def known_grammatical_cases do
    @grammatical_case
  end

  @doc """
  Returns a list of the known grammatical genders.

  A gender can be provided as an option to
  `Cldr.Unit.to_string/2` in order to localise a unit
  appropriate to the context in which it is used.

  ## Example

      iex> Cldr.Unit.known_grammatical_genders
      [
        :animate,
        :inanimate,
        :personal,
        :common,
        :feminine,
        :masculine,
        :neuter
      ]

  """
  @doc since: "3.5.0"
  def known_grammatical_genders do
    @grammatical_gender
  end

  @doc """
  Returns a new `Unit.t` struct.

  ## Arguments

  * `value` is any float, integer, `Ratio` or `Decimal`

  * `unit` is any unit name returned by `Cldr.Unit.known_units/0`

  * `options` is Keyword list of options. The default
    is `[]`

  ## Options

  * `:usage` is the intended use of the unit. This
    is used during localization to convert the unit
    to that appropriate for the unit category,
    usage, target territory and unit value. The usage
    must be defined for the unit's category. See
    `Cldr.Unit.unit_category_usage/0` for the known
    usage types for each category.

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

      Cldr.Unit.new(:gallon, 23, usage: :fluid)
      #=> {:ok, #Cldr.Unit<:gallon, 23, usage: :fluid, format_options: []>}

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

  @doc """
  Returns a new `Unit.t` struct from a map.

  A map representation of a unit may be generated
  from json or other external format data.

  The map provided must have the keys `unit` and
  `value` in either `String.t` or `atom` (both keys
  must be of the same type).

  `value` must be either an integer, a float or a map
  representation of a rational number. A rational number
  map has the keys `numerator` and `denominator` in either
  `String.t` or `atom` format (both keys must be of
  the same type).

  ## Arguments

  * `map` is a map with the keys `unit` and `value`

  ## Returns

  * `{:ok, unit}` or

  * `{:error, {exception, reason}}`

  ## Examples

      Cldr.Unit.from_map %{value: 1, unit: "kilogram"}
      => {:ok, #Cldr.Unit<:kilogram, 1>}

      Cldr.Unit.from_map %{value: %{numerator: 3, denominator: 4}, unit: "kilogram"}
      => {:ok, #Cldr.Unit<:kilogram, 3 <|> 4>}

      Cldr.Unit.from_map %{"value" => 1, "unit" => "kilogram"}
      => {:ok, #Cldr.Unit<:kilogram, 1>}

  """
  def from_map(%{"unit" => unit, "value" => value}) when is_number(value) do
    new(unit, value)
  end

  def from_map(%{"unit" => unit, "value" => %{"numerator" => numerator, "denominator" => denominator}}) do
    new(unit, Ratio.new(numerator, denominator))
  end

  def from_map(%{unit: unit, value: value}) when is_number(value) do
    new(unit, value)
  end

  def from_map(%{unit: unit, value: %{numerator: numerator, denominator: denominator}}) do
    new(unit, Ratio.new(numerator, denominator))
  end

  def from_map(other) do
    {:error, unit_error(other)}
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

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:only` is a unit category or unit, or a list of unit categories and units.
    The parsed unit must match one of the categories or units in order to
    be valid. This is helpful when disambiguating parsed units. For example,
    parsing "2w" could be either "2 watts" or "2 weeks". Specifying `only: :duration`
    would return "2 weeks". Specifying `only: :power` would return
    "2 watts"

  * `:except` is the oppostte of `:only`. The parsed unit must *not*
    match the specified unit or category, or unit categories and units.

  ## Returns

  * `{:ok, unit}` or

  * `{:error, {exception, reason}}`

  ## Notes

  * When both `:only` and `:except` options are passed, both
    conditions must be true in order to return a parsed result.

  * Only units returned by `Cldr.Unit.known_units/0` can be
    used in the `:only` and `:except` filters.

  ## Examples

      iex> Cldr.Unit.parse "1kg"
      Cldr.Unit.new(1, :kilogram)

      iex> Cldr.Unit.parse "1w"
      Cldr.Unit.new(1, :watt)

      iex> Cldr.Unit.parse "1w", only: :duration
      Cldr.Unit.new(1, :week)

      iex> Cldr.Unit.parse "1m", only: [:year, :month, :day]
      Cldr.Unit.new(1, :month)

      iex> Cldr.Unit.parse "1 tages", locale: "de"
      Cldr.Unit.new(1, :day)

      iex> Cldr.Unit.parse "1 tag", locale: "de"
      Cldr.Unit.new(1, :day)

      iex> Cldr.Unit.parse("42 millispangels")
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"spangels\\""}}

  """
  @spec parse(binary) :: {:ok, t()} | {:error, {module(), binary()}}

  @doc since: "3.6.0"
  def parse(unit_string, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, strings} <- Module.concat([backend, :Unit]).unit_strings_for(locale) do
      case Cldr.Number.Parser.scan(unit_string, options) do
        [number, unit] when is_number(number) and is_binary(unit) ->
          units = resolve_unit_alias(unit, strings)
          new_unit(number, unit, units, options)

        [unit, number] when is_number(number) and is_binary(unit) ->
          units = resolve_unit_alias(unit, strings)
          new_unit(number, unit, units, options)

        _other ->
          {:error, not_parseable_error(unit_string)}
      end
    end
  end

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

      iex> Cldr.Unit.parse_unit_name "kg"
      {:ok, :kilogram}

      iex> Cldr.Unit.parse_unit_name "w"
      {:ok, :watt}

      iex> Cldr.Unit.parse_unit_name "w", only: :duration
      {:ok, :week}

      iex> Cldr.Unit.parse_unit_name "m", only: [:year, :month, :day]
      {:ok, :month}

      iex> Cldr.Unit.parse_unit_name "tages", locale: "de"
      {:ok, :day}

      iex> Cldr.Unit.parse_unit_name "tag", locale: "de"
      {:ok, :day}

      iex> Cldr.Unit.parse_unit_name("millispangels")
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"spangels\\""}}

  """
  @doc since: "3.14.0"

  @spec parse_unit_name(binary, Keyword.t()) :: {:ok, atom} | {:error, {module(), binary()}}
  def parse_unit_name(unit_name_string, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, strings} <- Module.concat([backend, :Unit]).unit_strings_for(locale),
         units = resolve_unit_alias(unit_name_string, strings),
         {:ok, {only, except, _}} <- get_filter_options(options),
         {:ok, unit} = unit_matching_filter(unit_name_string, units, only, except),
         {:ok, unit, _base_conversion} <- validate_unit(unit) do
      {:ok, unit}
    end
  end

  defp new_unit(number, unit, units, options) do
    with {:ok, {only, except, options}} <- get_filter_options(options),
         {:ok, unit} <- unit_matching_filter(unit, units, only, except) do
      new(number, unit, options)
    end
  end

  defp get_filter_options(options) do
    {only, options} = Keyword.pop(options, :only, []) |> maybe_list_wrap()
    {except, options} = Keyword.pop(options, :except, []) |> maybe_list_wrap()

    with {:ok, only} <- validate_categories_or_units(only),
         {:ok, except} <- validate_categories_or_units(except) do
      {:ok, {only, except, options}}
    end
  end

  # If there are no options to filter then
  # use the original implementation which is to pick
  # the shortest match (lexically shortest)

  defp unit_matching_filter(_unit, unit, {[],[]} = _only, {[],[]} = _except) when is_binary(unit) do
    {:ok, unit}
  end

  defp unit_matching_filter(_unit, units, {[],[]} = _only, {[],[]} = _except) do
    units
    |> Enum.map(&Kernel.to_string/1)
    |> Enum.sort(&(String.length(&1) <= String.length(&2) && &1 < &2))
    |> hd
    |> wrap(:ok)
  end

  # If there is an :only and/or :except option then
  # filter for a match. If there is no match its an
  # error. And error could be because the result is
  # ambiguous (multiple results) or because no category
  # could be derived for a unit

  defp unit_matching_filter(unit, units, only, except) do
    case filter_units(units, only, except) do
      [unit] -> {:ok, unit}
      [] -> {:error, category_unit_match_error(units, only, except)}
      units -> {:error, ambiguous_unit_error(unit, units)}
    end
  end

  defp filter_units(units, only, except) do
    Enum.filter(units, fn unit ->
      case unit_category(unit) do
        {:ok, category} -> category_match?(category, only, except) && unit_match?(unit, only, except)
        _other -> false
      end
    end)
  end

  defp category_match?(_category, {[], _}, {[], _}), do: true
  defp category_match?(category, {only, _}, {[], _}), do: category in only
  defp category_match?(category, {[], _}, {except, _}), do: category not in except
  defp category_match?(category, {only, _}, {except, _}), do: category in only and category not in except

  defp unit_match?(_unit, {_, []}, {_, []}), do: true
  defp unit_match?(unit, {_, only}, {_, []}), do: unit in only
  defp unit_match?(unit, {_, []}, {_, except}), do: unit not in except
  defp unit_match?(unit, {_, only}, {_, except}), do: unit in only and unit not in except

  defp wrap(term, atom), do: {atom, term}

  defp maybe_list_wrap({list, options}) when is_list(list), do: {list, options}
  defp maybe_list_wrap({other, options}), do: {[other], options}

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

  * `:backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `:only` is a unit category or unit, or a list of unit categories and units.
    The parsed unit must match one of the categories or units in order to
    be valid. This is helpful when disambiguating parsed units. For example,
    parsing "2w" could be either "2 watts" or "2 weeks". Specifying `only: :duration`
    would return "2 weeks". Specifying `only: :power` would return
    "2 watts"

  * `:except` is the oppostte of `:only`. The parsed unit must *not*
    match the specified unit or category, or unit categories and units.

  ## Notes

  * When both `:only` and `:except` options are passed, both
    conditions must be true in order to return a parsed result.

  * Only units returned by `Cldr.Unit.known_units/0` can be
    used in the `:only` and `:except` filters.

  ## Returns

  * `unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.parse! "1kg"
      Cldr.Unit.new!(1, :kilogram)

      iex> Cldr.Unit.parse! "1 tages", locale: "de"
      Cldr.Unit.new!(1, :day)

      iex> Cldr.Unit.parse!("42 candela per lux")
      Cldr.Unit.new!(42, "candela per lux")

      iex> Cldr.Unit.parse!("42 millispangels")
      ** (Cldr.UnknownUnitError) Unknown unit was detected at "spangels"

  """
  @spec parse!(binary) :: t() | no_return()

  @doc since: "3.6.0"
  def parse!(unit_string, options \\ []) do
    case parse(unit_string, options) do
      {:ok, unit} -> unit
      {:error, {exception, message}} -> raise exception, message
    end
  end

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

      iex> Cldr.Unit.parse_unit_name! "kg"
      :kilogram

      iex> Cldr.Unit.parse_unit_name! "w"
      :watt

      iex> Cldr.Unit.parse_unit_name! "w", only: :duration
      :week

      iex> Cldr.Unit.parse_unit_name! "m", only: [:year, :month, :day]
      :month

      iex> Cldr.Unit.parse_unit_name! "tages", locale: "de"
      :day

      iex> Cldr.Unit.parse_unit_name! "tag", locale: "de"
      :day

      iex> Cldr.Unit.parse_unit_name!("millispangels")
      ** (Cldr.UnknownUnitError) Unknown unit was detected at "spangels"

  """
  @doc since: "3.14.0"

  @spec parse_unit_name!(binary) :: atom() | no_return()
  def parse_unit_name!(unit_name_string, options \\ []) do
    case parse_unit_name(unit_name_string, options) do
      {:ok, unit} -> unit
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp resolve_unit_alias(unit, strings) do
    unit = String.trim(unit)
    Map.get(strings, unit, unit)
  end

  @default_use :default
  @default_format_options []

  defp create_unit(value, unit, options) do
    usage = Keyword.get(options, :usage, @default_use)
    format_options = Keyword.get(options, :format_options, @default_format_options)

    with {:ok, unit, base_conversion} <- validate_unit(unit),
         {:ok, usage} <- validate_usage(unit, usage, base_conversion) do
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

  @doc false
  def validate_usage(_unit, @default_use = usage, _base_conversion) do
    {:ok, usage}
  end

  def validate_usage(unit, usage, base_conversion) do
    with {:ok, category} <- unit_category(unit, base_conversion) do
      validate_category_usage(category, usage)
    end
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

  defp validate_categories_or_units(units_or_categories) do
    {categories, units} = Enum.split_with(units_or_categories, &(&1 in known_unit_categories()))
    invalid_units = Enum.filter(units, &(&1 not in known_units()))

    if invalid_units == [] do
      {:ok, {categories, units}}
    else
      {:error, unit_error(invalid_units)}
    end
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
  Formats a number into a string according to a unit definition
  for the current process's locale and backend.

  The current process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string/3` for full details.

  """
  @spec to_string(list_or_number :: Unit.value() | Unit.t() | [Unit.t()]) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(unit) do
    Format.to_string(unit)
  end

  @doc """
  Formats a number into a string according to a unit definition for a locale.

  During processing any `:format_options` of a `Unit.t()` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `list_or_number` is any number (integer, float or Decimal) or a
    `t:Cldr.Unit` struct or a list of `t:Cldr.Unit` structs

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options.

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `t:Cldr.Unit` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `style` is one of those returned by `Cldr.Unit.styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * `:grammatical_case` indicates that a localisation for the given
    locale and given grammatical case should be used. See `Cldr.Unit.known_grammatical_cases/0`
    for the list of known grammatical cases. Note that not all locales
    define all cases. However all locales do define the `:nominative`
    case, which is also the default.

  * `:gender` indicates that a localisation for the given
    locale and given grammatical gender should be used.
    See `Cldr.Unit.known_grammatical_genders/0`
    for the list of known grammatical genders. Note that not all locales
    define all genders.

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

  @spec to_string(
          Unit.value() | Unit.t() | list(Unit.t()),
          Cldr.backend() | Keyword.t(),
          Keyword.t()
        ) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(list_or_unit, backend, options \\ [])

  # Options but no backend
  def to_string(list_or_unit, options, []) when is_list(options) do
    Format.to_string(list_or_unit, options, [])
  end

  def to_string(list_or_unit, backend, options) do
    Format.to_string(list_or_unit, backend, options)
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  The current process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string!/3` for full details.

  """
  @spec to_string!(list_or_number :: Unit.value() | Unit.t() | [Unit.t()]) ::
          String.t() | no_return()

  def to_string!(unit) do
    Format.to_string!(unit)
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  During processing any `:format_options` of a `t:Cldr.Unit` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `number` is any number (integer, float or Decimal) or a
    `t:Cldr.Unit` struct

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `t:Cldr.Unit` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.known_styles/0`.
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
  @spec to_string!(
          Unit.value() | Unit.t() | list(Unit.t()),
          Cldr.backend() | Keyword.t(),
          Keyword.t()
        ) ::
          String.t() | no_return()

  def to_string!(unit, backend, options \\ []) do
    Format.to_string!(unit, backend, options)
  end

  ## TODO remove in ex_cldr 4.0

  @doc false
  @spec to_iolist(list_or_number :: Unit.value() | Unit.t() | [Unit.t()]) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_iolist(unit) do
    Format.to_iolist(unit)
  end

  @doc false
  @spec to_iolist(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
          {:ok, list()} | {:error, {atom, binary}}

  def to_iolist(unit, backend, options \\ []) do
    Format.to_iolist(unit, backend, options)
  end

  @doc false
  @spec to_iolist!(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...]) ::
          list() | no_return()

  def to_iolist!(unit) do
    Format.to_iolist!(unit)
  end

  @doc false
  @spec to_iolist!(Cldr.Unit.value() | Cldr.Unit.t() | [Cldr.Unit.t(), ...], Keyword.t()) ::
          list() | no_return()

  def to_iolist!(unit, backend, options \\ []) do
    Format.to_iolist!(unit, backend, options)
  end

  @doc """
  Inverts a unit

  Only "per" units can be inverted.

  """
  @spec invert(t()) :: {:ok, t()} | {:error, {module(), String.t()}}

  def invert(%Unit{value: value, base_conversion: conversion} = unit)
      when is_tuple(conversion) and is_number(value) do
    new_unit = inverted_unit(unit)

    {:ok, %{new_unit | value: invert_value(value)}}
  end

  def invert(%Unit{value: %Decimal{} = value, base_conversion: conversion} = unit)
      when is_tuple(conversion) do
    new_unit = inverted_unit(unit)

    {:ok, %{new_unit | value: invert_value(value)}}
  end

  @per Cldr.Unit.Parser.per()
  @one Decimal.new(1)

  def invert(%Unit{unit: name, value: value}) when is_atom(name) do
    case Atom.to_string(name) |> String.split(@per) do
      [_unit_name] ->
        {:error, not_invertable_error(name)}

      [left, right] ->
        new_name = right <> @per <> left
        new_value = invert_value(value)
        Cldr.Unit.new(new_name, new_value)
    end
  end

  def invert(%Unit{} = unit) do
    {:error, not_invertable_error(unit)}
  end

  defp invert_value(value) when is_number(value) do
    1 / value
  end

  defp invert_value(%Decimal{} = value) do
    Decimal.div(@one, value)
  end

  defp inverted_unit(%Unit{base_conversion: {numerator, denominator}} = unit) do
    new_conversion = {denominator, numerator}
    new_unit = %{unit | base_conversion: new_conversion}

    new_name =
      new_conversion
      |> Cldr.Unit.Parser.canonical_unit_name()
      |> maybe_translatable_unit()

    %{new_unit | unit: new_name}
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
    case Conversion.conversion_for(unit_1, unit_2) do
      {:ok, _conversion, _maybe_inverted} -> true
      {:error, _error} -> false
    end
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

  The current process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.localize/3` for further
  details.

  """
  @spec localize(t()) :: [t(), ...]
  def localize(%Unit{} = unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    localize(unit, backend, locale: locale)
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

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module.

  * `options` is a keyword list of options

  ## Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `backend.get_locale/0`.

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
      [
        Cldr.Unit.new!(:foot, 6, usage: :person_height),
        Cldr.Unit.new!(:inch, Ratio.new(6485183463413016, 137269716642252725), usage: :person_height)
      ]

  """
  @spec localize(t(), Cldr.backend(), Keyword.t()) :: [t(), ...]
  def localize(unit, backend, options \\ [])

  def localize(%Unit{} = unit, options, []) when is_list(options) do
    locale = Cldr.get_locale()
    options = Keyword.merge([locale: locale], options)
    localize(unit, locale.backend, options)
  end

  def localize(%Unit{} = unit, backend, options) when is_atom(backend) do
    with {:ok, unit_list, format_options} <- Preference.preferred_units(unit, backend, options) do
      unit = %{unit | usage: (options[:usage] || unit.usage)}
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

  * `unit` is any `t:Cldr.Unit` or any
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
  @spec display_name(Cldr.Unit.value() | Cldr.Unit.t(), Keyword.t) ::
    String.t() | {:error, {module, binary}}

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
                    |> Enum.map(fn {unit, conversion} -> {unit, conversion.systems} end)
                    |> Kernel.++(Cldr.Unit.Additional.systems_for_units())
                    |> Map.new()

  @doc """
  Returns the measurement systems for a given
  unit.

  ## Arguments

  * `unit` is any `t:Cldr.Unit` or any unit
    returned by `Cldr.Unit.known_units/0` or a
    string unit name.

  ## Returns

  * A list of measurement systems to which
    the `unit` belongs.

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.measurement_systems_for_unit :foot
      [:ussystem, :uksystem]

      iex> Cldr.Unit.measurement_systems_for_unit :meter
      [:metric, :si]

      iex> Cldr.Unit.measurement_systems_for_unit :invalid
      {:error, {Cldr.UnknownUnitError, "The unit :invalid is not known."}}

  """
  @doc since: "3.4.0"
  @spec measurement_systems_for_unit(t() | unit()) ::
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
  for prefix <- Cldr.Unit.Prefix.prefixes() do
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
        if rest == [], do: {:error, unit_error(unit)}, else: measurement_systems_for_unit(hd(rest))
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
        ussystem: %{alias: nil, description: "US System of measurement: feet, pints, etc.; pints are 16oz"},
        si: %{alias: nil, description: "SI System"}
      }

  """
  @spec known_measurement_systems ::
          %{measurement_system() => %{alias: atom(), description: String.t()}}

  def known_measurement_systems do
    @measurement_systems
  end

  @doc """
  Return a list of known measurement system names.

  ## Example

      iex> Cldr.Unit.known_measurement_system_names()
      [:metric, :si, :uksystem, :ussystem]

  """
  @doc since: "3.5.0"
  @spec known_measurement_system_names :: [measurement_system(), ...]

  def known_measurement_system_names do
    @system_names
  end

  @doc """
  Determines the preferred measurement system
  from a locale.

  See also `Cldr.Unit.known_measurement_systems/0`.

  ## Arguments

  * `locale` is any valid locale name returned by
    `Cldr.known_locale_names/0` or a `t:Cldr.LanguageTag`
    struct.  The default is `Cldr.get_locale/0`.

  * `key` is any measurement system key.
    The known keys are `:default`, `:temperature`
    and `:paper_size`. The default key is `:default`.

  ## Examples

      iex> Cldr.Unit.measurement_system_from_locale "en"
      :ussystem

      iex> Cldr.Unit.measurement_system_from_locale "en-GB"
      :uksystem

      iex> Cldr.Unit.measurement_system_from_locale "en-AU"
      :metric

      iex> Cldr.Unit.measurement_system_from_locale "en-AU-u-ms-ussystem"
      :ussystem

      iex> Cldr.Unit.measurement_system_from_locale "en-GB", :temperature
      :uksystem

      iex> Cldr.Unit.measurement_system_from_locale "en-AU", :paper_size
      :a4

      iex> Cldr.Unit.measurement_system_from_locale "en-GB", :invalid
      {:error,
       {Cldr.Unit.InvalidSystemKeyError,
        "The key :invalid is not known. Valid keys are :default, :paper_size and :temperature"}}

  """
  @doc since: "3.4.0"
  @spec measurement_system_from_locale(
          Cldr.LanguageTag.t() | Cldr.Locale.locale_name(),
          measurement_system_key() | Cldr.backend()
        ) ::
          measurement_system() | {:error, {module(), String.t()}}

  def measurement_system_from_locale(locale \\ Cldr.get_locale(), key \\ :default)

  def measurement_system_from_locale(locale, backend_or_key) when is_binary(locale) do
    case Cldr.validate_backend(backend_or_key) do
      {:ok, backend} ->
        with {:ok, locale} <- Cldr.validate_locale(locale, backend) do
          measurement_system_from_locale(locale)
        end

      {:error, _} ->
        with {:ok, locale} <- Cldr.validate_locale(locale) do
          measurement_system_from_locale(locale, backend_or_key)
        end
    end
  end

  def measurement_system_from_locale(%LanguageTag{locale: %{ms: :imperial}}, _key) do
    :uksystem
  end

  def measurement_system_from_locale(%LanguageTag{locale: %{ms: system}}, _key)
      when not is_nil(system) do
    system
  end

  def measurement_system_from_locale(%Cldr.LanguageTag{} = locale, key) do
    territory = Cldr.Locale.territory_from_locale(locale)
    measurement_system_for_territory(territory, key)
  end

  @doc since: "3.4.0"
  @spec measurement_system_from_locale(
          Locale.locale_reference(),
          Cldr.backend(),
          measurement_system_key()
        ) ::
          measurement_system() | {:error, {module(), String.t()}}

  def measurement_system_from_locale(locale, backend, key) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend) do
      measurement_system_from_locale(locale, key)
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
        duration: [:default, :media],
        energy: [:default, :food],
        length: [:default, :focal_length, :person, :person_height, :rainfall, :road,
         :snowfall, :vehicle, :visiblty],
        mass: [:default, :person],
        mass_density: [:default],
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
  @base_units @units
              |> Map.get(:base_units)
              |> Kernel.++(Cldr.Unit.Additional.base_units())
              |> Enum.uniq()
              |> Map.new()

  def base_units do
    @base_units
  end

  @doc """
  Returns the base unit for a given unit.

  ## Argument

  * `unit` is either a `t:Cldr.Unit`, an `atom` or
    a `t:String`

  ## Returns

  * `{:ok, base_unit}` or

  * `{:error, {exception, reason}}`

  ## Example

      iex> Cldr.Unit.base_unit :square_kilometer
      {:ok, :square_meter}

      iex> Cldr.Unit.base_unit :square_table
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"table\\""}}

  """

  def base_unit(%Unit{base_conversion: conversion}) do
    BaseUnit.canonical_base_unit(conversion)
  end

  def base_unit(unit_name) when is_atom(unit_name) or is_binary(unit_name) do
    with {:ok, _unit, conversion} <- Cldr.Unit.validate_unit(unit_name) do
      BaseUnit.canonical_base_unit(conversion)
    end
  end

  @deprecated "Use `Cldr.Unit.known_unit_categories/0"
  defdelegate unit_categories(), to: __MODULE__, as: :known_unit_categories

  @unit_category_inverse_map Cldr.Map.invert(@units_by_category) |> Cldr.Map.stringify_keys()

  @doc false
  def unit_category_inverse_map do
    @unit_category_inverse_map
  end

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

      iex> Cldr.Unit.unit_category :watt
      {:ok, :power}

      iex> Cldr.Unit.unit_category "kilowatt hour"
      {:ok, :energy}

      iex> Cldr.Unit.unit_category "watt hour per light year"
      {:error,
       {Cldr.Unit.UnknownCategoryError,
        "The category for \\"watt hour per light year\\" is not known."}}

  """

  @spec unit_category(Unit.t() | String.t() | atom()) ::
          {:ok, category()} | {:error, {module(), String.t()}}

  def unit_category(unit) when unit in @translatable_units do
    case Map.fetch(@unit_category_inverse_map, Kernel.to_string(unit)) do
      {:ok, category} -> {:ok, category}
      :error -> {:error, unknown_category_error(unit)}
    end
  end

  def unit_category(unit) do
    with {:ok, resolved_unit, conversion} <- validate_unit(unit) do
      if resolved_unit in @translatable_units do
        unit_category(resolved_unit)
      else
        unit_category(unit, conversion)
      end
    end
  end

  @doc false
  def unit_category(unit, conversion) do
    with {:ok, base_unit} <- BaseUnit.canonical_base_unit(conversion),
         {:ok, category} <- Map.fetch(@unit_category_inverse_map, Kernel.to_string(base_unit)) do
      {:ok, category}
    else
      :error -> {:error, unknown_category_error(unit)}
      other -> other
    end
  end

  @deprecated "Please use `Cldr.Unit.unit_category/1"
  def unit_type(unit) do
    unit_category(unit)
  end

  @doc """
  Return the grammatical gender for a
  unit.

  ## Arguments

  ## Options

  ## Returns

  ## Examples

  """
  @unknown_gender :undefined
  @doc since: "3.5.0"
  @spec grammatical_gender(t(), Keyword.t()) :: grammatical_gender()

  def grammatical_gender(unit, options \\ [])

  def grammatical_gender(%__MODULE__{} = unit, options) when is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    module = Module.concat(backend, :Unit)
    units = units_for(locale, :long)

    features =
      module.grammatical_features(@root_locale_name)
      |> Map.merge(module.grammatical_features(locale))
      |> Map.fetch!(:gender)

    Cldr.Unit.Format.traverse(unit, fn
      {:unit, unit} -> Map.fetch!(units, unit) |> Map.get(:gender, @unknown_gender)
      {:times, left_right} -> elem(left_right, features.times)
      {:per, left_right} -> elem(left_right, features.per)
      {:prefix, left_right} -> elem(left_right, features.prefix + 1)
      {:power, left_right} -> elem(left_right, features.power + 1)
    end)
  end

  def grammatical_gender(unit, options) when is_binary(unit) do
    grammatical_gender(new!(1, unit), options)
  end

  @base_unit_category_map Cldr.Config.units()
                          |> Map.get(:base_units)
                          # |> Kernel.++(Cldr.Unit.Additional.base_units())
                          |> Enum.map(fn {k, v} -> {Kernel.to_string(v), k} end)
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

      iex> Cldr.Unit.known_styles
      [:long, :short, :narrow]

  """
  @spec known_styles :: [style(), ...]
  def known_styles do
    @styles
  end

  @deprecated "Use Cldr.Unit.known_styles/0"
  defdelegate styles, to: __MODULE__, as: :known_styles

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
  @spec measurement_systems_by_territory() :: %{Locale.territory_code() => map()}
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
          :metric | :ussystem | :uksystem | :a4 | :us_letter | {:error, {module(), String.t()}}

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
      get_in(measurement_systems_by_territory(), [territory, key]) || default
    end
  end

  @doc """
  Validates a unit name and normalizes it,

  A unit name can be expressed as:

  * an `atom()` in which case the unit must be
    localizable in CLDR directly

  * or a `t:String` in which case it is parsed
    into a list of composable subunits that
    can be converted but are not guaranteed to
    be output as a localized string.

  ## Arguments

  * `unit_name` is an `atom()` or `t:String`, supplied
    as is or as part of an `t:Cldr.Unit` struct.

  ## Returns

  * `{:ok, canonical_unit_name, conversion}` where
    `canonical_unit_name` is the normalized unit name
    and `conversion` is an opaque structure used
    to convert this this unit into its base unit or

  * `{:error, {exception, reason}}`

  ## Notes

  A returned `unit_name` that is an atom is directly
  localisable (CLDR has translation data for the unit).

  A `unit_name` that is a `t:String` is composed of
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
    {:ok, unit_name, Conversions.conversion_for!(unit_name)}
  end

  @aliases Alias.aliases() |> Map.keys()
  def validate_unit(unit_name) when unit_name in @aliases do
    unit_name
    |> Alias.alias()
    |> validate_unit()
  end

  def validate_unit(unit_name) when is_atom(unit_name) do
    unit_name
    |> Atom.to_string()
    |> validate_unit()
  end

  def validate_unit(unit_name) when is_binary(unit_name) do
    unit_name
    |> normalize_unit_name()
    |> maybe_translatable_unit()
    |> return_parsed_unit()
  end

  def validate_unit(%Unit{unit: unit_name, base_conversion: base_conversion}) do
    {:ok, unit_name, base_conversion}
  end

  def validate_unit(unknown_unit) do
    {:error, unit_error(unknown_unit)}
  end

  defp return_parsed_unit(unit_name) when is_atom(unit_name) do
    validate_unit(unit_name)
  end

  defp return_parsed_unit(unit_name) do
    with {:ok, parsed} <- Parser.parse_unit(unit_name) do
      name =
        parsed
        |> Parser.canonical_unit_name()
        |> maybe_translatable_unit()

      {:ok, name, parsed}
    end
  end

  @doc false
  def normalize_unit_name(name) when is_binary(name) do
    String.replace(name, [" ", "-"], "_")
  end

  @doc false
  def maybe_translatable_unit(name) do
    atom_name = String.to_existing_atom(name)
    if atom_name in known_units(), do: atom_name, else: name

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
  Validates a grammatical case and normalizes it to a
  standard downcased atom form

  """
  @doc since: "3.5.0"
  def validate_grammatical_case(grammatical_case) when grammatical_case in @grammatical_case do
    {:ok, grammatical_case}
  end

  def validate_grammatical_case(grammatical_case) when is_binary(grammatical_case) do
    grammatical_case
    |> String.downcase()
    |> String.to_existing_atom()
    |> validate_grammatical_case()
  catch
    ArgumentError ->
      {:error, grammatical_case_error(grammatical_case)}
  end

  def validate_grammatical_case(grammatical_case) do
    {:error, grammatical_case_error(grammatical_case)}
  end

  @doc false
  def validate_grammatical_gender(nil, default_gender, locale) do
    validate_grammatical_gender(default_gender, locale)
  end

  def validate_grammatical_gender(grammatical_gender, _default_gender, locale) do
    validate_grammatical_gender(grammatical_gender, locale)
  end

  @doc """
  Validates a grammatical gender and normalizes it to a
  standard downcased atom form

  """
  @doc since: "3.5.0"
  def validate_grammatical_gender(grammatical_gender, locale \\ Cldr.default_locale())

  def validate_grammatical_gender(grammatical_gender, %LanguageTag{} = locale)
      when is_atom(grammatical_gender) do
    with {:ok, genders} = Module.concat(locale.backend, :Unit).grammatical_gender(locale) do
      if grammatical_gender in genders do
        {:ok, grammatical_gender}
      else
        {:error, grammatical_gender_error(grammatical_gender, genders, locale)}
      end
    end
  end

  def validate_grammatical_gender(grammatical_gender, %LanguageTag{} = locale)
      when is_binary(grammatical_gender) do
    grammatical_gender
    |> String.downcase()
    |> String.to_existing_atom()
    |> validate_grammatical_gender(locale)
  catch
    ArgumentError ->
      {:error, grammatical_gender_error(grammatical_gender, locale)}
  end

  @doc """
  Convert a ratio, Decimal or integer `t:Unit` to a float `t:Unit`
  """
  @doc since: "3.5.0"
  def to_float_unit(%Unit{value: %Ratio{} = value} = unit) do
    value = Ratio.to_float(value)
    %{unit | value: value}
  end

  def to_float_unit(%Unit{value: value} = unit) when is_integer(value) do
    value = 1.0 * value
    %{unit | value: value}
  end

  def to_float_unit(%Unit{value: %Decimal{} = value} = unit) do
    value = Decimal.to_float(value)
    %{unit | value: value}
  end

  def to_float_unit(%Unit{} = other) do
    other
  end

  @deprecated "Use Cldr.Unit.to_float_unit/1"
  defdelegate ratio_to_float(unit), to: __MODULE__, as: :to_float_unit

  @doc """
  Convert a ratio, float or integer `t:Unit` to a Decimal `t:Unit`
  """
  @doc since: "3.5.0"
  def to_decimal_unit(%Unit{value: %Ratio{} = value} = unit) do
    value = Decimal.div(Decimal.new(value.numerator), Decimal.new(value.denominator))
    %{unit | value: value}
  end

  def to_decimal_unit(%Unit{value: value} = unit) when is_float(value) do
    value = Decimal.from_float(value)
    %{unit | value: value}
  end

  def to_decimal_unit(%Unit{value: value} = unit) when is_integer(value) do
    value = Decimal.new(value)
    %{unit | value: value}
  end

  def to_decimal_unit(%Unit{} = other) do
    other
  end

  @deprecated "Use Cldr.Unit.to_decimal_unit/1"
  defdelegate ratio_to_decimal(unit), to: __MODULE__, as: :to_decimal_unit

  @doc false
  def unknown_base_unit_error(unit_name) do
    {Cldr.Unit.UnknownBaseUnitError, "Base unit for #{inspect(unit_name)} is not known"}
  end

  @doc false
  def unit_error(nil) do
    {
      Cldr.UnknownUnitError,
      "A unit must be provided, for example 'Cldr.Unit.string(123, unit: :meter)'."
    }
  end

  def unit_error([unit]) do
    {Cldr.UnknownUnitError, "The unit #{inspect(unit)} is not known."}
  end

  def unit_error(units) when is_list(units) do
    units = Enum.sort(units)
    {Cldr.UnknownUnitError, "The units #{inspect(units)} are not known."}
  end

  def unit_error(unit) do
    {Cldr.UnknownUnitError, "The unit #{inspect(unit)} is not known."}
  end

  @doc false
  def unit_category_error(category) do
    {Cldr.Unit.UnknownUnitCategoryError, "The unit category #{inspect(category)} is not known."}
  end

  @doc false
  def unit_categories_error([category]) do
    unit_category_error(category)
  end

  @doc false
  def unit_categories_error(categories) do
    {Cldr.Unit.UnknownUnitCategoryError, "The unit categories #{inspect(categories)} are not known."}
  end

  @doc false
  def unknown_category_error(unit) do
    {Cldr.Unit.UnknownCategoryError, "The category for #{inspect(unit)} is not known."}
  end

  @doc false
  def style_error(style) do
    {Cldr.UnknownFormatError, "The unit style #{inspect(style)} is not known."}
  end

  @doc false
  def grammatical_case_error(grammatical_case) do
    {
      Cldr.UnknownGrammaticalCaseError,
      "The grammatical case #{inspect(grammatical_case)} " <>
        "is not known. The valid cases are #{inspect(@grammatical_case)}"
    }
  end

  @doc false
  def grammatical_gender_error(grammatical_gender, known_genders, locale) do
    {
      Cldr.UnknownGrammaticalGenderError,
      "The locale #{inspect(locale.cldr_locale_name)} does not define " <>
        "a grammatical gender #{inspect(grammatical_gender)}. " <>
        "The valid genders are #{inspect(known_genders)}"
    }
  end

  def grammatical_gender_error(grammatical_gender, _locale) do
    {
      Cldr.UnknownGrammaticalGenderError,
      "The grammatical gender #{inspect(grammatical_gender)} is invalid"
    }
  end

  @doc false
  def incompatible_units_error(%Unit{unit: unit_1}, unit_2) do
    incompatible_units_error(unit_1, unit_2)
  end

  def incompatible_units_error(unit_1, %Unit{unit: unit_2}) do
    incompatible_units_error(unit_1, unit_2)
  end

  def incompatible_units_error(unit_1, unit_2) do
    {
      Unit.IncompatibleUnitsError,
      "Operations can only be performed between units with the same base unit. " <>
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

  @doc false
  def no_pattern_error(unit, locale, style) do
    {
      Cldr.Unit.NoPatternError,
      "No localisation pattern was found for unit #{inspect(unit)} in " <>
        "locale #{inspect(locale.requested_locale_name)} for " <>
        "style #{inspect(style)}"
    }
  end

  @doc false
  def not_invertable_error(unit) do
    {
      Cldr.Unit.NotInvertableError,
      "The unit #{inspect(unit)} cannot be inverted. Only compound 'per' units " <>
        "can be inverted"
    }
  end

  @doc false
  def not_parseable_error(string) do
    {
      Cldr.Unit.NotParseableError,
      "The string #{inspect(string)} could not be parsed as a unit and a value"
    }
  end

  @doc false
  def ambiguous_unit_error(unit, units) do
    units = Enum.sort(units)

    {
      Cldr.Unit.AmbiguousUnitError,
      "The string #{inspect String.trim(unit)} ambiguously resolves to #{inspect units}"
    }
  end

  @doc false
  defp category_unit_match_error(unit, only, {[], []}) do
    {
      Cldr.Unit.CategoryMatchError,
      "None of the units #{inspect Enum.sort(unit)} belong to a unit or category matching " <>
      "only: #{inspect flatten(only)}"
    }
  end

  defp category_unit_match_error(unit, {[], []}, except) do
    {
      Cldr.Unit.CategoryMatchError,
      "None of the units #{inspect Enum.sort(unit)} belong to a unit or category matching " <>
      "except: #{inspect flatten(except)}"
    }
  end

  defp category_unit_match_error(unit, only, except) do
    {
      Cldr.Unit.CategoryMatchError,
      "None of the units #{inspect Enum.sort(unit)} belong to a unit or category matching " <>
      "only: #{inspect flatten(only)} except: #{inspect flatten(except)}"
    }
  end

  defp flatten(tuple) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> List.flatten()
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

  defimpl Cldr.DisplayName do
    def display_name(unit, options) do
      Cldr.Unit.display_name(unit, options)
    end
  end

  @doc false
  def exclude_protocol_implementation(module) do
    exclusions =
      :ex_unit
      |> Application.get_env(:exclude_protocol_implementations, [])
      |> List.wrap()

    if module in exclusions, do: true, else: false
  end
end
