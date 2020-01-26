defmodule Cldr.Unit do
  @moduledoc """
  Supports the CLDR Units definitions which provide for the localization of many
  unit types.

  The primary public API defines:

  * `Cldr.Unit.to_string/3` which, given a number and a unit name or unit list will output a localized string

  * `Cldr.Unit.units/0` identifies the available units for localization

  * `Cldr.Unit.{add, sub, mult, div}/2` to support basic unit mathematics between
    units of compatible type (like length or volume)

  * `Cldr.Unit.convert/2` to convert one unit to another unit as long as they
    are convertable.

  * `Cldr.Unit.decompose/2` to take a unit and return a list of units decomposed
    by a list of smaller units.

  """

  alias Cldr.Substitution
  alias Cldr.LanguageTag
  alias Cldr.Locale
  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Alias
  alias Cldr.Unit
  alias Cldr.Unit.Math

  @enforce_keys [:unit, :value]
  defstruct unit: nil, value: 0

  @type unit :: atom()
  @type style :: atom()
  @type value :: Cldr.Math.number_or_decimal()
  @type t :: %Unit{unit: unit, value: value}

  @default_style :long
  @styles [:long, :short, :narrow]

  defdelegate convert(unit_1, to_unit), to: Cldr.Unit.Conversion
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

  @doc """
  Returns a new `Unit.t` struct.

  ## Options

  * `value` is any float, integer or `Decimal`

  * `unit` is any unit returned by `Cldr.Unit.units/0`

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
  @spec new(unit() | value(), value() | unit()) :: t() | {:error, {module(), String.t()}}

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
  @spec new!(unit() | value(), value() | unit()) :: t() | no_return()

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
  @spec compatible?(unit(), unit()) :: boolean
  def compatible?(unit_1, unit_2) do
    with {:ok, unit_1} <- validate_unit(unit_1),
         {:ok, unit_2} <- validate_unit(unit_2) do
      unit_category(unit_1) == unit_category(unit_2)
    else
      _ -> false
    end
  end

  @doc """
  Formats a number into a string according to a unit definition for a locale.

  ## Arguments

  * `list_or_number` is any number (integer, float or Decimal) or a
    `Cldr.Unit.t()` struct or a list of `Cldr.Unit.t()` structs

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend/0`.

  * `options` is a keyword list of options

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.units/0`. Ignored if
    the number to be formatted is a `Cldr.Unit.t()` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * `:per` allows compound units to be formatted. For example, assume
    we want to format a string which represents "kilograms per second".
    There is no such unit defined in CLDR (or perhaps anywhere!).
    If however we define the unit `unit = Cldr.Unit.new(:kilogram, 20)`
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

      iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: :foot, style: :narrow, per: :second
      {:ok, "1,234′/s"}

      iex> Cldr.Unit.to_string 1234, MyApp.Cldr, unit: :foot, per: :second
      {:ok, "1,234 feet per second"}

      iex> unit = Cldr.Unit.new(123, :foot)
      iex> Cldr.Unit.to_string unit, MyApp.Cldr
      {:ok, "123 feet"}

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

      iex> Cldr.Unit.to_string 123, MyApp.Cldr, unit: :blabber, locale: "en"
      {:error, {Cldr.UnknownUnitError, "The unit :blabber is not known."}}

  """
  @spec to_string(
          list_or_number :: value | t() | list(t()),
          backend_or_options :: Cldr.backend() | Keyword.t(),
          options :: Keyword.t()
        ) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(list_or_number, backend \\ Cldr.default_backend(), options \\ [])

  def to_string(list_or_number, options, []) when is_list(options) do
    to_string(list_or_number, Cldr.default_backend(), options)
  end

  def to_string(unit_list, backend, options) when is_list(unit_list) do
    with {locale, _style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale) do
      options = Map.to_list(options)

      list_options =
        options
        |> Keyword.get(:list_options, [])
        |> Keyword.put(:locale, locale)

      unit_list
      |> Enum.map(&to_string!(&1, backend, options ++ [locale: locale]))
      |> Cldr.List.to_string(backend, list_options)
    end
  end

  def to_string(%Unit{unit: unit, value: value}, backend, options) when is_list(options) do
    options = Keyword.put(options, :unit, unit)
    to_string(value, backend, options)
  end

  def to_string(number, backend, options) when is_list(options) do
    with {locale, style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale),
         {:ok, style} <- validate_style(style),
         {:ok, unit} <- validate_unit(options[:unit]) do
      {:ok, to_string(number, unit, locale, style, backend, options)}
    end
  end

  @doc """
  Formats a list using `to_string/3` but raises if there is
  an error.

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

  * raises and exception

  ## Examples

      iex> Cldr.Unit.to_string! 123, MyApp.Cldr, unit: :gallon
      "123 gallons"

      iex> Cldr.Unit.to_string! 1, MyApp.Cldr, unit: :gallon
      "1 gallon"

      iex> Cldr.Unit.to_string! 1, MyApp.Cldr, unit: :gallon, locale: "af"
      "1 gelling"

  """
  @spec to_string!(value(), Cldr.backend() | Keyword.t(), Keyword.t()) :: String.t() | no_return()

  def to_string!(number, backend \\ Cldr.default_backend(), options \\ []) do
    case to_string(number, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @spec to_string(
          Cldr.Math.number_or_decimal(),
          unit,
          Locale.locale_name() | LanguageTag.t(),
          style,
          Cldr.backend(),
          map()
        ) :: String.t()

  defp to_string(number, unit, locale, style, backend, %{per: nil} = options) do
    with {:ok, number_string} <-
           Cldr.Number.to_string(number, backend, Map.to_list(options)),
         {:ok, patterns} <- pattern_for(locale, style, unit, backend) do
      cardinal_module = Module.concat(backend, Number.Cardinal)
      pattern = cardinal_module.pluralize(number, locale, patterns)

      [number_string]
      |> Substitution.substitute(pattern)
      |> :erlang.iolist_to_binary()
    end
  end

  defp to_string(number, unit, locale, style, backend, %{per: per} = options) do
    with {:ok, per_pattern} <- per_pattern_for(locale, style, per, backend) do
      unit_string = to_string(number, unit, locale, style, backend, Map.put(options, :per, nil))

      if length(per_pattern) <= 2 do
        [unit_string]
        |> Substitution.substitute(per_pattern)
      else
        [unit_string, localize_per_unit(per, locale, style)]
        |> Substitution.substitute(per_pattern)
      end
      |> :erlang.iolist_to_binary()
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

  @doc """
  Return the value of the Unit struct

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Returns

  * an integer, float or Decimal representing the amount
  of the unit

  ## Example

      iex> Cldr.Unit.value Cldr.Unit.new(:kilogram, 23)
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
             |> Enum.into(%{})

  @doc """
  Decomposes a unit into subunits.

  Any list compatible units can be provided
  however a list of units of decreasing scale
  is recommended.  For example `[:foot, :inch]`
  or `[:kilometer, :meter, :centimeter, :millimeter]`

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `decompose_list` is a list of valid units (one or
    more from the list returned by `Cldr.units/0`). All
    units must be from the same category.

  ## Returns

  * a list of units after decomposition or an error
    tuple

  ## Examples

      iex> u = Cldr.Unit.new(10.3, :foot)
      iex> Cldr.Unit.decompose u, [:foot, :inch]
      [Cldr.Unit.new(:foot, 10), Cldr.Unit.new(:inch, 4)]

      iex> u = Cldr.Unit.new(:centimeter, 1111)
      iex> Cldr.Unit.decompose u, [:kilometer, :meter, :centimeter, :millimeter]
      [Cldr.Unit.new(:meter, 11), Cldr.Unit.new(:centimeter, 11)]

  """
  @spec decompose(unit :: Unit.t(), decompose_list :: [Unit.unit(), ...]) ::
          [Unit.t(), ...] | {:error, {module(), String.t()}}

  def decompose(unit, []) do
    [unit]
  end

  def decompose(unit, [h | []]) do
    new_unit =
      unit
      |> Conversion.convert!(h)
      |> Math.round()
      |> Math.trunc()

    if zero?(new_unit) do
      []
    else
      [new_unit]
    end
  end

  def decompose(unit, [h | t]) do
    new_unit = Conversion.convert!(unit, h)
    {integer_unit, remainder} = int_rem(new_unit)

    if zero?(integer_unit) do
      decompose(remainder, t)
    else
      [integer_unit | decompose(remainder, t)]
    end
  end

  @doc """
  Localizes a unit according to a territory

  A territory can be derived from a `locale_name`
  or `Cldr.LangaugeTag.t()`.

  Use this function if you have a unit which
  should be presented in a user interface using
  units relevant to the audience. For example, a
  unit `#Unit<100, :meter>` might be better
  presented to a US audiance as `#Unit<328, :foot>`.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `usage` is the way in which the unit is intended
    to be used.  The available `usage` varyies according
    to the unit category.  See `Cldr.Unit.unit_preferences/0`.

  * `options` is a keyword list of options

  ## Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:territory` is any valid territory code returned by
    `Cldr.known_territories/0`. The default is the territory defined
    as part of the `:locale`.

  * `:scope` may be set to `:small` to indicate that a unit conversion
    intended for "small" unit sizes is preferred. In some territories it is
    customary to use different units for "small" sizes from those that
    are "large".

  * `:style` may be set to `:informal` to indicate that a more informal
    unit conversion be applied.

  ## Examples

      iex> Cldr.Unit.localize(Cldr.Unit.new(100, :meter), :person, territory: :US)
      [Cldr.Unit.new(:inch, 3937)]

      iex> Cldr.Unit.localize(Cldr.Unit.new(100, :meter), :person, territory: :US, style: :informal)
      [Cldr.Unit.new(:foot, 328), Cldr.Unit.new(:inch, 1)]

  """
  def localize(%Unit{} = unit, usage, options) do
    locale = Keyword.get(options, :locale, Cldr.get_locale())

    with {:ok, locale} <- Cldr.validate_locale(locale),
         territory = Keyword.get(options, :territory, locale.territory),
         {:ok, territory} <- Cldr.validate_territory(territory),
         {:ok, unit_list} <- extract_unit_list(unit, usage, territory, options) do
      decompose(unit, unit_list)
    end
  end

  defp extract_unit_list(unit, usage, territory, options) do
    category = unit_category(unit)

    unit_preferences()
    |> get_in([category, usage])
    |> find_preference(usage, territory, options[:scope], options[:style])
  end

  @global :"001"
  defp find_preference(nil, usage, _territory, _scope, _style) do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "No known unit preference for usage #{inspect(usage)}"}}
  end

  defp find_preference(preferences, _usage, territory, nil, nil) do
    {:ok, Map.get(preferences, territory) || Map.get(preferences, @global)}
  end

  defp find_preference(preferences, usage, territory, :small, nil) do
    {:ok,
     get_in(preferences, [:small, territory]) || get_in(preferences, [:small, @global]) ||
       find_preference(usage, preferences, territory, nil, nil)}
  end

  defp find_preference(preferences, usage, territory, nil, :informal) do
    {:ok,
     get_in(preferences, [:informal, territory]) || get_in(preferences, [:informal, @global]) ||
       find_preference(usage, preferences, territory, nil, nil)}
  end

  defp find_preference(preferences, usage, territory, :small, :informal) do
    {:ok,
     get_in(preferences, [:small, :informal, territory]) ||
       get_in(preferences, [:small, :informal, @global]) ||
       get_in(preferences, [:informal, territory]) ||
       get_in(preferences, [:informal, @global]) ||
       find_preference(usage, preferences, territory, nil, nil)}
  end

  defp find_preference(_preferences, _usage, _territory, scope, style)
       when scope in [:small, nil] do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "Style #{inspect(style)} is not known. It should be :informal or nil"}}
  end

  defp find_preference(_preferences, _usage, _territory, scope, style)
       when style in [:informal, nil] do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "Scope #{inspect(scope)} is not known. It should be :small or nil"}}
  end

  defp find_preference(_preferences, _usage, _territory, scope, style) do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "No known scope #{inspect(scope)} and no known style #{inspect(style)}"}}
  end

  defp int_rem(unit) do
    integer = Unit.round(unit, 0, :down) |> Math.trunc()
    remainder = Math.sub(unit, integer)
    {integer, remainder}
  end

  @doc """
  Returns a new unit of the same unit
  type but with a zero value.

  ## Example

      iex> u = Cldr.Unit.new(:foot, 23.3)
      #Unit<:foot, 23.3>
      iex> Cldr.Unit.zero(u)
      #Unit<:foot, 0.0>

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

  ## Examples

      iex> u = Cldr.Unit.new(:foot, 23.3)
      #Unit<:foot, 23.3>
      iex> Cldr.Unit.zero?(u)
      false

      iex> u = Cldr.Unit.new(:foot, 0)
      #Unit<:foot, 0>
      iex> Cldr.Unit.zero?(u)
      true

  """
  def zero?(%Unit{value: value}) when is_number(value) do
    value == 0
  end

  @decimal_0 Decimal.new(0)
  def zero?(%Unit{value: value}) do
    Decimal.cmp(value, @decimal_0) == :eq
  end

  @doc """
  Returns a list of the known unit categories.

  ## Example

      iex> Cldr.Unit.unit_categories
      [:acceleration, :angle, :area, :compound, :concentr, :consumption, :coordinate, :digital,
       :duration, :electric, :energy, :force, :frequency, :graphics, :length, :light, :mass,
       :power, :pressure, :speed, :temperature, :torque, :volume]

  """
  @unit_categories Map.keys(@unit_tree)
  def unit_categories do
    @unit_categories
  end

  @doc """
  Returns the units category for a given unit

  ## Options

  * `unit` is any units returned by
    `Cldr.Unit.new/2` or units returned by `Cldr.Unit.units/0`

  ## Returns

  * a valid category or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.unit_category :pint_metric
      :volume

      iex> Cldr.Unit.unit_category :stone
      :mass

  """
  @spec unit_category(Unit.t() | String.t() | atom()) ::
          atom() | {:error, {module(), String.t()}}
  def unit_category(unit) do
    with {:ok, unit} <- validate_unit(unit) do
      Map.get(unit_category_map(), unit)
    end
  end

  def unit_type(unit) do
    IO.warn("Cldr.Unit.unit_type/1 is deprecated. Please use `Cldr.Unit.unit_category/1")
    unit_category(unit)
  end

  @doc """
  Returns a list of the unit categories and associated
  units

  ## Example

      Cldr.Unit.unit_tree
      => %{
        acceleration: [:g_force, :meter_per_second_squared],
        angle: [:arc_minute, :arc_second, :degree, :radian, :revolution],
        area: [:acre, :hectare, :square_centimeter, :square_foot, :square_inch,
               :square_kilometer, :square_meter, :square_mile, :square_yard],
        concentr: [:karat, :milligram_per_deciliter, :millimole_per_liter,
                   :part_per_million]
        ...

  """
  @spec unit_tree :: map()
  def unit_tree do
    @unit_tree
  end

  @unit_category_map @unit_tree
                     |> Enum.map(fn {k, v} ->
                       k = List.duplicate(k, length(v))
                       Enum.zip(v, k)
                     end)
                     |> List.flatten()
                     |> Map.new()

  @doc """
  Returns a mapping of units to their respective
  unit categories

  ## Example

      => iex> Cldr.Unit.unit_category_map
      %{
        kilowatt: :power,
        percent: :concentr,
        picometer: :length,
        centiliter: :volume,
        square_inch: :area,
        megapascal: :pressure,
        atmosphere: :pressure,
        per: :compound,
        ...
      }

  """
  @spec unit_category_map :: map()
  def unit_category_map do
    @unit_category_map
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
         |> Map.delete(:compound)
         |> Map.values()
         |> List.flatten()

  @spec units :: [atom, ...]
  def units do
    @units
  end

  @doc """
  Returns the units for a given unit type

  ## Arguments

  * `type` is any unit type returned by
    `Cldr.Unit.unit_categories/0`

  ## Returns

  * a list of units

  ## Examples

      iex> Cldr.Unit.units(:length)
      [:astronomical_unit, :centimeter, :decimeter, :fathom, :foot, :furlong, :inch,
       :kilometer, :light_year, :meter, :micrometer, :mile, :mile_scandinavian,
       :millimeter, :nanometer, :nautical_mile, :parsec, :picometer, :point,
       :solar_radius, :yard]

  """
  @spec units(atom) :: [atom, ...]
  def units(category) when category in @unit_categories do
    Map.get(unit_tree(), category)
  end

  def units(category) do
    {:error, unit_category_error(category)}
  end

  @doc """
  Returns a list of units that are within the
  specified jaro distance of the provided unit.

  ## Arguments

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
  @spec jaro_match(unit | String.t(), number) :: [{float, unit}, ...] | []
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

  ## Arguments

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

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.units/0` or by
    `Cldr.Unit.new/2`

  * `options` is a keyword list of options

  ## Options

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
       :millimeter, :nanometer, :nautical_mile, :parsec, :picometer, :point,
       :solar_radius, :yard]

      iex> Cldr.Unit.compatible_units :me, jaro: true
      [{0.7999999999999999, :meter}]

  """
  @default_options [jaro: false, distance: @default_distance]
  @spec compatible_units(unit(), Keyword.t() | map()) :: [unit(), ...] | [{float, unit}, ...] | []

  def compatible_units(unit, options \\ @default_options)

  def compatible_units(unit, options) when is_list(options) do
    options = Keyword.merge(@default_options, options) |> Map.new()
    compatible_units(unit, options)
  end

  def compatible_units(unit, %{jaro: false}) do
    with {:ok, unit} <- validate_unit(unit) do
      type = unit_category(unit)
      unit_tree()[type]
    end
  end

  def compatible_units(unit, %{jaro: true, distance: distance}) when is_number(distance) do
    unit
    |> jaro_match(distance)
    |> compatible_list(unit)
  end

  @string_units Enum.map(@units, &Atom.to_string/1)
  @spec match_list(String.t(), float) :: list({float, unit()}) | []

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
        {_distance, u} -> unit_category(u) == unit_category(unit)
        u -> unit_category(u) == unit_category(unit)
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

  @doc """
  Returns a map of unit preferences

  Units of measure vary country by country. While
  most countries standardize on the metric system,
  others use the US or UKL systems of measure.

  When presening a unit to an end user it is appropriate
  to do so using units familiar and relevant to that
  end user.

  The data returned by this function supports the
  opportunity to convert a give unit to meet this
  requirement.

  Unit preferences can vary by usage, not just territory,
  Therefore the data is structured according to unit
  category and unit usage.

  """
  @unit_preferences Cldr.Config.unit_preferences()
  @spec unit_preferences() :: map()
  def unit_preferences do
    @unit_preferences
  end

  @doc false
  def units_for(locale, style \\ default_style(), backend \\ Cldr.default_backend()) do
    module = Module.concat(backend, :"Elixir.Unit")
    module.units_for(locale, style)
  end

  @doc """
  Returns the default measurement system for a territory.

  ## Example

      iex> Cldr.Unit.measurement_system_for :US
      :US

      iex> Cldr.Unit.measurement_system_for :GB
      :UK

      iex> Cldr.Unit.measurement_system_for :AU
      :metric

  """
  @spec measurement_system_for(atom()) ::
          :metric | :US | :UK | {:error, {module(), String.t()}}

  def measurement_system_for(territory) do
    with {:ok, territory} <- Cldr.validate_territory(territory) do
      map = measurement_systems()
      get_in(map, [:default, territory]) || get_in(map, [:default, :"001"])
    end
  end

  @doc """
  Returns the default measurement system for a territory
  in a given category.

  ## Example

      iex> Cldr.Unit.measurement_system_for :US, :temperature
      :US

      iex> Cldr.Unit.measurement_system_for :BS, :temperature
      :US

      iex> Cldr.Unit.measurement_system_for :BS
      :metric

  """
  @spec measurement_system_for(atom(), atom()) ::
          :metric | :US | :UK | nil | {:error, {module(), String.t()}}

  def measurement_system_for(territory, category) do
    with {:ok, territory} <- Cldr.validate_territory(territory) do
      map = measurement_systems()

      get_in(map, [category, territory]) || get_in(map, [:default, territory]) ||
        get_in(map, [:default, :"001"])
    end
  end

  @doc """
  Returns the measurement system in use by territory

  ## Example

      iex> Cldr.Unit.measurement_systems
      %{
        default: %{
          "001": :metric,
          GB: :UK,
          LR: :US,
          MM: :US,
          US: :US
        },
        paper_size: %{
          "001": :A4,
          BZ: :"US-Letter",
          CA: :"US-Letter",
          CL: :"US-Letter",
          CO: :"US-Letter",
          CR: :"US-Letter",
          GT: :"US-Letter",
          MX: :"US-Letter",
          NI: :"US-Letter",
          PA: :"US-Letter",
          PH: :"US-Letter",
          PR: :"US-Letter",
          SV: :"US-Letter",
          US: :"US-Letter",
          VE: :"US-Letter"
        },
        temperature: %{
          BS: :US,
          BZ: :US,
          KY: :US,
          LR: :metric,
          MM: :metric,
          PR: :US,
          PW: :US
        }
      }

  """
  @measurement_systems Cldr.Config.measurement_system()
  def measurement_systems do
    @measurement_systems
  end

  defp pattern_for(%LanguageTag{cldr_locale_name: locale_name}, style, unit, backend) do
    with {:ok, style} <- validate_style(style),
         {:ok, unit} <- validate_unit(unit) do
      units = units_for(locale_name, style, backend)
      pattern = Map.get(units, unit)
      {:ok, pattern}
    end
  end

  defp pattern_for(locale_name, style, unit, backend) do
    with {:ok, locale} <- backend.validate_locale(locale_name) do
      pattern_for(locale, style, unit, backend)
    end
  end

  defp per_pattern_for(%LanguageTag{cldr_locale_name: locale_name}, style, unit, backend) do
    with {:ok, style} <- validate_style(style),
         {:ok, unit} <- validate_unit(unit) do
      units = units_for(locale_name, style, backend)
      pattern = get_in(units, [unit, :per_unit_pattern])
      default_pattern = get_in(units, [:per, :compound_unit_pattern])
      {:ok, pattern || default_pattern}
    end
  end

  defp per_pattern_for(locale_name, style, unit, backend) do
    with {:ok, locale} <- backend.validate_locale(locale_name) do
      per_pattern_for(locale, style, unit, backend)
    end
  end

  defp normalize_options(backend, options) do
    with {:ok, per_unit} <- validate_per_unit(options[:per]) do
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
    |> String.replace("-", "_")
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

  defp validate_per_unit(nil) do
    {:ok, nil}
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
      "Operations can only be performed between units of the same type. " <>
        "Received #{inspect(unit_1)} and #{inspect(unit_2)}"
    }
  end
end
