defmodule Cldr.Unit.Parser do
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

  @power_units [{"square", 2}, {"cubic", 3}]

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

  def parse_unit(unit_string) do
    unit_string
    |> String.replace("-", "_")
    |> String.split(@per, parts: 2)
    |> Enum.map(&parse_subunit/1)
  rescue e in [Cldr.UnknownUnitError, Cldr.Unit.UnknownBaseUnitError] ->
    {:error, {e.__struct__, e.message}}
  end

  defp parse_subunit(unit_string) do
    unit_string
    |> String.replace(@per, "")
    |> split_into_units
    |> expand_power_instances()
    |> combine_power_instances()
    |> Enum.map(&resolve_base_unit/1)
    |> Enum.sort(&unit_sorter/2)
  end

  @unit_strings Conversions.conversions()
  |> Map.keys
  |> Cldr.Map.stringify_values
  |> Enum.sort(fn a, b -> String.length(a) > String.length(b) end)

  # in order to tokenize a unit string we need to split
  # at the boundaries of known units - after we strip
  # any SI prefixes and any power (square, cubic) prefixes.
  #
  # The process is:
  #
  # 1. Ignore "square" and "cubic" prefixes, they
  #    are just passed through for later use
  #
  # 2. For each known unit, defined as a key on
  #    the map returned by `Cldr.Unit.Conversions.conversions/0`,
  #    sorted in descending order of length so we match
  #    longest first, generate a function matching the head
  #    of the string. This will match any unit except those
  #    with an SI prefix
  #
  # 3. Match the beginning of the string to an SI prefix and
  #    then match the remaining string. Reassemble the prefix
  #    to the base unit before returning.

  defp split_into_units("") do
    []
  end

  for {prefix, _power} <- @power_units do
    defp split_into_units(<< unquote(prefix) <> "_", rest :: binary >>) do
      [unquote(prefix) | split_into_units(rest)]
    end
  end

  for unit <- @unit_strings do
    defp split_into_units(<< unquote(unit), rest :: binary >>) do
      [unquote(unit) | split_into_units(String.trim_leading(rest, "_"))]
    end
  end

  for {prefix, _scale} <- @si_factors do
    defp split_into_units(<< unquote(prefix), rest :: binary >>) do
      [head | rest] = split_into_units(String.trim_leading(rest, "_"))
      [unquote(prefix) <> head | rest]
    end
  end

  defp split_into_units(other) do
    raise Cldr.UnknownUnitError, "Unknown unit was detected at #{inspect other}"
  end

  # In order to correctly identify the units with their
  # correct power (square or cubic) we have to expand
  # any power units that are already powers so that
  # later on we can group them with any single units of
  # the same name.

  defp expand_power_instances([]) do
    []
  end

  defp expand_power_instances(["square", unit | rest]) do
    [unit, unit | expand_power_instances(rest)]
  end

  defp expand_power_instances(["cubic", unit | rest]) do
    [unit, unit, unit | expand_power_instances(rest)]
  end

  defp expand_power_instances([unit | rest]) do
    [unit | expand_power_instances(rest)]
  end

  # Reassemble the power units by grouping and
  # combining with a square or cubic prefix
  # if there is more than one instance

  defp combine_power_instances(units) do
    units
    |> Enum.group_by(&(&1))
    |> Enum.map(fn
      {k, v} when length(v) == 1 -> k
      {k, v} when length(v) == 2 -> "square_#{k}"
      {k, v} when length(v) == 3 -> "cubic_#{k}"
    end)
  end

  # For each unit, resolve its base unit. we First
  # ignore any power prefix or any SI unit prefix and then
  # look up the base unit. Afterwards we take a note of any
  # scale or power that need to be abplied to the base unit
  # to reflect the power or SI unit.

  for {prefix, power} <- @power_units do
    defp resolve_base_unit(<< unquote(prefix) <> "_", subunit :: binary >> = unit) do
      with {_, base_unit, scale, _power} <- resolve_base_unit(subunit) do
        {unit, base_unit, scale, unquote(power)}
      else
        {:error, {exception, reason}} -> raise(exception, reason)
      end
    end
  end

  for {prefix, scale} <- @si_factors do
    defp resolve_base_unit(<< unquote(prefix), base_unit :: binary >> = unit) do
      with {:ok, base_unit} <- Unit.base_unit(base_unit) do
        scale = maybe_adjust_mass_scale(base_unit, unquote(Macro.escape(scale)))
        {unit, base_unit, scale, 0}
      else
        {:error, {exception, reason}} -> raise(exception, reason)
      end
    end
  end

  defp resolve_base_unit(unit) when is_binary(unit) do
    with {:ok, base_unit} <- Unit.base_unit(unit) do
      scale = maybe_adjust_mass_scale(base_unit, 1)
      {unit, base_unit, scale, 0}
    else
      {:error, {exception, reason}} -> raise(exception, reason)
    end
  end

  # The SI base unit of mass is a kilogram. But it also has an SI
  # prefix. So in order to get the scale right we need to divide by
  # the scale of the kilogram, which is 1_000.

  defp maybe_adjust_mass_scale(:kilogram, scale) do
    Ratio.div(scale, 1000)
  end

  defp maybe_adjust_mass_scale(_, scale) do
    scale
  end

  # Units are sorted in the order present in the base units
  # list. Within any base unit, SI prefixes are sorted by the
  # largest first. Therefore the sort keys may be an integer
  # for a simple unit with no prefix or a tuple with the
  # integer ranking for the unit and an integer ranking for
  # the SI prefix.

  defp unit_sorter(a, b) do
    case {unit_sort_key(a), unit_sort_key(b)} do
      {{key, order_1}, {key, order_2}} -> order_1 < order_2
      {{key_1, _order_1}, key_2} when is_integer(key_2) -> key_1 < key_2
      {key_1, {key_2, _order_2}} when is_integer(key_1) -> key_1 < key_2
      {key_1, key_2} when is_integer(key_1) and is_integer(key_2) -> key_1 < key_2
      _other -> true
    end
  end

  for {prefix, _power} <- @power_units do
    defp unit_sort_key({<< unquote(prefix) <> "_", unit :: binary >>, base_unit, scale}) do
      unit_sort_key({unit, base_unit, scale})
    end
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

  defp base_units_in_order do
    @base_units_in_order
  end

  @doc false
  def unconvertible_units do
    units = Cldr.Unit.known_units |> Enum.map(&Cldr.Unit.Alias.alias/1)

    for unit <- units do
      parse_unit(to_string(unit))
    end
    |> Enum.reject(&is_list/1)
  end

  @doc false
  def unparseable_units do
    for {unit, conversion} <- Cldr.Unit.Conversions.conversions() do
      [Atom.to_string(unit), Atom.to_string(conversion.base_unit)]
    end
    |> List.flatten
    |> Enum.map(fn x -> case parse_unit(x) do
        thing when is_list(thing) -> nil
        {:error, other} -> other
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

end