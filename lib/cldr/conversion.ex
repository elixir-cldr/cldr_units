defmodule Cldr.Unit.Conversion do
  @moduledoc """
  Unit conversion functions for the units defined
  in `Cldr`.

  """

  alias Cldr.Unit
  import Unit, only: [incompatible_units_error: 2]
  import Cldr.Unit.Conversions, only: [conversion_factor: 1]

  defmodule Options do
    defstruct [usage: nil, scope: nil, locale: nil, backend: nil, alt: nil]
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...)

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `to_unit` is any unit name returned by `Cldr.Unit.units/0`

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.convert Cldr.Unit.new!(:celsius, 0), :fahrenheit
      #Unit<:fahrenheit, 32>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Unit<:celsius, 0>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :foot
      #Unit<:foot, 5280>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :gallon
      {:error, {Cldr.Unit.IncompatibleUnitsError,
        "Operations can only be performed between units of the same type. Received :mile and :gallon"}}

  """
  @spec convert(Unit.t(), Unit.unit()) :: Unit.t() | {:error, {module(), String.t()}}

  def convert(%Unit{unit: from_unit, value: _value} = unit, from_unit) do
    unit
  end

  def convert(%Unit{unit: from_unit, value: value}, to_unit) do
    with {:ok, to_unit} <- Unit.validate_unit(to_unit),
         true <- Unit.compatible?(from_unit, to_unit),
         {:ok, from_conversion} <- get_conversions(from_unit),
         {:ok, to_conversion} <- get_conversions(to_unit),
         {:ok, converted} <- convert(value, from_conversion, to_conversion) do
      Unit.new(to_unit, converted)
    else
      {:error, _} = error -> error
      false -> {:error, incompatible_units_error(from_unit, to_unit)}
    end
  end

  defp get_conversions(unit) do
    if factors = conversion_factor(unit) do
      {:ok, factors}
    else
      {:error,  {Cldr.Unit.UnitNotConvertibleError,
        "No conversion is possible for #{inspect unit}"}}
    end
  end

  defp convert(value, from, to) when is_number(value) do
    use Ratio

    %{factor: from_factor, offset: from_offset} = from
    %{factor: to_factor, offset: to_offset} = to

    base = (value * from_factor) + from_offset
    converted = ((base - to_offset) / to_factor) |> Ratio.to_float

    truncated = trunc(converted)

    if converted == truncated do
      {:ok, truncated}
    else
      {:ok, converted}
    end
  end

  defp convert(%Decimal{} = value, from, to) do
    use Ratio

    %{factor: from_factor, offset: from_offset} = from
    %{factor: to_factor, offset: to_offset} = to

    base =
      Ratio.new(value)
      |> Ratio.mult(Ratio.new(from_factor))
      |> Ratio.add(Ratio.new(from_offset))

    converted =
      base
      |> Ratio.sub(Ratio.new(to_offset))
      |> Ratio.div(Ratio.new(to_factor))
      |> to_decimal

    {:ok, converted}
  end

  defp convert(_value, from, to) do
    {:error,
     {Cldr.Unit.UnitNotConvertibleError,
      "No conversion is possible between #{inspect(to)} and #{inspect(from)}"}}
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...) and raises
  on a unit type mismatch

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `to_unit` is any unit name returned by `Cldr.Unit.units/0`

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Conversion.convert! Cldr.Unit.new!(:celsius, 0), :fahrenheit
      #Unit<:fahrenheit, 32>

      iex> Cldr.Unit.Conversion.convert! Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Unit<:celsius, 0>

      Cldr.Unit.Conversion.convert Cldr.Unit.new!(:mile, 1), :gallon
      ** (Cldr.Unit.IncompatibleUnitsError) Operations can only be performed between units of the same type. Received :mile and :gallon

  """
  @spec convert!(Unit.t(), Unit.unit()) :: Unit.t() | no_return()

  def convert!(%Unit{} = unit, to_unit) do
    case convert(unit, to_unit) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc """
  Returns a list of the preferred units for a given
  unit, locale, use case and scope.

  The units used to represent length, volume and so on
  depend on a given territory, measurement system and usage.

  For example, in the US, people height is most commonly
  referred to in `inches`, or informally as `feet and inches`.
  In most of the rest of the world it is `centimeters`.

  ### Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `backend` is any Cldr backend module. That is, any module
    that includes `use Cldr`. The default is `Cldr.default_backend/0`

  * `options` is a keyword list of options or a
    `Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ### Options

  * `:usage` is the unit usage. for example `;person` for a unit
    of type `:length`. The available usage for a given unit category can
    be seen with `Cldr.Config.unit_preferences/0`. The default is `nil`.

  * `:scope` is either `:small` or `nil`. In some usage, the units
    used are different when the unit size is small. It is up to the
    developer to determine when `scope: :small` is appropriate.

  * `:alt` is either `:informal` or `nil`. Like `:scope`, the units
    in use depend on whether they are being used in a formal or informal
    context.

  * `:locale` is any locale returned by `Cldr.validate_locale/2`

  ### Returns

  * `{:ok, unit_list}` or

  * `{:error, {exception, reason}}`

  ### Examples

      iex> meter = Cldr.Unit.new :meter, 1
      #Unit<:meter, 1>
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :person, alt: :informal
      {:ok, [:foot, :inch]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :person
      {:ok, [:inch]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :person
      {:ok, [:centimeter]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :road
      {:ok, [:mile]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :road
      {:ok, [:kilometer]}

  ### Notes

  One common pattern is to convert a given unit into the unit
  appropriate for a given local and usage. This can be
  accomplished with a combination of `Cldr.Unit.Conversion.preferred_units/2`
  and `Cldr.Unit.decompose/2`. For example:

      iex> meter = Cldr.Unit.new(:meter, 1)
      iex> with {:ok, preferred_units} <- Cldr.Unit.preferred_units(meter, MyApp.Cldr, locale: "en-US", usage: :person, alt: :informal) do
      ...>   Cldr.Unit.decompose(meter, preferred_units)
      ...> end
      [Cldr.Unit.new(:foot, 3), Cldr.Unit.new(:inch, 3)]

  """
  def preferred_units(unit, backend, options \\ [])

  def preferred_units(%Unit{} = unit, options, []) when is_list(options) do
    preferred_units(unit, Cldr.default_backend(), options)
  end

  def preferred_units(%Unit{} = unit, backend, options) when is_list(options) do
    preferred_units(unit, backend, struct(Cldr.Unit.Conversion.Options, options))
  end

  @default_territory :"001"
  def preferred_units(%Unit{} = unit, backend, %Options{} = options) do
    %{usage: usage, scope: scope, alt: alt, locale: locale} = options

    with {:ok, locale} <- backend.validate_locale(locale || backend.get_locale()) do
      territory = atomize(locale.territory)
      category = Unit.unit_category(unit.unit)
      preferences = Cldr.Config.unit_preferences()

      preferred_units =
        get_in(preferences, [category, usage, scope, alt, territory]) ||
        get_in(preferences, [category, usage, scope, territory]) ||
        get_in(preferences, [category, usage, alt, territory]) ||
        get_in(preferences, [category, usage, territory]) ||

        get_in(preferences, [category, usage, scope, alt, @default_territory]) ||
        get_in(preferences, [category, usage, scope, @default_territory]) ||
        get_in(preferences, [category, usage, alt, @default_territory]) ||
        get_in(preferences, [category, usage, @default_territory]) ||
        [unit.unit]

      {:ok, preferred_units}
    end
  end

  @doc """
  Returns a list of the preferred units for a given
  unit, locale, use case and scope.

  The units used to represent length, volume and so on
  depend on a given territory, measurement system and usage.

  For example, in the US, people height is most commonly
  referred to in `inches`, or informally as `feet and inches`.
  In most of the rest of the world it is `centimeters`.

  ### Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `backend` is any Cldr backend module. That is, any module
    that includes `use Cldr`. The default is `Cldr.default_backend/0`

  * `options` is a keyword list of options or a
    `Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ### Options

  * `:usage` is the unit usage. for example `;person` for a unit
    of type `:length`. The available usage for a given unit category can
    be seen with `Cldr.Config.unit_preferences/0`. The default is `nil`.

  * `:scope` is either `:small` or `nil`. In some usage, the units
    used are different when the unit size is small. It is up to the
    developer to determine when `scope: :small` is appropriate.

  * `:alt` is either `:informal` or `nil`. Like `:scope`, the units
    in use depend on whether they are being used in a formal or informal
    context.

  * `:locale` is any locale returned by `Cldr.validate_locale/2`

  ### Returns

  * `unit_list` or

  * raises an exception

  ### Examples

      iex> meter = Cldr.Unit.new :meter, 1
      #Unit<:meter, 1>
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :person, alt: :informal
      [:foot, :inch]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :person
      [:inch]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-AU", usage: :person
      [:centimeter]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :road
      [:mile]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-AU", usage: :road
      [:kilometer]

  """
  def preferred_units!(unit, backend, options \\ []) do
    case preferred_units(unit, backend, options) do
      {:ok, preferred_units} -> preferred_units
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp atomize(string) do
    String.to_existing_atom(string)
  rescue ArgumentError ->
    :"001"
  end

  def to_decimal(%Ratio{numerator: numerator, denominator: denominator}) do
    Decimal.new(numerator)
    |> Decimal.div(Decimal.new(denominator))
  end

  def to_decimal(number) when is_integer(number) do
    Decimal.new(number)
  end

end
