defmodule Cldr.Unit.Conversions do
  @moduledoc false

  alias Cldr.Unit.Conversion

  @conversions Map.get(Cldr.Config.units(), :conversions)
  |> Enum.map(fn
    {k, v} -> {k, struct(Conversion, v)}
  end)
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

  @identity_conversions Enum.map(@conversions, fn
    {_k, v} -> {v.base_unit, %Conversion{base_unit: v.base_unit}}
  end)
  |> Map.new

  @all_conversions Map.merge(@conversions, @identity_conversions)

  def conversions do
    unquote(Macro.escape(@all_conversions))
  end

  def conversion_for(unit) when is_atom(unit) do
    with {:ok, conversion} <- Map.fetch(conversions(), unit) do
      {:ok, conversion}
    else
      :error -> {:error, Cldr.Unit.unit_error(unit)}
    end
  end

  def conversion_for(unit) when is_binary(unit) do
    unit
    |> String.to_existing_atom()
    |> conversion_for()
  rescue ArgumentError ->
    {:error, Cldr.Unit.unit_error(unit)}
  end

end