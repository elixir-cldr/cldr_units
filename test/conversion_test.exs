defmodule Cldr.Unit.Conversion.Test do
  use ExUnit.Case

  for t <- Cldr.Unit.TestData.conversions() do
    test "that #{t.from} is convertible to #{t.to}" do
      {:ok, from} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.from))
      {:ok, to} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.to))
      assert from == to
    end
  end

  for t <- Cldr.Unit.TestData.conversions() do
    test "that #{t.from} comverted to #{t.to} is #{inspect t.result}" do
      unit = Cldr.Unit.new(unquote(t.from), 1000)
      {expected_result, rounding} = unquote(t.result)

      result =
        unit
        |> Cldr.Unit.Conversion.convert(unquote(t.to))
        |> Cldr.Unit.TestData.round(rounding)

      assert result.value == expected_result
    end
  end
end