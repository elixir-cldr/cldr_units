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

  def add_derived_conversions(conversions, [unit | _rest] = units) when is_atom(unit) do
    string_units = Cldr.Map.stringify_values(units)
    string_conversions = Cldr.Map.stringify_keys(conversions, level: 1)
    add_derived_conversions(string_conversions, string_units)
  end

  def add_derived_conversions(conversions, units) do
    updated_conversions =
      conversions
      |> si_factor_conversions(units)
      |> Map.merge(conversions)

    compound_unit_conversions(updated_conversions, units)
    |> Map.merge(updated_conversions)
    |> Cldr.Map.atomize_keys(level: 1)
  end

  defp si_factor_conversions(conversions, units) do
    for unit <- units, not Map.has_key?(conversions, unit) do
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
    |> Enum.reject(&is_nil/1)
    |> Map.new
  end

  def compound_unit_conversions(conversions, units) do
    for unit <- units, not Map.has_key?(conversions, unit) do
      conversion =
        unit
        |> String.split("_per_")
        |> Enum.map(&Map.get(conversions, &1))
        |> craft_compound_conversion

      {unit, conversion}
    end
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Map.new
  end

  def craft_compound_conversion([nil]), do: nil
  def craft_compound_conversion([nil, _]), do: nil
  def craft_compound_conversion([_, nil]), do: nil

  def craft_compound_conversion([c1, c2]) do
    c1
    |> Map.put(:base_unit, String.to_atom("#{c1.base_unit}_per_#{c2.base_unit}"))
    |> Map.put(:factor, Ratio.div(c1.factor, c2.factor))
  end

  def unconvertible_units do
    for unit <- Cldr.Unit.known_units, not Map.has_key?(Cldr.Unit.Conversions.conversions(), unit) do
      IO.puts "Unit #{unit} is not convertible"
    end
    nil
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