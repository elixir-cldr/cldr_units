defmodule Cldr.Unit.Prefix do
  @moduledoc false

  @units Cldr.Config.units()

  @doc """
  Returns the power (exponent) of the base unit
  of a conversion.
  """
  def power(%{base_unit: [power, _unit]}) do
    Map.fetch!(power_units(), power)
  end

  def power(%{base_unit: [_unit]}) do
    1
  end

  @doc """
  Returns the base unit power factor from
  its numerical representation.
  """
  def prefix_from_power(power) when power in 2..15 do
    Map.fetch!(inverse_power_units(), power)
  end

  ##
  ## SI prefixes
  ##

  @si_factors @units
  |> Map.fetch!(:prefixes)
  |> Enum.reduce([], fn
    {prefix, %{base: 10 = base, power: power}}, acc ->
      abs_factor = Cldr.Math.power(base, abs(power))

      factor =
        if power < 0, do: Decimal.div(1, abs_factor), else: abs_factor

      [{to_string(prefix), factor} | acc]

    _other, acc ->
      acc
  end)
  |> Map.new()

  def si_factors do
    @si_factors
  end

  @si_power_prefixes @si_factors
                     |> Enum.map(fn
                       {prefix, factor} when is_integer(factor) ->
                         {prefix, Cldr.Math.log10(factor) |> round()}

                       {prefix, %Decimal{} = factor} ->
                         {prefix, Decimal.to_integer(Cldr.Math.log10(factor)) |> Decimal.round()}
                     end)
                     |> Map.new()

  def si_power_prefixes do
    @si_power_prefixes
  end

  @si_sort_order @si_factors
                 |> Enum.map(fn
                   {k, v} when is_integer(v) -> {k, v / 1.0}
                   {k, v} -> {k, Decimal.to_float(v)}
                 end)
                 |> Enum.sort(fn {_k1, v1}, {_k2, v2} -> v1 > v2 end)
                 |> Enum.map(&elem(&1, 0))
                 |> Enum.with_index()

  def si_sort_order do
    @si_sort_order
  end

  @si_keys @si_power_prefixes
           |> Enum.map(fn {_name, exp} ->
             String.replace("10p#{exp}", "-", "_") |> String.to_atom()
           end)

  def si_keys do
    @si_keys
  end

  ##
  ## Power prefixes
  ##

  @power_units @units
  |> Map.fetch!(:components)
  |> Map.fetch!(:power)
  |> Enum.with_index(2)
  |> Enum.map(fn {k, v} ->
    v = if v > 3, do: v - 2, else: v
    {String.to_atom(k), v}
  end)
  |> Map.new()

  def power_units do
    @power_units
  end

  @inverse_power_units @power_units
  |> Enum.map(fn {k, v} -> {v, k} end)
  |> Map.new()
  |> Map.put(2, :square)
  |> Map.put(3, :cubic)

  def inverse_power_units do
    @inverse_power_units
  end

  @power_keys @power_units
              |> Enum.map(fn {_name, exp} ->
                String.to_atom("power#{exp}")
              end)

  def power_keys do
    @power_keys
  end

  ##
  ## Binary prefixes, 1024 ^ x where 1 <= x <= 8
  ##

  @binary_factors @units
  |> Map.fetch!(:prefixes)
  |> Enum.reduce([], fn
    {prefix, %{base: 2 = base, power: power}}, acc ->
      factor = Cldr.Math.power(base, power)

      [{to_string(prefix), factor} | acc]

    _other, acc ->
      acc
  end)
  |> Map.new()

  def binary_factors do
    @binary_factors
  end

  @binary_keys @binary_factors
               |> Enum.map(fn {_name, exp} ->
                 exp = trunc(:math.log2(exp) / 10)
                 String.to_atom("1024p#{exp}")
               end)

  def binary_keys do
    @binary_keys
  end

  @binary_prefixes @binary_factors
                   |> Enum.map(fn
                     {prefix, factor} when is_integer(factor) ->
                       {prefix, trunc(:math.log2(factor) / 10)}
                   end)
                   |> Map.new()

  def binary_prefixes do
    @binary_prefixes
  end

  @binary_sort_order @binary_factors
                     |> Enum.sort(fn {_k1, v1}, {_k2, v2} -> v1 > v2 end)
                     |> Enum.map(&elem(&1, 0))
                     |> Enum.with_index()

  def binary_sort_order do
    @binary_sort_order
  end

  ##
  ## Overall prefixes
  ##

  @prefixes Enum.sort(Map.keys(@si_factors)) ++
              Enum.sort(Map.keys(@binary_factors)) ++
              Enum.map(@power_units, fn {factor, _} -> to_string(factor) <> "_" end)

  def prefixes do
    @prefixes
  end
end
