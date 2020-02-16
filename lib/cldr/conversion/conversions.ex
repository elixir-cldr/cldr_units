defmodule Cldr.Unit.Conversions do
  @moduledoc false

  @conversions Map.get(Cldr.Config.unit_conversion_info(), :conversions)
  |> Enum.map(fn
      {unit, %{factor: factor} = conversion} when is_number(factor) ->
         {unit, conversion}
      {unit, %{factor: factor} = conversion} ->
         {unit, %{conversion | factor: Ratio.new(factor.numerator, factor.denominator)}}
  end)
  |> Enum.map(fn
      {unit, %{offset: offset} = conversion} when is_number(offset) ->
         {unit, conversion}
      {unit, %{offset: offset} = conversion} ->
         {unit, %{conversion | offset: Ratio.new(offset.numerator, offset.denominator)}}
  end)
  |> Map.new

  @inverse_conversions Enum.map(@conversions, fn {_k, v} -> {v.base_unit, %{factor: 1, offset: 0}} end)
                       |> Map.new

  @all_conversions Map.merge(@conversions, @inverse_conversions)

  def conversions do
    unquote(Macro.escape(@all_conversions))
  end

  def conversion_factor(unit) do
    Map.get(conversions(), unit)
  end

end