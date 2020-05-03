defmodule Cldr.Unit.Prefix do
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

  @power_units [{"square", 2}, {"cubic", 3}]
  def power_units do
    @power_units
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
end
