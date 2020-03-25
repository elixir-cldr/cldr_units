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
    "exa"   =>   1_000_000_000_000_000_000,
    "zetta" => 1_000_000_000_000_000_000_000,
    "yotta" => 1_000_000_000_000_000_000_000_000
  }

  def add_derived_conversions(conversions, [unit | _rest] = units) when is_atom(unit) do
    string_units = Cldr.Map.stringify_values(units)
    string_conversions = Cldr.Map.stringify_keys(conversions, level: 1)
    add_derived_conversions(string_conversions, string_units)
  end

  def add_derived_conversions(conversions, units) do
    known_conversions = Map.keys(conversions)

    additional_conversions =
      for unit <- units, unit not in known_conversions do
        with {:ok, _prefix, base_unit, si_factor} <- resolve_si_prefix(unit) do
          if base_unit in known_conversions do
            base_conversion = Map.fetch!(conversions, base_unit)
            new_factor = Ratio.mult(base_conversion.factor, si_factor)
            {unit, %{base_conversion | factor: new_factor}}
          else
            # IO.puts "The unit #{unit} is localisable but has no conversion for the base unit"
            # There is where we need to process compount units to derived a conversion
            nil
          end
        else _other ->
          # IO.puts "The unit #{unit} is localisable, has no conversion and has no SI prefix"
          # We also have to deal with compount units here
          nil
        end
      end
      |> Enum.reject(&is_nil/1)
      |> Map.new

    conversions
    |> Map.merge(additional_conversions)
    |> Cldr.Map.atomize_keys(level: 1)
  end

  for {prefix, factor} <- @si_factors do
    def resolve_si_prefix(<< unquote(prefix), base_unit :: binary >>) do
      {:ok, unquote(prefix), base_unit, unquote(Macro.escape(factor))}
    end
  end

  def resolve_si_prefix(unit) do
    {:error, "No known SI prefix for unit #{unit}"}
  end

  for {prefix, factor} <- @si_factors do
    def si_prefix_factor(unquote(prefix)), do: {:ok, unquote(Macro.escape(factor))}
  end

  def si_prefix_factor(_other), do: {:error, :no_such_factor}
end