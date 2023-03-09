defmodule Cldr.IntegerUnits.Test do
  use ExUnit.Case, async: true

  test "creation of standalone integer-based units" do
    assert {:ok, _} = Cldr.Unit.new(2, "100-gram")
  end

  test "creation of integer-based units" do
    assert {:ok, _} = Cldr.Unit.new(2, "calorie_per_100-gram")
  end

  test "integer-based unit formatting" do
    assert {:ok, "2 calories per 100 grams"} ==
             Cldr.Unit.to_string(Cldr.Unit.new!(2, "calorie_per_100-gram"), MyApp.Cldr)
  end
end
