defmodule Cldr.Unit.Math.Test do
  use ExUnit.Case

  test "Add with compatible units" do
    u1 = u2 = Cldr.Unit.new!(2, "curr-usd-per-ampere-light-year")
    assert Cldr.Unit.new!(4, "curr-usd-per-ampere-light-year") == Cldr.Unit.add(u1, u2)

    u1 = u2 = Cldr.Unit.new!(2, "curr-usd-foot-pound-per-ampere-light-year")
    assert Cldr.Unit.new!(4, "curr-usd-foot-pound-per-ampere-light-year") == Cldr.Unit.add(u1, u2)
  end

  test "Sub with compatible units" do
    u1 = Cldr.Unit.new!(4, "curr-usd-per-ampere-light-year")
    u2 = Cldr.Unit.new!(2, "curr-usd-per-ampere-light-year")

    assert Cldr.Unit.new!(2, "curr-usd-per-ampere-light-year") == Cldr.Unit.sub(u1, u2)
  end

  test "Add for numeric prefix units" do
    u1 = u2 = Cldr.Unit.new!(2, "curr-usd-per-100-mile-per-gallon")
    assert Cldr.Unit.add(u1, u2) == Cldr.Unit.new!(4, "curr-usd-per-100-mile-per-gallon")
  end

  test "Rounding a float unit" do
    float_unit =
      Cldr.Unit.new!(:meter, "12.34")
      |> Cldr.Unit.to_float_unit()
      |> Cldr.Unit.round(1)

    assert float_unit.value == 12.3
  end

  test "Mult/2 and div/2 with a scalar" do
    assert Cldr.Unit.Math.div(Cldr.Unit.new!(:meter, 10), 2) == Cldr.Unit.new!(:meter, 5)
    assert Cldr.Unit.Math.mult(Cldr.Unit.new!(:meter, 10), 2) == Cldr.Unit.new!(:meter, 20)
  end

  describe "Unit power reduction" do
    test "That powers are combined after mult/2 for :meter" do
      unit = Cldr.Unit.new!(:meter, 10)
      unit_squared = Cldr.Unit.new!(:square_meter, 100)
      unit_cubed = Cldr.Unit.new!(:cubic_meter, 1000)

      assert Cldr.Unit.Math.mult(unit, unit) == unit_squared
      assert Cldr.Unit.Math.mult(unit, unit_squared) == unit_cubed
      assert Cldr.Unit.Math.mult(unit_squared, unit_squared) ==
        Cldr.Unit.new!("pow4_meter", 10_000)
    end

    test "That powers are combined after mult/2 for :foot" do
      unit = Cldr.Unit.new!(:foot, 10)
      unit_squared = Cldr.Unit.new!("square_foot", 100)
      unit_cubed = Cldr.Unit.new!("cubic_foot", 1000)

      assert Cldr.Unit.Math.mult(unit, unit) == unit_squared
      assert Cldr.Unit.Math.mult(unit, unit_squared) == unit_cubed
      assert Cldr.Unit.Math.mult(unit_squared, unit_squared) ==
        Cldr.Unit.new!("pow4_foot", 10_000)
    end
  end
end


