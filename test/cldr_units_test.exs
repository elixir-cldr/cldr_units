defmodule Cldr.UnitsTest do
  use ExUnit.Case

  test "that centimetre conversion is correct" do
    assert Cldr.Unit.convert(Cldr.Unit.new(:millimeter, 300), :centimeter) ==
             Cldr.Unit.new(:centimeter, 30.0)
  end

  test "that pluralization in non-en locales works" do
    assert Cldr.Unit.to_string!(1, MyApp.Cldr, locale: "de", unit: :microsecond) ==
             "1 Mikrosekunde"

    assert Cldr.Unit.to_string!(123, MyApp.Cldr, locale: "de", unit: :microsecond) ==
             "123 Mikrosekunden"

    assert Cldr.Unit.to_string!(1, MyApp.Cldr, locale: "de", unit: :pint) == "1 Pint"
    assert Cldr.Unit.to_string!(123, MyApp.Cldr, locale: "de", unit: :pint) == "123 Pints"

    assert Cldr.Unit.to_string!(1, MyApp.Cldr, locale: "de", unit: :century) == "1 Jahrhundert"

    assert Cldr.Unit.to_string!(123, MyApp.Cldr, locale: "de", unit: :century) ==
             "123 Jahrhunderte"
  end

  test "decimal" do
    unit = Cldr.Unit.new(Decimal.new("300"), :minute)

    hours = Cldr.Unit.Conversion.convert(unit, :hour)

    assert hours.unit == :hour
    assert Decimal.equal?(5, Cldr.Unit.value(Cldr.Unit.round(hours)))
  end

  test "decimal functional conversion - celsius" do
    celsius = Cldr.Unit.new(Decimal.new("100"), :celsius)
    fahrenheit = Cldr.Unit.Conversion.convert(celsius, :fahrenheit)
    value = Decimal.round(Cldr.Unit.value(fahrenheit))
    assert Decimal.equal?(value, Decimal.new(212))
  end

  test "decimal functional conversion - kelvin" do
    celsius = Cldr.Unit.new(Decimal.new("0"), :celsius)
    kelvin = Cldr.Unit.Conversion.convert(celsius, :kelvin)

    assert Decimal.equal?(Cldr.Unit.value(kelvin), Decimal.new("273.15"))
  end

  test "decimal conversion without function" do
    celsius = Cldr.Unit.new(Decimal.new(100), :celsius)
    celsius2 = Cldr.Unit.Conversion.convert(celsius, :celsius)

    assert Decimal.equal?(Cldr.Unit.value(celsius2), Decimal.new(100))
  end

  test "that to_string is invoked by the String.Chars protocol" do
    unit = Cldr.Unit.new(23, :foot)
    assert to_string(unit) == "23 feet"
  end

  test "formatting a list" do
    list = [Cldr.Unit.new(23, :foot), Cldr.Unit.new(5, :inch)]
    assert Cldr.Unit.to_string(list) == {:ok, "23 feet and 5 inches"}
  end

  test "per pattern for a defined per_unit_pattern" do
    unit = Cldr.Unit.new(45, :gallon)

    assert Cldr.Unit.to_string(unit, per: :square_kilometer) ==
             {:ok, "45 gallons per square kilometer"}

    assert Cldr.Unit.to_string(unit, style: :narrow, per: :square_kilometer) ==
             {:ok, "45gal/km²"}
  end

  test "per pattern for a generic per_unit_pattern" do
    unit = Cldr.Unit.new(45, :gallon)
    assert Cldr.Unit.to_string(unit, per: :degree) == {:ok, "45 gallons per degree"}
    assert Cldr.Unit.to_string(unit, style: :narrow, per: :degree) == {:ok, "45gal/°"}
  end

  test "localize a unit" do
    unit = Cldr.Unit.new(100, :meter)

    assert Cldr.Unit.localize(unit, :person, territory: :US) ==
             [Cldr.Unit.new(:inch, 3937)]

    assert Cldr.Unit.localize(unit, :person, territory: :US, style: :informal) ==
             [Cldr.Unit.new(:foot, 328), Cldr.Unit.new(:inch, 1)]

    assert Cldr.Unit.localize(unit, :unknown, territory: :US) ==
             {:error,
              {Cldr.Unit.UnknownUnitPreferenceError,
               "No known unit preference for usage :unknown"}}

    assert Cldr.Unit.localize(unit, :person, territory: :US, style: :unknown) ==
             {:error,
              {Cldr.Unit.UnknownUnitPreferenceError,
               "Style :unknown is not known. It should be :informal or nil"}}

    assert Cldr.Unit.localize(unit, :person, territory: :US, scope: :unknown) ==
             {:error,
              {Cldr.Unit.UnknownUnitPreferenceError,
               "Scope :unknown is not known. It should be :small or nil"}}

    assert Cldr.Unit.localize(unit, :person, territory: :US, scope: :unknown1, style: :unknown2) ==
             {:error,
              {Cldr.Unit.UnknownUnitPreferenceError,
               "No known scope :unknown1 and no known style :unknown2"}}
  end

  if function_exported?(Code, :fetch_docs, 1) do
    test "that no module docs are generated for a backend" do
      assert {:docs_v1, _, :elixir, _, :hidden, %{}, _} = Code.fetch_docs(NoDocs.Cldr)
    end

    assert "that module docs are generated for a backend" do
      {:docs_v1, _, :elixir, "text/markdown", %{"en" => _}, %{}, _} = Code.fetch_docs(MyApp.Cldr)
    end
  end
end
