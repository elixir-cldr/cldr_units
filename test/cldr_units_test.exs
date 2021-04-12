defmodule Cldr.UnitsTest do
  use ExUnit.Case

  test "that centimetre conversion is correct" do
    assert Cldr.Unit.convert(Cldr.Unit.new!(:millimeter, 300), :centimeter) ==
             Cldr.Unit.new(:centimeter, 30.0)
  end

  test "that pluralization in non-en locales works" do
    assert Cldr.Unit.Format.to_string!(1, MyApp.Cldr, locale: "de", unit: :microsecond) ==
             "1 Mikrosekunde"

    assert Cldr.Unit.Format.to_string!(123, MyApp.Cldr, locale: "de", unit: :microsecond) ==
             "123 Mikrosekunden"

    assert Cldr.Unit.Format.to_string!(1, MyApp.Cldr, locale: "de", unit: :pint) == "1 Pint"
    assert Cldr.Unit.Format.to_string!(123, MyApp.Cldr, locale: "de", unit: :pint) == "123 Pints"

    assert Cldr.Unit.Format.to_string!(1, MyApp.Cldr, locale: "de", unit: :century) ==
             "1 Jahrhundert"

    assert Cldr.Unit.Format.to_string!(123, MyApp.Cldr, locale: "de", unit: :century) ==
             "123 Jahrhunderte"
  end

  test "locale option is passed to Cldr.Number.to_string" do
    assert Cldr.Unit.Format.to_string!(1, MyApp.Cldr, format: :spellout, locale: "de", unit: :pint) ==
             "eins Pint"
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
    fahrenheit = Cldr.Unit.to_float_unit(fahrenheit)
    assert fahrenheit.value == 212
  end

  test "decimal functional conversion - kelvin" do
    celsius = Cldr.Unit.new!(Decimal.new("0"), :celsius)
    {:ok, kelvin} = Cldr.Unit.Conversion.convert(celsius, :kelvin)
    kelvin = Cldr.Unit.to_float_unit(kelvin)
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
    assert Cldr.Unit.Format.to_string(list, MyApp.Cldr, []) == {:ok, "23 feet and 5 inches"}
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
    assert Cldr.Unit.Format.to_string(u) == {:ok, "20 meters"}
  end

  test "to_string a ratio unit" do
    u = Cldr.Unit.new!(:foot, Ratio.new(360_287_970_189_639_680, 5_490_788_665_690_109))
    assert Cldr.Unit.Format.to_string(u) == {:ok, "65.617 feet"}
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

    assert Cldr.Unit.Format.to_string!(localized) == "300 meters"
  end

  test "creating a compound unit" do
    assert {:ok, unit} = Cldr.Unit.new("meter_per_kilogram", 1)
    assert unit.usage == :default
  end

  test "to_string a compound unit" do
    unit = Cldr.Unit.new!("meter_per_kilogram", 1)
    assert {:ok, "1 meter per kilogram"} = Cldr.Unit.Format.to_string(unit)
  end

  test "to_string for a pattern with no substitutions when the unit value is 0, 1 or 2" do
    unit =  Cldr.Unit.new!(1, :hour)
    assert Cldr.Unit.to_string(unit, locale: "he") == {:ok, "שעה"}
    assert Cldr.Unit.to_string(unit, locale: "ar") == {:ok, "ساعة"}

    unit =  Cldr.Unit.new!(-1, :hour)
    assert Cldr.Unit.to_string(unit, locale: "he") == {:ok, "‎-1 שעות"}
    assert Cldr.Unit.to_string(unit, locale: "ar") == {:ok, "؜-١ ساعة"}

    unit =  Cldr.Unit.new!(3, :hour)
    assert Cldr.Unit.to_string(unit, locale: "he") == {:ok, "3 שעות"}
  end

  test "to_string a complex compound unit" do
    unit = Cldr.Unit.new!("square millimeter per cubic fathom", 3)
    assert Cldr.Unit.Format.to_string(unit) == {:ok, "3 square millimeters per cubic fathom"}
  end

  test "to_string a per compound unit" do
    unit = Cldr.Unit.new!("meter_per_square_kilogram", 1)
    assert Cldr.Unit.Format.to_string(unit) == {:ok, "1 meter per square kilogram"}

    unit = Cldr.Unit.new!("meter_per_square_kilogram", 2)
    assert Cldr.Unit.Format.to_string(unit) == {:ok, "2 meters per square kilogram"}
  end

  test "localization with current process locales" do
    assert Cldr.Unit.localize(Cldr.Unit.new!(2, :meter, usage: :person_height))
    assert Cldr.Unit.localize(Cldr.Unit.new!(2, :meter, usage: :person_height), locale: "fr")
  end

  test "a multiplied unit to_string" do
    unit = Cldr.Unit.new!("meter ampere volt", 3)
    assert Cldr.Unit.Format.to_string(unit) == {:ok, "3 volt-meter-amperes"}
  end

  test "create a unit that is directly translatable but has no explicit conversion" do
    assert {:ok, "1 kilowatt hour"} ==
             Cldr.Unit.new!(1, :kilowatt_hour) |> Cldr.Unit.Format.to_string()

    assert {:ok, "1 Kilowattstunde"} ==
             Cldr.Unit.new!(1, :kilowatt_hour) |> Cldr.Unit.Format.to_string(locale: "de")
  end

  test "that a translatable unit name in binary form gets identified as translatable" do
    assert {:ok, "1 kilowatt hour"} ==
             Cldr.Unit.new!(1, "kilowatt_hour") |> Cldr.Unit.Format.to_string()
  end

  test "unit categories" do
    assert Cldr.Unit.known_unit_categories() ==
             [
               :acceleration,
               :angle,
               :area,
               :concentr,
               :consumption,
               :digital,
               :duration,
               :electric,
               :energy,
               :force,
               :frequency,
               :graphics,
               :length,
               :light,
               :mass,
               :power,
               :pressure,
               :speed,
               :temperature,
               :torque,
               :volume
             ]
  end

  test "unit categories for" do
    assert {:ok, _list} = Cldr.Unit.known_units_for_category(:volume)

    assert Cldr.Unit.known_units_for_category(:invalid) ==
             {:error,
              {Cldr.Unit.UnknownUnitCategoryError, "The unit category :invalid is not known."}}
  end

  test "display names" do
    assert Cldr.Unit.display_name(:liter) == "liters"
    assert Cldr.Unit.display_name(:liter, locale: "fr") == "litres"
    assert Cldr.Unit.display_name(:liter, locale: "fr", style: :short) == "l"

    assert Cldr.Unit.display_name(:liter, locale: "fr", style: :invalid) ==
             {:error, {Cldr.UnknownFormatError, "The unit style :invalid is not known."}}

    assert Cldr.Unit.display_name(:liter, locale: "xx", style: :short) ==
             {:error, {Cldr.UnknownLocaleError, "The locale \"xx\" is not known."}}

    assert Cldr.Unit.display_name(:invalid, locale: "fr", style: :short) ==
             {:error, {Cldr.UnknownUnitError, "The unit :invalid is not known."}}
  end

  test "Unit of 1 retrieves a default pattern is plural category pattern does not exist" do
    unit = Cldr.Unit.new!(1, :pascal)
    assert Cldr.Unit.to_string(unit, locale: "de", style: :short) == {:ok, "1 Pa"}
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
