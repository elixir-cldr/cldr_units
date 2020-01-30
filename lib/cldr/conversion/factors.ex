defmodule Cldr.Unit.Factor do
  @moduledoc false

  @conversions Cldr.Config.unit_conversion_info()

  # Here we are reconstituting the rationals representing the factor
  # and offset for a conversion from their map form that came from
  # JSON decoding.
  @factors @conversions
           |> Map.get(:conversions)
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


  @inverse_factors Enum.map(@factors, fn {_k, v} -> {v.target, %{factor: 1, offset: 0}} end)
  |> Map.new

  @all_factors Map.merge(@factors, @inverse_factors)
               # |> Cldr.Unit.Prefix.add_si_prefix_factors()

  def factors do
    unquote(Macro.escape(@all_factors))
  end

  def factors(factor) do
    Map.get(factors(), factor)
  end


end