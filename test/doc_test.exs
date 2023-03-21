defmodule Doc.Test do
  use ExUnit.Case, async: true

  doctest Cldr.Unit
  doctest Cldr.Unit.Conversion
  doctest Cldr.Unit.Conversions
  doctest Cldr.Unit.Preference
  doctest Cldr.Unit.Math
  doctest Cldr.Unit.Parser
  doctest Cldr.Unit.Alias
  doctest Cldr.Unit.Format
  doctest Cldr.Unit.Range

  doctest MyApp.Cldr.Unit
end
