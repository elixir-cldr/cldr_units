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
  alias Cldr.Unit
  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Alias

  @type t :: %Unit{}
  @type unit :: atom()
  @type style :: atom()

  @styles [:long, :short, :narrow]
  @default_style :long

  defstruct unit: nil, value: 0

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
  Returns a new `Unit.t` struct.

  ## Options

  * `value` is any float, integer or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.units`

  ## Returns

  * `unit` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.new(23, :gallon)
      #Unit<:gallon, 23>

      iex> Cldr.Unit.new(:gallon, 23)
      #Unit<:gallon, 23>

      iex> Cldr.Unit.new(14, :gadzoots)
      {:error, {Cldr.UnknownUnitError,
        "The unit :gadzoots is not known."}}

  """
  def new(value, unit) when is_number(value) do
    with {:ok, unit} <- validate_unit(unit) do
      %Unit{unit: unit, value: value}
    end
  end

  def new(unit, value) when is_number(value) do
    new(value, unit)
  end

  def new(%Decimal{} = value, unit) do
    with {:ok, unit} <- validate_unit(unit) do
      %Unit{unit: unit, value: value}
    end
  end

  def new(unit, %Decimal{} = value) do
    new(value, unit)
  end

  @doc """
  Returns a new `Unit.t` struct or raises on error.

  ## Options

  * `value` is any float, integer or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.units/0`

  ## Returns

  * `unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.new! 23, :gallon
      #Unit<:gallon, 23>

      Cldr.Unit.new! 14, :gadzoots
      ** (Cldr.UnknownUnitError) The unit :gadzoots is not known.
          (ex_cldr_units) lib/cldr/unit.ex:57: Cldr.Unit.new!/2

  """
  def new!(unit, value) do
    case new(unit, value) do
      {:error, {exception, message}} -> raise exception, message
      unit -> unit
    end
  end

  @doc """
  Returns a boolean indicating if two units are
  of the same unit type.

  ## Options

  * `unit_1` and `unit_2` are any units returned by
    `Cldr.Unit.new/2` or units returned by `Cldr.Unit.units/0`

  ## Returns

  * `true` or `false`

  ## Examples

      iex> Cldr.Unit.compatible? :foot, :meter
      true

      iex> Cldr.Unit.compatible? Cldr.Unit.new!(:foot, 23), :meter
      true

      iex> Cldr.Unit.compatible? :foot, :liter
      false

  """
  def compatible?(unit_1, unit_2) do
    with {:ok, unit_1} <- validate_unit(unit_1),
         {:ok, unit_2} <- validate_unit(unit_2) do
      unit_type(unit_1) == unit_type(unit_2) && Conversion.factor(unit_1) != :not_convertible &&
        Conversion.factor(unit_2) != :not_convertible
    else
      _ -> false
    end
  end

  @doc """
  Formats a number into a string according to a unit definition for a locale.

  ## Options

  * `number` is any number (integer, float or Decimal)

  * `unit` is any unit returned by `Cldr.Unit.units/2`

  * `options` are:

    * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_current_locale/0`

    * `:style` is one of those returned by `Cldr.Unit.available_styles`.
      The current styles are `:long`, `:short` and `:narrow`.
      The default is `style: :long`

    * Any other options are passed to `Cldr.Number.to_string/2`
      which is used to format the `number`

  ## Returns

  * `{;ok, formatted_string}` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.to_string 123, unit: :gallon
      {:ok, "123 gallons"}

      iex> Cldr.Unit.to_string 1, unit: :gallon
      {:ok, "1 gallon"}

      iex> Cldr.Unit.to_string 1, unit: :gallon, locale: "af"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.to_string 1, unit: :gallon, locale: "af-NA"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.to_string 1, unit: :gallon, locale: "bs"
      {:ok, "1 galona"}

      iex> Cldr.Unit.to_string 1234, unit: :gallon, format: :long
      {:ok, "1 thousand gallons"}

      iex> Cldr.Unit.to_string 1234, unit: :gallon, format: :short
      {:ok, "1K gallons"}

      iex> Cldr.Unit.to_string 1234, unit: :megahertz
      {:ok, "1,234 megahertz"}

      iex> Cldr.Unit.to_string 1234, unit: :megahertz, style: :narrow
      {:ok, "1,234MHz"}

      iex> Cldr.Unit.to_string 123, unit: :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

      iex> Cldr.Unit.to_string 123, unit: :blabber, locale: "en"
      {:error, {Cldr.UnknownUnitError, "The unit :blabber is not known."}}

  """
  @spec to_string(Cldr.Math.number_or_decimal(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {atom, binary}}
  def to_string(number, options \\ [])

  def to_string(%Unit{unit: unit, value: value}, options) when is_list(options) do
    to_string(value, Keyword.put(options, :unit, unit))
  end

  def to_string(number, options) when is_list(options) do
    with {locale, style, options} <- normalize_options(options),
         {:ok, locale} <- Cldr.validate_locale(locale),
         {:ok, style} <- validate_style(style),
         {:ok, unit} <- validate_unit(options[:unit]) do
      {:ok, to_string(number, unit, locale, style, options)}
    end
  end

  @doc """
  Formats a list using `to_string/3` but raises if there is
  an error.

  ## Options

  * `number` is any number (integer, float or Decimal)

  * `unit` is any unit returned by `Cldr.Unit.units/2`

  * `options` are:

    * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_current_locale/0`

    * `:style` is one of those returned by `Cldr.Unit.available_styles`.
      The current styles are `:long`, `:short` and `:narrow`.
      The default is `style: :long`

    * Any other options are passed to `Cldr.Number.to_string/2`
      which is used to format the `number`

  ## Returns

  * `formatted_string` or

  * raises and exception

  ## Examples

      iex> Cldr.Unit.to_string! 123, unit: :gallon
      "123 gallons"

      iex> Cldr.Unit.to_string! 1, unit: :gallon
      "1 gallon"

      iex> Cldr.Unit.to_string! 1, unit: :gallon, locale: "af"
      "1 gelling"

  """
  @spec to_string!(Math.decimal_or_number(), Keyword.t()) :: String.t() | no_return()
  def to_string!(number, options \\ []) do
    case to_string(number, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @spec to_string(
          Math.decimal_or_number(),
          unit,
          Locale.locale_name() | LanguageTag.t(),
          style,
          Keyword.t()
        ) :: String.t()

  defp to_string(number, unit, locale, style, options) do
    with {:ok, number_string} <- Cldr.Number.to_string(number, options ++ [locale: locale]),
         {:ok, patterns} <- pattern_for(locale, style, unit) do
      pattern = Cldr.Number.Ordinal.pluralize(number, locale, patterns)

      number_string
      |> Substitution.substitute(pattern)
      |> :erlang.iolist_to_binary()
    end
  end

  @doc """
  Return the value of the Unit struct

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Returns

  * an integer, float or Decimal representing the amount
  of the unit

  ## Example

      iex(1)> Cldr.Unit.value Cldr.Unit.new(:kilogram, 23)
      23

  """
  @spec value(unit :: Unit.t) :: Cldr.Math.number_or_decimal()
  def value(%Unit{value: value}) do
    value
  end

  @unit_tree Cldr.default_locale()
             |> Map.get(:cldr_locale_name)
             |> Cldr.Config.get_locale()
             |> Map.get(:units)
             |> Map.get(:short)
             |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
             |> Enum.into(%{})

  @doc """
  Returns a list of the known unit categories.

  ## Example

      iex> Cldr.Unit.unit_types
      [:acceleration, :angle, :area, :concentr, :consumption, :coordinate, :digital,
       :duration, :electric, :energy, :frequency, :length, :light, :mass, :power,
       :pressure, :speed, :temperature, :volume]

  """
  @unit_types Map.keys(@unit_tree)
  def unit_types do
    @unit_types
  end

  @doc """
  Returns a list of the unit types and associated
  units

  ## Example

      Cldr.Unit.unit_tree
      %{
        acceleration: [:g_force, :meter_per_second_squared],
        angle: [:arc_minute, :arc_second, :degree, :radian, :revolution],
        area: [:acre, :hectare, :square_centimeter, :square_foot, :square_inch,
               :square_kilometer, :square_meter, :square_mile, :square_yard],
        concentr: [:karat, :milligram_per_deciliter, :millimole_per_liter,
                   :part_per_million]
        ...

  """
  @spec unit_tree :: [atom, ...]
  def unit_tree do
    @unit_tree
  end

  @doc """
  Returns the units associated with a given unit type

  ## Options

  * `unit` is any units returned by
    `Cldr.Unit.new/2` or units returned by `Cldr.Unit.units/0`

  ## Returns

  * a valid unit or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.unit_type :pint_metric
      :volume

      iex> Cldr.Unit.unit_type :stone
      :mass

  """
  @spec unit_type(Unit.t() | String.t() | atom()) ::
          atom() | {:error, {Exception.t(), String.t()}}
  def unit_type(unit) do
    with {:ok, unit} <- validate_unit(unit) do
      type_map(unit)
    end
  end

  @doc """
  Returns the known units.

  ## Example

      Cldr.Unit.units
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
         |> Map.values()
         |> List.flatten()

  @spec units :: [atom, ...]
  def units do
    @units
  end

  @doc """
  Returns the units for a given unit type

  ## Options

  * `type` is any unit type returned by
    `Cldr.Unit.unit_types/0`

  ## Returns

  * a list of units

  ## Examples

      iex> Cldr.Unit.units(:length)
      [:astronomical_unit, :centimeter, :decimeter, :fathom, :foot, :furlong, :inch,
       :kilometer, :light_year, :meter, :micrometer, :mile, :mile_scandinavian,
       :millimeter, :nanometer, :nautical_mile, :parsec, :picometer, :point, :yard]

  """
  @spec units(atom) :: [atom, ...]
  def units(type) when type in @unit_types do
    Map.get(unit_tree(), type)
  end

  def units(type) do
    {:error, unit_type_error(type)}
  end

  @doc """
  Returns a list of units that are within the
  specified jaro distance of the provided unit.

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.units/0` or by
    `Cldr.Unit.new/2`

  * `distance` is a float between 0.0 and 1.0 representing
    the jaro distance above which a unit must match in order
    to be returned.  The default is 0.75

  ## Returns

  * a list of tagged tuples of the form `{jaro_distance, unit}`
    sorted in decending jaro distance order or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.jaro_match :foot
      [{1.0, :foot}]

      iex> Cldr.Unit.jaro_match :meter
      [
        {1.0, :meter},
        {0.7708333333333334, :meter_per_second},
        {0.7592592592592592, :kilometer_per_hour}
      ]

  """
  @default_distance 0.75
  @spec jaro_match(unit, number) :: [{float, unit}, ...] | []
  def jaro_match(unit, distance \\ @default_distance)

  def jaro_match(%Unit{unit: unit}, distance) do
    jaro_match(unit, distance)
  end

  def jaro_match(unit, distance) do
    unit
    |> Kernel.to_string()
    |> match_list(distance)
  end

  @doc """
  Returns the unit closed in jaro distance to the
  provided unit

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.units/0` or by
    `Cldr.Unit.new/2`

  * `distance` is a float between 0.0 and 1.0 representing
    the jaro distance above which a unit must match in order
    to be returned.  The default is 0.75

  ## Returns

  * a `Unit.t` struct or

  * `nil`

  ## Examples

      iex> Cldr.Unit.best_match :ft
      :fathom

      iex> Cldr.Unit.best_match :zippity
      nil

  """
  def best_match(unit, distance \\ @default_distance) do
    unit
    |> jaro_match(distance)
    |> return_best_match
  end

  defp return_best_match([]) do
    nil
  end

  defp return_best_match([{_distance, unit} | _rest]) do
    unit
  end

  @doc """
  Returns a list of units that are compatible with the
  provided unit.

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.units/0` or by
    `Cldr.Unit.new/2`

  * `options` is a keyword list of options,  The valid
    options are:

    * `:jaro` is a boolean which determines if the match
      is to use the jaro distance.  The default is `false`

    * `distance` is a float between 0.0 and 1.0 representing
      the jaro distance above which a unit must match in order
      to be returned.  The default is 0.75

  ## Returns

  * a list of tuples of the form `{jaro_distance, unit}`
    sorted in decending jaro distance order, or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.compatible_units :foot
      [:astronomical_unit, :centimeter, :decimeter, :fathom, :foot, :furlong, :inch,
       :kilometer, :light_year, :meter, :micrometer, :mile, :mile_scandinavian,
       :millimeter, :nanometer, :nautical_mile, :parsec, :picometer, :point, :yard]

      iex> Cldr.Unit.compatible_units :me, jaro: true
      [{0.7999999999999999, :meter}]

  """
  @default_options [jaro: false, distance: @default_distance]
  @spec compatible_units(unit, Keyword.t() | Map.t()) :: [unit, ...] | [{float, unit}, ...] | []

  def compatible_units(unit, options \\ @default_options)

  def compatible_units(unit, options) when is_list(options) do
    options = Keyword.merge(@default_options, options) |> Enum.into(%{})
    compatible_units(unit, options)
  end

  def compatible_units(unit, %{jaro: false}) do
    with {:ok, unit} <- validate_unit(unit) do
      type = unit_type(unit)
      unit_tree()[type]
    end
  end

  def compatible_units(unit, %{jaro: true, distance: distance}) when is_number(distance) do
    unit = Kernel.to_string(unit)

    case jaro_match(unit, distance) do
      jaro_list when is_list(jaro_list) -> compatible_list(jaro_list, unit)
      other -> other
    end
  end

  @string_units Enum.map(@units, &Atom.to_string/1)
  @spec match_list(unit, number) :: [{float, unit}, ...] | []
  defp match_list(unit, distance) when is_binary(unit) and is_number(distance) do
    @string_units
    |> Enum.map(fn u -> {String.jaro_distance(unit, u), String.to_existing_atom(u)} end)
    |> Enum.filter(&(elem(&1, 0) >= distance))
    |> Enum.sort(&(elem(&1, 0) > elem(&2, 0)))
  end

  @spec compatible_list([{float, unit}, ...], unit) :: [{float, unit}, ...] | []
  defp compatible_list(jaro_list, unit) when is_list(jaro_list) do
    with {:ok, unit} <- validate_unit(unit) do
      Enum.filter(jaro_list, fn
        {_distance, u} -> unit_type(u) == unit_type(unit)
        u -> unit_type(u) == unit_type(unit)
      end)
    else
      _ ->
        # Use the best match as the match key
        [{_, unit} | _] = jaro_list
        compatible_list(jaro_list, unit)
    end
  end

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

  defp type_map(unit) do
    with {:ok, unit} <- validate_unit(unit) do
      type_map()
      |> Map.get(unit)
    end
  end

  defp units_for(locale \\ Cldr.get_current_locale(), style \\ @default_style)

  defp units_for(%LanguageTag{cldr_locale_name: cldr_locale_name}, style) do
    units_for(cldr_locale_name, style)
  end

  # Generate the functions that encapsulate the unit data from CDLR
  for locale_name <- Cldr.known_locale_names() do
    locale_data =
      locale_name
      |> Cldr.Config.get_locale()
      |> Map.get(:units)

    for style <- @styles do
      units =
        Map.get(locale_data, style)
        |> Enum.map(&elem(&1, 1))
        |> Cldr.Map.merge_map_list()
        |> Enum.into(%{})

      defp units_for(unquote(locale_name), unquote(style)) do
        unquote(Macro.escape(units))
      end
    end
  end

  defp pattern_for(%LanguageTag{cldr_locale_name: locale_name}, style, unit) do
    with {:ok, style} <- validate_style(style),
         {:ok, unit} <- validate_unit(unit),
         pattern = Map.get(units_for(locale_name, style), unit) do
      {:ok, pattern}
    end
  end

  defp pattern_for(locale_name, style, unit) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name) do
      pattern_for(locale, style, unit)
    end
  end

  @type_map @unit_tree
            |> Enum.map(fn {k, v} ->
              k = List.duplicate(k, length(v))
              Enum.zip(v, k)
            end)
            |> List.flatten()
            |> Enum.into(%{})

  defp type_map do
    @type_map
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

  @doc """
  Validates a unit name and normalizes it to a
  standard downcased atom form
  """
  def validate_unit(unit) when unit in @units do
    {:ok, unit}
  end

  @aliases Alias.aliases() |> Map.keys()
  def validate_unit(unit) when unit in @aliases do
    unit
    |> Alias.alias()
    |> validate_unit
  end

  def validate_unit(unit) when is_binary(unit) do
    unit
    |> String.downcase()
    |> String.to_existing_atom()
    |> validate_unit()
  rescue
    ArgumentError ->
      {:error, unit_error(unit)}
  end

  def validate_unit(%Unit{unit: unit}) do
    {:ok, unit}
  end

  def validate_unit(unit) do
    {:error, unit_error(unit)}
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
  def unit_type_error(type) do
    {Cldr.Unit.UnknownUnitTypeError, "The unit type #{inspect(type)} is not known."}
  end

  @doc false
  def style_error(style) do
    {Cldr.UnknownFormatError, "The unit style #{inspect(style)} is not known."}
  end

  @doc false
  def incompatible_unit_error(unit_1, unit_2) do
    {
      Unit.IncompatibleUnitError,
      "Operations can only be performed between units of the same type. " <>
        "Received #{inspect(unit_1)} and #{inspect(unit_2)}"
    }
  end

  defimpl String.Chars do
    def to_string(unit) do
      Unit.to_string(unit)
    end
  end

  defimpl Inspect, for: Cldr.Unit do
    def inspect(unit, _opts) do
      "#Unit<#{inspect(unit.unit)}, #{inspect(unit.value)}>"
    end
  end
end
