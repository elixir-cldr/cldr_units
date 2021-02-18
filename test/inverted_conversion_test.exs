defmodule Cldr.Unit.InvertedConversion.Test do
  use ExUnit.Case, async: true

  test "mpg to liters per 100 kilometers" do
    mpg = Cldr.Unit.new!(30, :mile_per_gallon)

    liters_per_100_kilometers =
      Cldr.Unit.convert!(mpg, :liter_per_100_kilometer)
      |> Cldr.Unit.ratio_to_decimal()
      |> Cldr.Unit.Test.ConversionData.round_precision(6)

    # |> IO.inspect(label: "converted value")

    target_value =
      Decimal.from_float(7.84049)
      |> Cldr.Unit.new!(:liter_per_100_kilometer)

    # |> IO.inspect(label: "expected value")

    assert Cldr.Unit.compare(liters_per_100_kilometers, target_value) == :eq
  end

  test "meter_per_cubic meter base unit into liters per 100 kilometers" do
    m_per_cm = Cldr.Unit.new!(1, :meter_per_cubic_meter)

    liters_per_100_kilometers =
      Cldr.Unit.convert!(m_per_cm, :liter_per_100_kilometer)
      |> Cldr.Unit.ratio_to_decimal()
      |> Cldr.Unit.Test.ConversionData.round_precision(6)

    # |> IO.inspect(label: "converted value")

    target_value = Cldr.Unit.new!(Decimal.new(100_000_000), :liter_per_100_kilometer)
    # |> IO.inspect(label: "expected value")

    assert Cldr.Unit.compare(liters_per_100_kilometers, target_value) == :eq
  end

  test "mpg to meter_per_cubic meter" do
    mpg = Cldr.Unit.new!(30, :mile_per_gallon)

    meters_per_cubic_meter =
      Cldr.Unit.convert!(mpg, :meter_per_cubic_meter)
      |> Cldr.Unit.ratio_to_decimal()
      |> Cldr.Unit.Test.ConversionData.round(6, 6)

    # |> IO.inspect(label: "converted value")

    target_value = Cldr.Unit.new!(Decimal.new(12_754_300), :meter_per_cubic_meter)
    # |> IO.inspect(label: "expected value")

    assert Cldr.Unit.compare(meters_per_cubic_meter, target_value) == :eq
  end
end
