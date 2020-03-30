defmodule Cldr.Unit.Conversion.Derived do
  @moduledoc false

  # The localisable units (the units parameter here) includes
  # several SI prefixes (like kilo and milli) that are not included
  # in the CLDR conversion byt design. It is intended that these be
  # derived and that is what this function does.
  #
  # We hold the strategy that the only valid units are ones that
  # can be localised so we:
  #
  # * iterate over the list of known units
  #
  # * if the unit is already convertible them move on
  #
  # * if its an SI prefixed unit and the base unit is convertible, create a
  #   new conversion with the SI prefix and scaled factor
  #
  # * if its not an SI prefixed unit, move on

  alias Cldr.Unit
  alias Cldr.Unit.Conversions

  @si_factors %{
    "pico"  =>  Ratio.new(1, 1_000_000_000_000),
    "nano"  =>  Ratio.new(1, 1_000_000_000),
    "micro" =>  Ratio.new(1, 1_000_000),
    "milli" =>  Ratio.new(1, 1_000),
    "centi" =>  Ratio.new(1, 100),
    "deci"  =>  10,
    "hecto" =>  100,
    "kilo"  =>  1_000,
    "mega"  =>  1_000_000,
    "giga"  =>  1_000_000_000,
    "tera"  =>  1_000_000_000_000,
    "peta"  =>  1_000_000_000_000_000,
    "exa"   =>  1_000_000_000_000_000_000,
    "zetta" =>  1_000_000_000_000_000_000_000,
    "yotta" =>  1_000_000_000_000_000_000_000_000
  }

  @per "_per_"

  def normalize_unit(unit_string, _conversions \\ Conversions.conversions()) do
    unit_string
    |> String.replace("-", "_")
    |> String.split("_per_", parts: 2)
    |> Enum.map(&normalize_subunit/1)
  end

  def normalize_subunit(unit_string) do
    unit_string
    |> String.replace(@per, "")
    |> String.split("_")
    |> expand_power_units()
    |> combine_instances()
    |> Enum.sort(&unit_sorter/2)
  end

  def expand_power_units([]) do
    []
  end

  def expand_power_units(["square", unit | rest]) do
    [unit, unit | expand_power_units(rest)]
  end

  def expand_power_units(["cubic", unit | rest]) do
    [unit, unit, unit | expand_power_units(rest)]
  end

  def expand_power_units([unit | rest]) do
    [unit | expand_power_units(rest)]
  end

  defp unit_sorter(a, b) do
    case {unit_sort_key(a), unit_sort_key(b)} do
      {{key, order_1}, {key, order_2}} -> order_1 < order_2
      {{key_1, _order_1}, key_2} when is_integer(key_2) -> key_1 < key_2
      {key_1, {key_2, _order_2}} when is_integer(key_1) -> key_1 < key_2
      {key_1, key_2} -> key_1 < key_2
    end
  end

  defp combine_instances(units) do
    units
    |> Enum.group_by(&(&1))
    |> Enum.map(fn
      {k, v} when length(v) == 1 -> k
      {k, v} when length(v) == 2 -> "square_#{k}"
      {k, v} when length(v) == 3 -> "cubic_#{k}"
    end)
  end

  def unit_sort_key(<< "square_", unit :: binary >>) do
    unit_sort_key(unit)
  end

  def unit_sort_key(<< "cubic_", unit :: binary >>) do
    unit_sort_key(unit)
  end

  @si_order @si_factors
  |> Enum.map(fn
    {k, v} when is_integer(v) -> {k, v /  1.0}
    {k, v} -> {k, Ratio.to_float(v)}
  end)
  |> Enum.sort(fn
    {_k1, v1}, {_k2, v2} -> v1 > v2
  end)
  |> Enum.map(fn
    {k, _v} -> k
  end)
  |> Enum.with_index

  for {prefix, order} <- @si_order do
    def unit_sort_key(<< unquote(prefix), unit :: binary >>) do
      {unit_sort_key(unit), unquote(order)}
    end
  end

  def unit_sort_key(unit) do
    with {:ok, base_unit} <- Unit.base_unit(unit) do
      Map.get(base_units_in_order(), base_unit)
    else
      _other -> 0
    end
  end

  @base_units_in_order Cldr.Config.units
  |> Map.get(:base_units)
  |> Enum.map(&(elem(&1, 1)))
  |> Enum.with_index
  |> Map.new

  def base_units_in_order do
    @base_units_in_order
  end

  def add_derived_conversions(conversions, [unit | _rest] = units) when is_atom(unit) do
    string_units = Cldr.Map.stringify_values(units)
    string_conversions = Cldr.Map.stringify_keys(conversions, level: 1)
    add_derived_conversions(string_conversions, string_units)
  end

  def add_derived_conversions(conversions, units) do
    conversions
    |> merge(units, &si_factor_conversions/2)
    |> merge(units, &exponent_unit_conversions/2)
    |> merge(units, &per_unit_conversions/2)
    |> merge(units, &compound_unit_conversions/2)
    |> Cldr.Map.atomize_keys(level: 1)
  end

  def unconvertible_units do
    units = Cldr.Unit.known_units |> Enum.map(&Cldr.Unit.Alias.alias/1)
    conversions = Cldr.Unit.Conversions.conversions()

    for unit <- units, not Map.has_key?(conversions, unit) do
      unit
    end
  end

  defp merge(conversions, units, fun) do
    for unit <- units, not Map.has_key?(conversions, unit) do
      fun.(conversions, unit)
    end
    |> Enum.reject(&is_nil/1)
    |> Map.new
    |> Map.merge(conversions)
  end

  defp si_factor_conversions(conversions, unit) do
    with {:ok, _prefix, base_unit, si_factor} <- resolve_si_prefix(unit) do
      if Map.has_key?(conversions, base_unit) do
        base_conversion = Map.fetch!(conversions, base_unit)
        new_factor = Ratio.mult(base_conversion.factor, si_factor)
        {unit, %{base_conversion | factor: new_factor}}
      end
    else
      _other -> nil
    end
  end

  defp exponent_unit_conversions(conversions, unit) do
    with {:ok, exponent, prefix, base_unit} <- resolve_exponent_prefix(unit) do
      if Map.has_key?(conversions, base_unit) do
        base_conversion = Map.fetch!(conversions, base_unit)
        new_factor = Ratio.pow(base_conversion.factor, exponent)

        conversion =
          base_conversion
          |> Map.put(:factor, new_factor)
          |> Map.put(:base_unit, String.to_atom("#{prefix}_#{base_unit}"))

        {unit, conversion}
      end
    else
      _other -> nil
    end
  end

  defp per_unit_conversions(conversions, unit) do
    conversion =
      unit
      |> String.split("_per_")
      |> Enum.map(&Map.get(conversions, &1))
      |> craft_per_unit_conversion()

     if conversion, do: {unit, conversion}, else: nil
  end

  defp compound_unit_conversions(conversions, unit) do
    conversion =
      unit
      |> String.split("_")
      |> form_two_subunits
      |> Enum.map(&Map.get(conversions, &1))
      |> craft_compound_unit_conversion()

    if conversion, do: {unit, conversion}, else: nil
  end

  defp craft_per_unit_conversion([nil]), do: nil
  defp craft_per_unit_conversion([nil, _]), do: nil
  defp craft_per_unit_conversion([_, nil]), do: nil

  defp craft_per_unit_conversion([c1, c2]) do
    c1
    |> Map.put(:base_unit, String.to_atom("#{c1.base_unit}_per_#{c2.base_unit}"))
    |> Map.put(:factor, Ratio.div(c1.factor, c2.factor))
  end

  defp form_two_subunits([first, second]), do: [first, second]
  defp form_two_subunits([first, second, third]), do: ["#{first}_#{second}", third]
  defp form_two_subunits(_other), do: [nil, nil]

  defp craft_compound_unit_conversion([nil]), do: nil
  defp craft_compound_unit_conversion([nil, _]), do: nil
  defp craft_compound_unit_conversion([_, nil]), do: nil

  defp craft_compound_unit_conversion([c1, c2]) do
    c1
    |> Map.put(:base_unit, String.to_atom("#{c1.base_unit}_#{c2.base_unit}"))
    |> Map.put(:factor, Ratio.mult(c1.factor, c2.factor))
  end

  defp resolve_exponent_prefix(<< "square_", base_unit :: binary >>) do
    {:ok, 2, "square", base_unit}
  end

  defp resolve_exponent_prefix(<< "cubic_", base_unit :: binary >>) do
    {:ok, 3, "cubic", base_unit}
  end

  defp resolve_exponent_prefix(unit) do
    {:error, "No known expenent prefix for unit #{unit}"}
  end

  for {prefix, factor} <- @si_factors do
    defp resolve_si_prefix(<< unquote(prefix), base_unit :: binary >>) do
      {:ok, unquote(prefix), base_unit, unquote(Macro.escape(factor))}
    end
  end

  defp resolve_si_prefix(unit) do
    {:error, "No known SI prefix for unit #{unit}"}
  end

end