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

  def parse_unit(unit_string, _conversions \\ Conversions.conversions()) do
    unit_string
    |> String.downcase()
    |> String.replace("-", "_")
    |> String.split(@per, parts: 2)
    |> Enum.map(&parse_subunit/1)
  rescue e in [Cldr.Unit.UnknownBaseUnitError, Cldr.UnknownUnitError] ->
    {:error, {e.__struct__, e.message}}
  end

  defp parse_subunit(unit_string) do
    unit_string
    |> String.replace(@per, "")
    |> String.split("_")
    |> expand_power_units()
    |> combine_power_instances()
    |> Enum.map(&resolve_base_unit/1)
    |> Enum.sort(&unit_sorter/2)
  end

  defp resolve_base_unit(<< "square_", subunit :: binary >> = unit) do
    with {_, base_unit, scale} <- resolve_base_unit(subunit) do
      {unit, base_unit, Keyword.merge(scale, power: 2)}
    else
      {:error, {exception, reason}} -> raise(exception, reason)
    end
  end

  defp resolve_base_unit(<< "cubic_", subunit :: binary >> = unit) do
    with {_, base_unit, scale} <- resolve_base_unit(subunit) do
      {unit, base_unit, Keyword.merge(scale, power: 3)}
    else
      {:error, {exception, reason}} -> raise(exception, reason)
    end
  end

  for {prefix, scale} <- @si_factors do
    defp resolve_base_unit(<< unquote(prefix), base_unit :: binary >> = unit) do
      with {:ok, base_unit} <- Unit.base_unit(base_unit) do
        {unit, base_unit, factor: unquote(Macro.escape(scale))}
      else
        {:error, {exception, reason}} -> raise(exception, reason)
      end
    end
  end

  defp resolve_base_unit(unit) when is_binary(unit) do
    with {:ok, base_unit} <- Unit.base_unit(unit) do
      {unit, base_unit, factor: 1}
    else
      {:error, {exception, reason}} -> raise(exception, reason)
    end
  end

  # Expand units like `[square, kilometer]` into
  # `[kilometer, kilometer]` since there may be a
  # compination of power units and non power units
  # that we will consolidate in `combine_power_instances/1`
  # later on

  defp expand_power_units([]) do
    []
  end

  defp expand_power_units(["square", unit | rest]) do
    [unit, unit | expand_power_units(rest)]
  end

  defp expand_power_units(["cubic", unit | rest]) do
    [unit, unit, unit | expand_power_units(rest)]
  end

  defp expand_power_units([unit | rest]) do
    [unit | expand_power_units(rest)]
  end

  defp unit_sorter(a, b) do
    case {unit_sort_key(a), unit_sort_key(b)} do
      {{key, order_1}, {key, order_2}} -> order_1 < order_2
      {{key_1, _order_1}, key_2} when is_integer(key_2) -> key_1 < key_2
      {key_1, {key_2, _order_2}} when is_integer(key_1) -> key_1 < key_2
      {key_1, key_2} when is_integer(key_1) and is_integer(key_2) -> key_1 < key_2
      _other -> true
    end
  end

  defp combine_power_instances(units) do
    units
    |> Enum.group_by(&(&1))
    |> Enum.map(fn
      {k, v} when length(v) == 1 -> k
      {k, v} when length(v) == 2 -> "square_#{k}"
      {k, v} when length(v) == 3 -> "cubic_#{k}"
    end)
  end

  defp unit_sort_key({<< "square_", unit :: binary >>, base_unit, scale}) do
    unit_sort_key({unit, base_unit, scale})
  end

  defp unit_sort_key({<< "cubic_", unit :: binary >>, base_unit, scale}) do
    unit_sort_key({unit, base_unit, scale})
  end

  # Take the map of SI factors and transform
  # it to map of sort keys with the larger prefixes
  # sorting before the smaller prefixes.

  @si_order @si_factors
  |> Enum.map(fn
    {k, v} when is_integer(v) -> {k, v *  1.0}
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
    defp unit_sort_key({<< unquote(prefix), unit :: binary >>, base_unit, scale}) do
      {unit_sort_key({unit, base_unit, scale}), unquote(order)}
    end
  end

  defp unit_sort_key({_unit, base_unit, _}) do
    Map.fetch!(base_units_in_order(), base_unit)
  end

  @base_units_in_order Cldr.Config.units
  |> Map.get(:base_units)
  |> Enum.map(&(elem(&1, 1)))
  |> Enum.with_index
  |> Map.new

  # Maintains the list tof base units in the order
  # defined by CLDR. We use this order when sorting
  # subunits within a compound unit
  defp base_units_in_order do
    @base_units_in_order
  end

  def check do
    for {unit, conversion} <- Cldr.Unit.Conversions.conversions() do
      [Atom.to_string(unit), Atom.to_string(conversion.base_unit)]
    end
    |> List.flatten
    |> Enum.map(fn x -> case parse_unit(x) do
        thing when is_list(thing) -> thing
        {:error, _other} -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end