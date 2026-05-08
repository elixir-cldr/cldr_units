defmodule Doc.Test do
  use ExUnit.Case, async: true

  # Pin the Decimal.Context precision so high-precision conversion fixtures in
  # the doctests below remain stable across Decimal versions whose default
  # context precision differs (Decimal 2.x = 28; Decimal 3.0 = 34).
  setup do
    original = Decimal.Context.get()
    Decimal.Context.set(%{original | precision: 28})
    on_exit(fn -> Decimal.Context.set(original) end)
    :ok
  end

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
