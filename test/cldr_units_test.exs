defmodule Cldr.UnitsTest do
  use ExUnit.Case

  test "that centimetre conversion is correct" do
    assert Cldr.Unit.convert(Cldr.Unit.new(:millimeter, 300), :centimeter) ==
           Cldr.Unit.new(:centimeter, 30.0)
  end

end