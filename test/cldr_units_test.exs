defmodule Cldr.UnitsTest do
  use ExUnit.Case

  test "that centimetre conversion is correct" do
    assert Cldr.Unit.convert(Cldr.Unit.new(:millimeter, 300), :centimeter) ==
             Cldr.Unit.new(:centimeter, 30.0)
  end

  test "that pluralization in non-en locales works" do
    assert Cldr.Unit.to_string!(1, locale: "de", unit: :microsecond) == "1 Mikrosekunde"
    assert Cldr.Unit.to_string!(123, locale: "de", unit: :microsecond) == "123 Mikrosekunden"

    assert Cldr.Unit.to_string!(1, locale: "de", unit: :pint) == "1 Pint"
    assert Cldr.Unit.to_string!(123, locale: "de", unit: :pint) == "123 Pints"

    assert Cldr.Unit.to_string!(1, locale: "de", unit: :century) == "1 Jahrhundert"
    assert Cldr.Unit.to_string!(123, locale: "de", unit: :century) == "123 Jahrhunderte"
  end
end
