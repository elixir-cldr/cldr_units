defmodule Cldr.Unit.Conversions do
  @moduledoc false

  alias Cldr.Unit.Conversion.Derived
  alias Cldr.Unit.Alias

  @conversions Map.get(Cldr.Config.units(), :conversions)
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
  |> Derived.add_derived_conversions(Cldr.Unit.known_units |> Enum.map(&Alias.alias/1))

  @identity_conversions Enum.map(@conversions, fn
    {_k, v} -> {v.base_unit, %{factor: 1, offset: 0}}
  end)
  |> Map.new

  @all_conversions Map.merge(@conversions, @identity_conversions)

  def conversions do
    unquote(Macro.escape(@all_conversions))
  end

  def conversion_factor(unit) do
    Map.get(conversions(), unit)
  end

end