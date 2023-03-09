defmodule Cldr.Unit.PrefixTest do
  use ExUnit.Case, async: true

  test "New SI units ronna, quetta, ronto, quecto" do
    assert %Cldr.Unit{} = Cldr.Unit.new!(10, "ronnameter")
    assert %Cldr.Unit{} = Cldr.Unit.new!(10, "quettameter")
    assert %Cldr.Unit{} = Cldr.Unit.new!(10, "rontometer")
    assert %Cldr.Unit{} = Cldr.Unit.new!(10, "quectometer")
  end
end