defmodule Cldr.Unit.Conversion.Test do
  use ExUnit.Case

  for t <- Cldr.Unit.TestData.conversions() do
    test "that #{t.from} is convertible to #{t.to}" do
      {:ok, from} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.from))
      {:ok, to} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.to))
      assert from == to
    end
  end
end