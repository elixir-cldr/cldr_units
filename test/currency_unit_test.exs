defmodule Cldr.CurrencyUnits.Test do
  use ExUnit.Case, async: true

  test "creation of standalone currency-based units" do
    assert {:ok, _} = Cldr.Unit.new(2, "curr-eur")
    assert {:error, _} = Cldr.Unit.new(2, "curr-xyz")
    assert {:error, _} = Cldr.Unit.new(2, "curr-invalid")
  end

  test "creation of currency-based units" do
    assert {:ok, _} = Cldr.Unit.new(2, "curr-eur-per-gallon")
    assert {:error, _} = Cldr.Unit.new(2, "curr-xyz-per-gallon")
    assert {:error, _} = Cldr.Unit.new(2, "curr-invalid-per-gallon")
  end

  test "currency-based unit formatting" do
    assert Cldr.Unit.to_string(Cldr.Unit.new!(2, "curr-usd")) == {:ok, "$2.00"}

    assert Cldr.Unit.to_string(Cldr.Unit.new!(2, "curr-usd-per-gallon")) ==
             {:ok, "$2.00 per gallon"}

    assert Cldr.Unit.to_string(Cldr.Unit.new!(2, "gallon-per-curr-usd")) ==
             {:ok, "2 gallons per US dollar"}
  end
end
