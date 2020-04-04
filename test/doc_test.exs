defmodule Doc.Test do
  use ExUnit.Case

  doctest Cldr.Unit
  doctest Cldr.Unit.Conversion
  doctest Cldr.Unit.Conversions
  doctest Cldr.Unit.Math
  doctest Cldr.Unit.Parser
  doctest Cldr.Unit.Alias

  doctest MyApp.Cldr.Unit
end
