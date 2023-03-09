defmodule Cldr.Unit.Parse.Test do
  use ExUnit.Case, async: true

  test "Parse a simple unit" do
    assert MyApp.Cldr.Unit.parse("1 week") == Cldr.Unit.new(1, :week)
    assert MyApp.Cldr.Unit.parse("2 weeks") == Cldr.Unit.new(2, :week)
  end

  test "Parse an ambiguous unit with no filter" do
    assert MyApp.Cldr.Unit.parse("2 w") == Cldr.Unit.new(2, :watt)
  end

  test "Parse an ambiguous unit with :only filter" do
    assert MyApp.Cldr.Unit.parse("2 w", only: :duration) == Cldr.Unit.new(2, :week)
    assert MyApp.Cldr.Unit.parse("2 w", only: [:duration, :length]) == Cldr.Unit.new(2, :week)
    assert MyApp.Cldr.Unit.parse("2 w", only: :power) == Cldr.Unit.new(2, :watt)
    assert MyApp.Cldr.Unit.parse("2 w", only: :watt) == Cldr.Unit.new(2, :watt)
    assert MyApp.Cldr.Unit.parse("2 w", except: :watt) == Cldr.Unit.new(2, :week)
    assert MyApp.Cldr.Unit.parse("2 m", only: :minute) == Cldr.Unit.new(2, :minute)
    assert MyApp.Cldr.Unit.parse("2 m", only: [:year, :month, :day]) == Cldr.Unit.new(2, :month)

    assert MyApp.Cldr.Unit.parse("2 m", only: :duration) ==
             {:error,
              {Cldr.Unit.AmbiguousUnitError,
               "The string \"m\" ambiguously resolves to [:minute, :month]"}}
  end

  test "Parse an ambiguous unit with :except filter" do
    assert MyApp.Cldr.Unit.parse("2 w", except: :duration) == Cldr.Unit.new(2, :watt)
    assert MyApp.Cldr.Unit.parse("2 w", except: :power) == Cldr.Unit.new(2, :week)
  end

  test "Parse with a filter that doesn't match" do
    assert MyApp.Cldr.Unit.parse("2 w", only: :energy) ==
             {:error,
              {Cldr.Unit.CategoryMatchError,
               "None of the units [:watt, :week] belong to a unit or category matching only: [:energy]"}}
  end

  test "Parse with an invalid :only or :except" do
    assert MyApp.Cldr.Unit.parse("2w", only: :invalid) ==
             {:error, {Cldr.UnknownUnitError, "The unit :invalid is not known."}}

    assert MyApp.Cldr.Unit.parse("2w", only: [:invalid, :also_invalid]) ==
             {:error, {Cldr.UnknownUnitError, "The units [:also_invalid, :invalid] are not known."}}

    assert MyApp.Cldr.Unit.parse("2w", except: :invalid) ==
             {:error, {Cldr.UnknownUnitError, "The unit :invalid is not known."}}

    assert MyApp.Cldr.Unit.parse("2w", except: [:invalid, :also_invalid]) ==
             {:error, {Cldr.UnknownUnitError, "The units [:also_invalid, :invalid] are not known."}}
  end

  test "Parse a simple unit name" do
    assert MyApp.Cldr.Unit.parse_unit_name("week") == {:ok, :week}
    assert MyApp.Cldr.Unit.parse_unit_name("weeks") == {:ok, :week}
  end
end
