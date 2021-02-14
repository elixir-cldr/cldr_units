defmodule Cldr.Unit.Conversion.Test do
  use ExUnit.Case

  alias Cldr.Unit.Test.ConversionData

  for t <- ConversionData.conversions() do
    test "##{t.line} that #{t.from} is convertible to #{t.to}" do
      {:ok, from} = Cldr.Unit.BaseUnit.canonical_base_unit(unquote(t.from))
      {:ok, to} = Cldr.Unit.BaseUnit.canonical_base_unit(unquote(t.to))
      assert from == to
    end
  end

  for t <- ConversionData.conversions(), t.line in [69, 58, 29, 151] do
    test "##{t.line} that #{t.from} converted to #{t.to} is #{inspect(t.result)}" do
      unit = Cldr.Unit.new!(unquote(t.from), 1000)
      {expected_result, round_digits, round_significant} = unquote(Macro.escape(t.result))

      result =
        unit
        |> Cldr.Unit.Conversion.convert!(unquote(t.to))
        |> Cldr.Unit.ratio_to_float()
        |> ConversionData.round(round_digits, round_significant)

      if is_integer(result.value) and is_float(expected_result) do
        assert result.value * 1.0 == expected_result
      else
        assert result.value == expected_result
      end
    end
  end

  test "convert!/2" do
    assert MyApp.Cldr.Unit.convert!(MyApp.Cldr.Unit.new!(:foot, 3), :meter)
  end
end
