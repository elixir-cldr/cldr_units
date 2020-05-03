defmodule Cldr.UnitsTest do
  use ExUnit.Case

  test "that centimetre conversion is correct" do
    assert Cldr.Unit.convert(Cldr.Unit.new!(:millimeter, 300), :centimeter) ==
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
    unit = Cldr.Unit.new!(Decimal.new("300"), :minute)

    {:ok, hours} = Cldr.Unit.Conversion.convert(unit, :hour)

    assert hours.unit == :hour
    assert Decimal.equal?(5, Cldr.Unit.value(Cldr.Unit.round(hours)))
  end

  test "decimal functional conversion - celsius" do
    celsius = Cldr.Unit.new!(Decimal.new("100"), :celsius)
    {:ok, fahrenheit} = Cldr.Unit.Conversion.convert(celsius, :fahrenheit)
    fahrenheit = Cldr.Unit.ratio_to_float(fahrenheit)
    assert fahrenheit.value == 212
  end

  test "decimal functional conversion - kelvin" do
    celsius = Cldr.Unit.new!(Decimal.new("0"), :celsius)
    {:ok, kelvin} = Cldr.Unit.Conversion.convert(celsius, :kelvin)
    kelvin = Cldr.Unit.ratio_to_float(kelvin)
    assert kelvin.value == 273.15
  end

  test "decimal conversion without function" do
    celsius = Cldr.Unit.new!(Decimal.new(100), :celsius)
    {:ok, celsius2} = Cldr.Unit.Conversion.convert(celsius, :celsius)

    assert Decimal.equal?(Cldr.Unit.value(celsius2), Decimal.new(100))
  end

  test "that to_string is invoked by the String.Chars protocol" do
    unit = Cldr.Unit.new!(23, :foot)
    assert to_string(unit) == "23 feet"
  end

  test "formatting a list" do
    list = [Cldr.Unit.new!(23, :foot), Cldr.Unit.new!(5, :inch)]
    assert Cldr.Unit.to_string(list, MyApp.Cldr, []) == {:ok, "23 feet and 5 inches"}
  end

  test "localize a unit" do
    unit = Cldr.Unit.new!(100, :meter)

    assert Cldr.Unit.localize(unit, usage: :person, territory: :US) ==
             [Cldr.Unit.new!(:inch, Ratio.new(21_617_278_211_378_380_800, 5_490_788_665_690_109))]

    assert Cldr.Unit.localize(unit, usage: :person_height, territory: :US) ==
             [
               Cldr.Unit.new!(:foot, 328),
               Cldr.Unit.new!(:inch, Ratio.new(5_534_023_222_111_776, 5_490_788_665_690_109))
             ]

    assert Cldr.Unit.localize(unit, usage: :unknown, territory: :US) ==
             {:error,
              {Cldr.Unit.UnknownUsageError,
               "The unit category :length does not define a usage :unknown"}}
  end

  test "localize a decimal unit" do
    u = Cldr.Unit.new!(Decimal.new(20), :meter)

    assert Cldr.Unit.localize(u, territory: :US) ==
             [Cldr.Unit.new!(:foot, Ratio.new(360_287_970_189_639_680, 5_490_788_665_690_109))]
  end

  test "localize a ratio unit" do
    u = Cldr.Unit.new!(:foot, Ratio.new(360_287_970_189_639_680, 5_490_788_665_690_109))
    assert Cldr.Unit.localize(u, territory: :AU) == [Cldr.Unit.new!(:meter, 20)]
  end

  test "to_string a decimal unit" do
    u = Cldr.Unit.new!(Decimal.new(20), :meter)
    assert Cldr.Unit.to_string(u) == {:ok, "20 metres"}
  end

  test "to_string a ratio unit" do
    u = Cldr.Unit.new!(:foot, Ratio.new(360_287_970_189_639_680, 5_490_788_665_690_109))
    assert Cldr.Unit.to_string(u) == {:ok, "65.617 feet"}
  end

  test "inspection when non-default usage or non-default format options" do
    assert inspect(Cldr.Unit.new!(:meter, 1)) == "#Cldr.Unit<:meter, 1>"

    assert inspect(Cldr.Unit.new!(:meter, 1, usage: :road)) ==
             "#Cldr.Unit<:meter, 1, usage: :road, format_options: []>"

    assert inspect(Cldr.Unit.new!(:meter, 1, format_options: [round_nearest: 50])) ==
             "#Cldr.Unit<:meter, 1, usage: :default, format_options: [round_nearest: 50]>"
  end

  test "that unit skeletons are used for formatting" do
    unit = Cldr.Unit.new!(311, :meter, usage: :road)
    localized = Cldr.Unit.localize(unit, MyApp.Cldr, territory: :SE)

    assert localized ==
             [Cldr.Unit.new!(:meter, 311, usage: :road, format_options: [round_nearest: 50])]

    assert Cldr.Unit.to_string!(localized) == "300 metres"
  end

  test "creating a compound unit" do
    assert {:ok, unit} = Cldr.Unit.new("meter_per_kilogram", 1)
    assert unit.usage == :default
  end

  test "to_string a compound unit" do
    unit = Cldr.Unit.new!("meter_per_kilogram", 1)
    assert {:ok, "1 metre per kilogram"} = Cldr.Unit.to_string(unit)
  end

  test "to_string a per compound unit" do
    unit = Cldr.Unit.new!("meter_per_square_kilogram", 1)
    assert Cldr.Unit.to_string(unit) == {:ok, "1 metre per square kilogram"}

    unit = Cldr.Unit.new!("meter_per_square_kilogram", 2)
    assert Cldr.Unit.to_string(unit) == {:ok, "2 metres per square kilogram"}
  end

  test "a muliplied unit to_string" do
    unit = Cldr.Unit.new!("meter ampere volt", 3)
    assert Cldr.Unit.to_string(unit) == {:ok, "3 metres⋅amperes⋅volts"}
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
