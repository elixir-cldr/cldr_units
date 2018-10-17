defmodule Cldr.Unit.Conversion do
  @moduledoc """
  Unit conversion functions for the units defined
  in `Cldr`.
  """

  alias Cldr.Unit
  import Unit, only: [incompatible_unit_error: 2]

  def factors do
    %{
      acceleration: %{
        g_force: 1,
        meter_per_second_squared: 9.80665
      },
      angle: %{
        arc_minute: 60,
        arc_second: 3600,
        degree: 0.0174533,
        radian: 1,
        revolution: 360
      },
      area: %{
        acre: 0.000247105,
        hectare: 1.0e-4,
        square_centimeter: 10_000,
        square_foot: 10.7639,
        square_inch: 1550,
        square_kilometer: 1.0e-6,
        square_meter: 1,
        square_mile: 3.861e-7,
        square_yard: 1.19599
      },
      concentr: %{
        karat: :not_convertible,
        milligram_per_deciliter: 1,
        millimole_per_liter: 0.06,
        part_per_million: 10
      },
      consumption: %{
        liter_per_100kilometers: 100,
        liter_per_kilometer: 1,
        mile_per_gallon: 2.35214583,
        mile_per_gallon_imperial: 2.82481053
      },
      coordinate: %{
        unit: 1
      },
      digital: %{
        bit: 1,
        byte: 0.125,
        gigabit: 1.0e-9,
        gigabyte: 1.25e-10,
        kilobit: 0.001,
        kilobyte: 0.000125,
        megabit: 1.0e-6,
        megabyte: 1.25e-7,
        terabit: 1.0e-12,
        terabyte: 1.25e-13,
        petabyte: 1.25e-16
      },
      duration: %{
        century: 3.171e-16,
        day: 1.1574e-11,
        hour: 2.7778e-10,
        microsecond: 1,
        millisecond: 0.001,
        minute: 1.6667e-8,
        month: 3.8052e-13,
        nanosecond: 1000,
        second: 1.0e-6,
        week: 1.6534e-12,
        year: 3.171e-14
      },
      electric: %{
        ampere: 0.001,
        milliampere: 1,
        ohm: :not_convertible,
        volt: :not_convertible
      },
      energy: %{
        calorie: 0.23900573614,
        foodcalorie: 0.00023900573614,
        joule: 1,
        kilocalorie: 0.00023900573614,
        kilojoule: 0.001,
        kilowatt_hour: 2.7778e-7
      },
      frequency: %{
        gigahertz: 1.0e-9,
        hertz: 1,
        kilohertz: 1.0e-3,
        megahertz: 1.0e-6
      },
      length: %{
        astronomical_unit: 6.6846e-21,
        centimeter: 1.0e-7,
        decimeter: 1.0e+8,
        fathom: 1.829e+9,
        foot: 3.2808e-9,
        furlong: 2.012e+11,
        inch: 3.937e-8,
        kilometer: 1.0e-12,
        light_year: 1.057e-25,
        meter: 1.0e-9,
        micrometer: 0.001,
        mile: 6.2137e-13,
        mile_scandinavian: 1.0e-13,
        millimeter: 1.0e-6,
        nanometer: 1,
        nautical_mile: 5.3996e-13,
        parsec: 3.24078e-26,
        picometer: 1000,
        point: 2.8346456692913e-6,
        yard: 1.0936e-9
      },
      light: %{
        lux: 1
      },
      mass: %{
        carat: 5,
        gram: 1,
        kilogram: 0.001,
        metric_ton: 1.0e-6,
        microgram: 1.0e+6,
        milligram: 1.0e+3,
        ounce: 0.035274,
        ounce_troy: 0.0321507,
        pound: 0.00220462,
        stone: 0.000157473,
        ton: 9.8421e-7
      },
      power: %{
        gigawatt: 1.0e-9,
        horsepower: 0.00134102,
        kilowatt: 1.0e-3,
        megawatt: 1.0e-6,
        milliwatt: 1000,
        watt: 1
      },
      pressure: %{
        hectopascal: 1,
        inch_hg: 0.02953,
        millibar: 1,
        millimeter_of_mercury: 0.75006375541921,
        pound_per_square_inch: 0.000145038,
        atmosphere: 0.000986923
      },
      speed: %{
        kilometer_per_hour: 3.6,
        knot: 1.94384,
        meter_per_second: 1,
        mile_per_hour: 2.23694
      },
      # {to_celsius, from_celsius}
      temperature: %{
        celsius: 1,
        fahrenheit: {
          fn
            x when is_number(x) ->
              (x - 32) / 1.8

            %Decimal{} = x ->
              Decimal.sub(x, Decimal.new(32))
              |> Decimal.div(Decimal.new("1.8"))
          end,
          fn
            x when is_number(x) ->
              x * 1.8 + 32

            %Decimal{} = x ->
              Decimal.mult(x, Decimal.new("1.8"))
              |> Decimal.add(Decimal.new(32))
          end
        },
        generic: :not_convertible,
        kelvin: {
          fn
            x when is_number(x) ->
              x - 273.15

            %Decimal{} = x ->
              Decimal.sub(x, Decimal.new("273.15"))
          end,
          fn
            x when is_number(x) ->
              x + 273.15

            %Decimal{} = x ->
              Decimal.add(x, Decimal.new("273.15"))
          end
        }
      },
      volume: %{
        acre_foot: 8.1071e-7,
        bushel: 0.0283776,
        centiliter: 100,
        cubic_centimeter: 1000,
        cubic_foot: 0.0353147,
        cubic_inch: 61.0237,
        cubic_kilometer: 1.0e-12,
        cubic_meter: 0.001,
        cubic_mile: 2.39913e-13,
        cubic_yard: 0.00130795,
        cup: 4.22675,
        cup_metric: 4,
        deciliter: 10,
        fluid_ounce: 33.814,
        gallon: 0.264172,
        gallon_imperial: 0.219969,
        hectoliter: 0.01,
        liter: 1,
        megaliter: 1.0e-6,
        milliliter: 1000,
        pint: 2.11338,
        pint_metric: 2,
        quart: 1.05669,
        tablespoon: 67.628,
        teaspoon: 202.884
      }
    }
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
      #Unit<:fahrenheit, 32.0>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Unit<:celsius, 0.0>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :foot
      #Unit<:foot, 5279.945925937846>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :gallon
      {:error, {Cldr.Unit.IncompatibleUnitError,
                "Operations can only be performed between units of the same type. Received :mile and :gallon"}}

  """
  @spec convert(Unit.t(), Unit.unit()) :: Unit.t()
  def convert(%Unit{unit: from_unit, value: value}, to_unit) do
    with {:ok, to_unit} <- Unit.validate_unit(to_unit),
         true <- Unit.compatible?(from_unit, to_unit),
         {:ok, converted} <- convert(value, factor(from_unit), factor(to_unit)) do
      Unit.new(to_unit, converted)
    else
      {:error, _} = error -> error
      false -> {:error, incompatible_unit_error(from_unit, to_unit)}
    end
  end

  defp convert(value, from, to) when is_number(value) and is_number(from) and is_number(to) do
    {:ok, value / from * to}
  end

  defp convert(%Decimal{} = value, from, to) when is_number(from) and is_number(to) do
    converted =
      value
      |> Decimal.div(Decimal.new(from))
      |> Decimal.mult(Decimal.new(to))

    {:ok, converted}
  end

  defp convert(value, {to_base_fun, _}, to) when is_number(value) and is_number(to) do
    {:ok, to_base_fun.(value) * to}
  end

  defp convert(%Decimal{} = value, {to_base_fun, _}, to) when is_number(to) do
    {:ok, Decimal.mult(to_base_fun.(value), Decimal.new(to))}
  end

  defp convert(value, from, {_to_fun, from_base_fun}) when is_number(value) and is_number(from) do
    {:ok, from_base_fun.(value / from)}
  end

  defp convert(%Decimal{} = value, from, {_to_fun, from_base_fun}) when is_number(from) do
    {:ok, Decimal.div(from_base_fun.(value), Decimal.new(from))}
  end

  defp convert(value, {to_base_fun, _}, {_, from_base_fun}) do
    {:ok, from_base_fun.(to_base_fun.(value))}
  end

  defp convert(_value, from, to)
       when from == :not_convertible or to == :not_convertible do
    {:error, {Cldr.Unit.UnitNotConvertibleError, "No conversion is possible"}}
  end

  @doc false
  def factor(unit) do
    unit_type = Unit.unit_type(unit)
    get_in(factors(), [unit_type, unit])
  end
end
