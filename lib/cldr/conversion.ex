defmodule Cldr.Unit.Conversion do
  alias Cldr.Unit
  import Unit, only: [incompatible_unit_error: 2]

  def factors do
    %{
      acceleration: %{
        g_force:                 1,
        meter_per_second_squared: 1
      },
      angle: %{
        arc_minute:              1,
        arc_second:              1,
        degree:                  1,
        radian:                  1,
        revolution:              1
      },
      area: %{
        acre:                    1,
        hectare:                 1,
        square_centimeter:       1,
        square_foot:             1,
        square_inch:             1,
        square_kilometer:        1,
        square_meter:            1,
        square_mile:             1,
        square_yard:             1
      },
      concentr: %{
        karat:                   1,
        milligram_per_deciliter: 1,
        millimole_per_liter:     1,
        part_per_million:        1
      },
      consumption: %{
        liter_per_100kilometers: 1,
        liter_per_kilometer:     1,
        mile_per_gallon:         1,
        mile_per_gallon_imperial: 1
      },
      coordinate: %{
        unit:                    1
      },
      digital: %{
        bit:                     1,
        byte:                    1,
        gigabit:                 1,
        gigabyte:                1,
        kilobit:                 1,
        kilobyte:                1,
        megabit:                 1,
        megabyte:                1,
        terabit:                 1,
        terabyte:                1
      },
      duration: %{
        century:                 1,
        day:                     1,
        hour:                    1,
        microsecond:             1,
        millisecond:             1,
        minute:                  1,
        month:                   1,
        nanosecond:              1,
        second:                  1,
        week:                    1,
        year:                    1
      },
      electric: %{
        ampere:                  1,
        milliampere:             1,
        ohm:                     1,
        volt:                    1
      },
      energy: %{
        calorie:                 1,
        foodcalorie:             1,
        joule:                   1,
        kilocalorie:             1,
        kilojoule:               1,
        kilowatt_hour:           1
      },
      frequency: %{
        gigahertz:               1,
        hertz:                   1,
        kilohertz:               1,
        megahertz:               1
      },
      length: %{
        astronomical_unit:       6.6846e-21,
        centimeter:              1.0e-7,
        decimeter:               1.0e+8,
        fathom:                  1.829e+9,
        foot:                    3.2808e-9,
        furlong:                 2.012e+11,
        inch:                    3.937e-8,
        kilometer:               1.0e-12,
        light_year:              1.057e-25,
        meter:                   1.0e-9,
        micrometer:              0.001,
        mile:                    6.2137e-13,
        mile_scandinavian:       1.0e-13,
        millimeter:              1_000_000,
        nanometer:               1,
        nautical_mile:           5.3996e-13,
        parsec:                  3.24078e-26,
        picometer:               0.001,
        point:                   2.8346456692913e-6,
        yard:                    1.0936e-9
      },
      light: %{
        lux:                     1
      },
      mass: %{
        carat:                   1,
        gram:                    1,
        kilogram:                1,
        metric_ton:              1,
        microgram:               1,
        milligram:               1,
        ounce:                   1,
        ounce_troy:              1,
        pound:                   1,
        stone:                   1,
        ton:                     1
      },
      power: %{
        gigawatt:                1,
        horsepower:              1,
        kilowatt:                1,
        megawatt:                1,
        milliwatt:               1,
        watt:                    1
      },
      pressure: %{
        hectopascal:             1,
        inch_hg:                 1,
        millibar:                1,
        millimeter_of_mercury:   1,
        pound_per_square_inch:   1
      },
      speed: %{
        kilometer_per_hour:      1,
        knot:                    1,
        meter_per_second:        1,
        mile_per_hour:           1
      },
      temperature: %{
        celsius:                 1,
        fahrenheit:              1,
        generic:                 1,
        kelvin:                  1
      },
      volume: %{
        acre_foot:               1,
        bushel:                  1,
        centiliter:              1,
        cubic_centimeter:        1,
        cubic_foot:              1,
        cubic_inch:              1,
        cubic_kilometer:         1,
        cubic_meter:             1,
        cubic_mile:              1,
        cubic_yard:              1,
        cup:                     1,
        cup_metric:              1,
        deciliter:               1,
        fluid_ounce:             1,
        gallon:                  1,
        gallon_imperial:         1,
        hectoliter:              1,
        liter:                   1,
        megaliter:               1,
        milliliter:              1,
        pint:                    1,
        pint_metric:             1,
        quart:                   1,
        tablespoon:              1,
        teaspoon:                1
      }
    }
  end

  def convert(%Unit{unit: from_unit, value: value}, to_unit) do
    with {:ok, to_unit} <- Unit.validate_unit(to_unit) do
      if Unit.compatible?(from_unit, to_unit) do
        converted = value / factor(from_unit) * factor(to_unit)
        Unit.new(to_unit, converted)
      else
        {:error, incompatible_unit_error(from_unit, to_unit)}
      end
    end
  end

  defp factor(unit) do
    unit_type = Unit.unit_type(unit)
    get_in(factors(), [unit_type, unit])
  end
end