defmodule Cldr.Unit.Prefix do
  @moduledoc false

  @si_factors %{
    "yokto" => Ratio.new(1, 1_000_000_000_000_000_000_000_000),
    "zepto" => Ratio.new(1, 1_000_000_000_000_000_000_000),
    "atto" => Ratio.new(1, 1_000_000_000_000_000_000),
    "femto" => Ratio.new(1, 1_000_000_000_000_000),
    "pico" => Ratio.new(1, 1_000_000_000_000),
    "nano" => Ratio.new(1, 1_000_000_000),
    "micro" => Ratio.new(1, 1_000_000),
    "milli" => Ratio.new(1, 1_000),
    "centi" => Ratio.new(1, 100),
    "deci" => Ratio.new(1, 10),
    "deka" => 10,
    "hecto" => 100,
    "kilo" => 1_000,
    "mega" => 1_000_000,
    "giga" => 1_000_000_000,
    "tera" => 1_000_000_000_000,
    "peta" => 1_000_000_000_000_000,
    "exa" => 1_000_000_000_000_000_000,
    "zetta" => 1_000_000_000_000_000_000_000,
    "yotta" => 1_000_000_000_000_000_000_000_000
  }

  def si_factors do
    @si_factors
  end

  @si_power_prefixes @si_factors
                     |> Enum.map(fn
                       {prefix, factor} when is_integer(factor) ->
                         {prefix, trunc(:math.log10(factor))}

                       {prefix, %Ratio{denominator: factor}} ->
                         {prefix, -trunc(:math.log10(factor))}
                     end)
                     |> Map.new()

  def si_power_prefixes do
    @si_power_prefixes
  end

  @si_sort_order @si_factors
                 |> Enum.map(fn
                   {k, v} when is_integer(v) -> {k, v / 1.0}
                   {k, v} -> {k, Ratio.to_float(v)}
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

  @power_units [{"square", 2}, {"cubic", 3}]

  def power_units do
    @power_units
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

  @binary_factors %{
    "kibi" => 1_024,
    "mebi" => 2_048,
    "gibi" => 4_096,
    "tebi" => 8_192,
    "pebi" => 16_384,
    "exbi" => 32_768,
    "zebi" => 65_536,
    "yobi" => 131_072
  }

  def binary_factors do
    @binary_factors
  end

  @binary_keys @binary_factors
              |> Enum.map(fn {_name, exp} ->
                exp = trunc(:math.log2(exp)) - 9
                String.to_atom("1024p#{exp}")
              end)

  def binary_keys do
    @binary_keys
  end

  @binary_prefixes @binary_factors
                     |> Enum.map(fn
                       {prefix, factor} when is_integer(factor) ->
                         {prefix, trunc(:math.log2(factor)) - 9}
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

  @prefixes Map.keys(@si_factors) ++
    Map.keys(@binary_factors) ++
    Enum.map(@power_units, fn {factor, _} -> factor <> "_" end)

  def prefixes do
    @prefixes
  end

end
