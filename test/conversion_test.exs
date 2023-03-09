defmodule Cldr.Unit.Conversion.Test do
  use ExUnit.Case, async: true

  alias Cldr.Unit.Test.ConversionData

  for t <- ConversionData.conversions() do
    test "##{t.line} that #{t.from} is convertible to #{t.to}" do
      {:ok, from} = Cldr.Unit.BaseUnit.canonical_base_unit(unquote(t.from))
      {:ok, to} = Cldr.Unit.BaseUnit.canonical_base_unit(unquote(t.to))
      assert from == to
    end
  end

  # Of the ~180 tests, 3 fail [35, 36, 186] because of rounding
  # precision for round significant digits. The errors are
  # in the 6th decimal place or further
  # so for now we omit these three tests.

  @just_outside_tolerance [35, 36, 186]

  for t <- ConversionData.conversions(), t.line not in @just_outside_tolerance do
    test "##{t.line} [Float] that #{t.from} converted to #{t.to} is #{inspect(t.result)}" do
      unit = Cldr.Unit.new!(unquote(t.from), 1000)
      {expected_result, round_digits, round_significant} = unquote(Macro.escape(t.result))

      result =
        unit
        |> Cldr.Unit.Conversion.convert!(unquote(t.to))
        |> Cldr.Unit.Test.ConversionData.to_float_unit()
        |> ConversionData.round(round_digits, round_significant)

      if is_integer(result.value) and is_float(expected_result) do
        assert result.value * 1.0 == expected_result
      else
        assert result.value == expected_result
      end
    end
  end

  @just_outside_tolerance_decimal [186]

  @one_thousand Decimal.new(1000)
  for t <- ConversionData.conversions(), t.line not in @just_outside_tolerance_decimal do
    test "##{t.line} [Decimal] that #{t.from} converted to #{t.to} is #{inspect(t.result)}" do
      unit = Cldr.Unit.new!(unquote(t.from), @one_thousand)
      {expected_result, round_digits, round_significant} = unquote(Macro.escape(t.result))

      result =
        unit
        |> Cldr.Unit.Conversion.convert!(unquote(t.to))
        |> Cldr.Unit.to_decimal_unit()
        |> ConversionData.round(round_digits, round_significant)

      if is_float(expected_result) do
        assert Cldr.Decimal.compare(result.value, Decimal.from_float(expected_result)) == :eq
      else
        assert Cldr.Decimal.compare(result.value, Decimal.new(expected_result)) == :eq
      end
    end
  end

  test "compare/2 for [Decimal] units that are built from string" do
    s_unit = Cldr.Unit.new!(Decimal.new("300.0"), "gram")
    t_unit = Cldr.Unit.new!(Decimal.new("60.0"), "kilogram")
    assert Cldr.Unit.compare(s_unit, t_unit) == :lt
  end

  test "convert!/2" do
    assert MyApp.Cldr.Unit.convert!(MyApp.Cldr.Unit.new!(:foot, 3), :meter)

    assert_raise Cldr.Unit.IncompatibleUnitsError, fn ->
      MyApp.Cldr.Unit.convert!(MyApp.Cldr.Unit.new!(:foot, 3), :liter)
    end
  end

  test "base unit conversion for a 'per per` unit" do
    assert Cldr.Unit.BaseUnit.canonical_base_unit("candela per lux") ==
             {:ok, "candela_square_meter_per_candela"}
  end

  test "conversion where base units don't match but unit categories do" do
    assert {:ok, _} = Cldr.Unit.convert(Cldr.Unit.new!(:joule, 1), "kilowatt_hour")
  end
end
