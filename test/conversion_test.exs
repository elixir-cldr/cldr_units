defmodule Cldr.Unit.Conversion.Test do
  use ExUnit.Case

  alias Cldr.Unit.Test.ConversionData

  for t <- ConversionData.conversions() do
    test "##{t.line} that #{t.from} is convertible to #{t.to}" do
      {:ok, from} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.from))
      {:ok, to} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.to))
      assert from == to
    end
  end

  for t <- ConversionData.conversions(), t.line in [69, 58, 29, 151] do
    test "##{t.line} that #{t.from} converted to #{t.to} is #{inspect t.result}" do
      unit = Cldr.Unit.new!(unquote(t.from), 1000)
      {expected_result, round_digits, round_significant} = unquote(Macro.escape(t.result))

      result =
        unit
        |> Cldr.Unit.Conversion.convert!(unquote(t.to))
        |> IO.inspect(label: "Before ratio_to_float")
        |> Cldr.Unit.ratio_to_float
        |> IO.inspect(label: "After ratio_to_float")
        |> ConversionData.round(round_digits, round_significant)

      if is_integer(result.value) and is_float(expected_result) do
        assert result.value == trunc(Float.round(expected_result))
      else
        assert result.value == expected_result
      end
    end
  end
end