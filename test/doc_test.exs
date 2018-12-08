defmodule Doc.Test do
  use ExUnit.Case

  doctest Cldr.Unit
  doctest Cldr.Unit.Conversion
  doctest Cldr.Unit.Math

  doctest TestBackend.Cldr.Unit
end
