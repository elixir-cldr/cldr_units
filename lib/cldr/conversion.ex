defmodule Cldr.Unit.Conversion do
  @moduledoc """
  Unit conversion functions for the units defined
  in `Cldr`.

  """

  alias Cldr.Unit
  import Unit, only: [incompatible_units_error: 2]

  @factors Cldr.Config.unit_conversion_info()
           |> Map.get(:conversions)
           |> Enum.map(fn
               {unit, %{factor: factor} = conversion} when is_number(factor) ->
                  {unit, conversion}
               {unit, %{factor: factor} = conversion} ->
                  {unit, %{conversion | factor: Ratio.new(factor.numerator, factor.denominator)}}
           end)
           |> Enum.map(fn
               {unit, %{offset: offset} = conversion} when is_number(offset) ->
                  {unit, conversion}
               {unit, %{offset: offset} = conversion} ->
                  {unit, %{conversion | offset: Ratio.new(offset.numerator, offset.denominator)}}
           end)
           |> Map.new

  @inverse_factors Enum.map(@factors, fn {_k, v} -> {v.target, %{factor: 1, offset: 0}} end)
  |> Map.new

  def factors do
    unquote(Macro.escape(Map.merge(@factors, @inverse_factors)))
  end

  def factors(factor) do
    Map.get(factors(), factor)
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...)

  ## Options

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

  def convert(%Unit{unit: from_unit, value: value}, to_unit) do
    with {:ok, to_unit} <- Unit.validate_unit(to_unit),
         true <- Unit.compatible?(from_unit, to_unit),
         {:ok, from_conversion} <- get_factors(from_unit),
         {:ok, to_conversion} <- get_factors(to_unit),
         {:ok, converted} <- convert(value, from_conversion, to_conversion) do
      Unit.new(to_unit, converted)
    else
      {:error, _} = error -> error
      false -> {:error, incompatible_units_error(from_unit, to_unit)}
    end
  end

  defp get_factors(unit) do
    if factors = factors(unit) do
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
      |> Ratio.to_float

    truncated = trunc(converted)

    if converted == truncated do
      {:ok, truncated}
    else
      {:ok, converted}
    end
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

  ## Options

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

end
