defmodule Cldr.Unit.Conversion do
  @moduledoc """
  Unit conversion functions for the units defined
  in `CLDR`.

  """

  @enforce_keys [:base_unit]
  defstruct factor: nil,
            offset: nil,
            base_unit: nil,
            special: nil

  @type factor :: integer | float
  @type offset :: integer | float

  @type t :: %{
          factor: factor(),
          base_unit: [atom(), ...],
          offset: offset(),
          special: atom() | nil
        }

  alias Cldr.Unit
  alias Cldr.Unit.BaseUnit
  alias Cldr.Unit.Prefix

  import Kernel, except: [div: 2]

  @decimal_1 Decimal.new(1)

  @doc """
  Returns the conversion that calculates
  the base unit into another unit or
  and error.

  """
  def conversion_for(unit_1, unit_2) do
    with {:ok, base_unit_1, _conversion_1} <- base_unit_and_conversion(unit_1),
         {:ok, base_unit_2, conversion_2} <- base_unit_and_conversion(unit_2) do
      conversion_for(unit_1, unit_2, base_unit_1, base_unit_2, conversion_2)
    end
  end

  # Base units match so are compatible
  defp conversion_for(_unit_1, _unit_2, base_unit, base_unit, conversion_2) do
    {:ok, conversion_2, :forward}
  end

  # Its invertable so see if that's convertible. Note that
  # there is no difference in the conversion for an inverted
  # conversion. Its only a hint so that in convert_from_base/2
  # we know to divide, not multiple the value.

  defp conversion_for(unit_1, unit_2, base_unit_1, _base_unit_2, {numerator_2, denominator_2}) do
    inverted_conversion = {denominator_2, numerator_2}

    with {:ok, base_unit_2} <- BaseUnit.canonical_base_unit(inverted_conversion) do
      if base_unit_1 == base_unit_2 do
        {:ok, {numerator_2, denominator_2}, :inverted}
      else
        {:error, Unit.incompatible_units_error(unit_1, unit_2)}
      end
    end
  end

  # If the base units don't match, try comparing the unit categories
  # instead.

  defp conversion_for(unit_1, unit_2, _base_unit_1, _base_unit_2, conversion_2) do
    with {:ok, category_1} <- Cldr.Unit.unit_category(unit_1),
         {:ok, category_2} <- Cldr.Unit.unit_category(unit_2) do
      if category_1 == category_2 do
        {:ok, conversion_2, :forward}
      else
        {:error, Unit.incompatible_units_error(unit_1, unit_2)}
      end
    end
  end

  @doc """
  Returns the base unit and the base unit
  conversionfor a given unit.

  ## Argument

  * `unit` is either a `t:Cldr.Unit`, an `atom` or
    a `t:String`

  ## Returns

  * `{:ok, base_unit, conversion}` or

  * `{:error, {exception, reason}}`

  ## Example

      iex> Cldr.Unit.Conversion.base_unit_and_conversion :square_kilometer
      {:ok, :square_meter,
       [
         {"square_kilometer",
          %Cldr.Unit.Conversion{
            factor: 1000000,
            offset: 0,
            base_unit: [:square, :meter]
          }}
       ]}

      iex> Cldr.Unit.Conversion.base_unit_and_conversion :square_table
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"table\\""}}

  """

  def base_unit_and_conversion(%Unit{base_conversion: conversion}) do
    {:ok, base_unit} = BaseUnit.canonical_base_unit(conversion)
    {:ok, base_unit, conversion}
  end

  def base_unit_and_conversion(unit_name) when is_atom(unit_name) or is_binary(unit_name) do
    with {:ok, _unit, conversion} <- Cldr.Unit.validate_unit(unit_name),
         {:ok, base_unit} <- BaseUnit.canonical_base_unit(conversion) do
      {:ok, base_unit, conversion}
    end
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...)

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `to_unit` is any unit name returned by `Cldr.Unit.known_units/0`.

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :foot
      {:ok, Cldr.Unit.new!(:foot, 5280)}

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :gallon
      {:error, {Cldr.Unit.IncompatibleUnitsError,
        "Operations can only be performed between units with the same base unit. Received :mile and :gallon"}}

  """
  @spec convert(Unit.t(), Unit.unit()) :: {:ok, Unit.t()} | {:error, {module(), String.t()}}

  def convert(%Unit{value: value, base_conversion: from_conversion} = unit, to_unit) do
    with {:ok, to_conversion, maybe_inverted} <- conversion_for(unit, to_unit) do
      converted_value = convert(value, from_conversion, to_conversion, maybe_inverted)
      Unit.new(to_unit, converted_value, usage: unit.usage, format_options: unit.format_options)
    end
  end

  defp convert(value, from, to, maybe_inverted) when is_number(value) or is_map(value) do
    value
    |> convert_to_base(from)
    |> maybe_invert_value(maybe_inverted)
    |> convert_from_base(to)
  end

  def maybe_invert_value(value, :inverted) do
    div(1, value)
  end

  def maybe_invert_value(value, _) do
    value
  end

  # Special handling for Beaufort
  defp convert_to_base(value, {_, %__MODULE__{special: :beaufort}}) do
    mult(0.836, pow(value, 1.5))
  end

  # All conversions are ultimately a list of
  # 2-tuples of the unit and conversion struct
  defp convert_to_base(value, {_, %__MODULE__{} = from}) do
    %{factor: from_factor, offset: from_offset} = from

    from_factor
    |> mult(value)
    |> add(from_offset)
  end

  # A per module is a 2-tuple of the numerator and
  # denominator. Both are lists of conversion tuples.
  defp convert_to_base(value, {numerator, denominator}) do
    convert_to_base(@decimal_1, numerator)
    |> div(convert_to_base(@decimal_1, denominator))
    |> mult(value)
  end

  # We recurse over the list of conversions
  # and accumulate the value as we go
  defp convert_to_base(value, []) do
    value
  end

  defp convert_to_base(value, [first | rest]) do
    convert_to_base(value, first) |> convert_to_base(rest)
  end

  # But if we meet a shape of data we don't
  # understand then its a raisable error
  defp convert_to_base(_value, conversion) do
    raise ArgumentError, "Conversion not recognised: #{inspect(conversion)}"
  end

  # Special handling for Beaufort
  defp convert_from_base(value, {_, %__MODULE__{special: :beaufort}}) do
    # B = (S/0.836)^(2/3)
    divided = div(value, 0.836)
    pow(divided, 2 / 3)
    |> Cldr.Math.round(2)
  end

  defp convert_from_base(value, {_, %__MODULE__{} = to}) do
    %{factor: to_factor, offset: to_offset} = to

    value
    |> sub(to_offset)
    |> div(to_factor)
  end

  defp convert_from_base(value, {numerator, denominator}) do
    convert_from_base(@decimal_1, numerator)
    |> div(convert_from_base(@decimal_1, denominator))
    |> mult(value)
  end

  defp convert_from_base(value, []) do
    value
  end

  defp convert_from_base(value, [first | rest]) do
    convert_from_base(value, first) |> convert_from_base(rest)
  end

  defp convert_from_base(_value, conversion) do
    raise ArgumentError, "Conversion not recognised: #{inspect(conversion)}"
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...) and raises
  on a unit type mismatch.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `to_unit` is any unit name returned by `Cldr.Unit.known_units/0`.

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Conversion.convert!(Cldr.Unit.new!(:celsius, 0), :fahrenheit)
      ...> |> Cldr.Unit.round
      Cldr.Unit.new!(:fahrenheit, 32)

      iex> Cldr.Unit.Conversion.convert!(Cldr.Unit.new!(:fahrenheit, 32), :celsius)
      ...> |> Cldr.Unit.round
      Cldr.Unit.new!(:celsius, 0)

      Cldr.Unit.Conversion.convert Cldr.Unit.new!(:mile, 1), :gallon
      ** (Cldr.Unit.IncompatibleUnitsError) Operations can only be performed between units of the same type. Received :mile and :gallon

  """
  @spec convert!(Unit.t(), Unit.unit()) :: Unit.t() | no_return()

  def convert!(%Unit{} = unit, to_unit) do
    case convert(unit, to_unit) do
      {:error, {exception, reason}} -> raise exception, reason
      {:ok, unit} -> unit
    end
  end

  @doc """
  Convert a unit into its base unit.

  For example, the base unit for `length`
  is `meter`. The base unit is an
  intermediary unit used in all
  conversions.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Returns

  * `unit` converted to its base unit as a `t:Unit.t()` or

  * `{;error, {exception, reason}}` as an error

  ## Example

      iex> unit = Cldr.Unit.new!(:kilometer, 10)
      iex> Cldr.Unit.Conversion.convert_to_base_unit unit
      {:ok, Cldr.Unit.new!(:meter, 10000)}

  """
  def convert_to_base_unit(%Unit{} = unit) do
    with {:ok, base_unit} <- Unit.base_unit(unit) do
      convert(unit, base_unit)
    end
  end

  def convert_to_base_unit(unit) when is_atom(unit) do
    unit
    |> Unit.new!("1.0")
    |> convert_to_base_unit()
  end

  def convert_to_base_unit([unit | _rest]) when is_atom(unit) do
    convert_to_base_unit(unit)
  end

  @doc """
  Convert a unit into its base unit and
  raises on error.

  For example, the base unit for `length`
  is `meter`. The base unit is an
  intermediary unit used in all
  conversions.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  ## Returns

  * `unit` converted to its base unit as a `t:Unit.t()` or

  * raises an exception

  ## Example

      iex> unit = Cldr.Unit.new!(:kilometer, 10)
      iex> Cldr.Unit.Conversion.convert_to_base_unit! unit
      Cldr.Unit.new!(:meter, 10000)

  """
  def convert_to_base_unit!(%Unit{} = unit) do
    case convert_to_base_unit(unit) do
      {:error, {exception, reason}} -> raise exception, reason
      {:ok, unit} -> unit
    end
  end

  # Math Helpers

  # Combines two conversions which are expected to
  # be the same base unit of potentially different
  # powers (exponents)

  @doc false
  def product(conversion_1, conversion_2) do
    {base_name_1, power_1} = name_and_power(conversion_1)
    {base_name_2, power_2} = name_and_power(conversion_2)

    new_power =
      power_1 + power_2

    new_factor =
      Cldr.Math.mult(conversion_1.factor, conversion_2.factor)

    new_base_unit =
      base_unit(base_name_1, base_name_2, new_power)

    %{conversion_1 | factor: new_factor, base_unit: new_base_unit}
  end

  # Extract the power from a base unit. Some translatable
  # units have compound names (like :square_meter) so to
  # preserve translatability we don't deconstruct them.

  @doc false
  def name_and_power([power, unit_name]) when is_binary(unit_name) do
    power = Map.fetch!(Prefix.power_units(), power)
    {base_name, base_power} = extract_power(unit_name)
    {base_name, base_power + power}
  end

  def name_and_power([power, unit_name]) when is_atom(unit_name) do
    {name, intrinsic_power} = extract_power(unit_name)
    power = Map.fetch!(Prefix.power_units(), power)
    {name, power + intrinsic_power}
  end

  def name_and_power([unit]) do
    extract_power(unit)
  end

  def name_and_power(unit) when is_binary(unit) or is_atom(unit) do
    extract_power(unit)
  end

  def name_and_power(%{base_unit: [unit]}) do
    name_and_power([unit])
  end

  def name_and_power(%{base_unit: [power, unit_name]}) do
    name_and_power([power, unit_name])
  end

  # Extract the power from a unit name

  @doc false
  def extract_power(unit_name) when is_atom(unit_name) do
    unit_name
    |> to_string()
    |> extract_power
  end

  for {power_name, power} <- Prefix.power_units() do
    power_name = "#{power_name}_"

    def extract_power(unquote(power_name) <> base_name) do
      {Unit.maybe_translatable_unit(base_name), unquote(power)}
    end
  end

  def extract_power(base_name), do: {Unit.maybe_translatable_unit(base_name), 1}

  # Are these the same base units - excluding power prefixes
  @doc false
  def same_base_unit(%{base_unit: [_power_1, unit]}, %{base_unit: [_power_2, unit]}), do: unit
  def same_base_unit(%{base_unit: [unit]}, %{base_unit: [_power, unit]}), do: unit
  def same_base_unit(%{base_unit: [_power, unit]}, %{base_unit: [unit]}), do: unit
  def same_base_unit(%{base_unit: [unit]}, %{base_unit: [unit]}), do: unit
  def same_base_unit(conversion_1, conversion_2) do
    {base_name_1, _power_1} = name_and_power(conversion_1)
    {base_name_2, _power_2} = name_and_power(conversion_2)

    if base_name_1 == base_name_2 do
      Unit.maybe_translatable_unit(base_name_1)
    else
      nil
    end
  end

  # Creates a unit name from a unit and a
  # power.

  @doc false
  def base_unit(unit_name, power) do
    base_unit(unit_name, unit_name, power)
  end

  @doc false
  def base_unit(unit_name, unit_name, 1) do
    [unit_name]
  end

  def base_unit(unit_name, unit_name, power) do
    case reduce_power_to_translatable_unit(unit_name, power) do
      {unit_name, 1} ->
        [unit_name]

      {unit_name, power} ->
        prefix = Prefix.prefix_from_power(power)
        [prefix, Unit.maybe_translatable_unit(unit_name)]
    end
  end

  # If we end up with something like [:pow4, :meter] then
  # what we really wnat is [:square, :cubic_meter] because
  # we want to preserve the maximal translatable name if possible.

  defp reduce_power_to_translatable_unit(unit_name, power) do
    Enum.reduce_while(power..2//-1, {unit_name, power}, fn test_power, acc ->
      test_unit = Prefix.add_prefix(unit_name, test_power)

      if test_unit in Prefix.units_with_power_prefixes() do
        {:halt, {Unit.maybe_translatable_unit(test_unit), max(power - test_power - 1, 1)}}
      else
        {:cont, acc}
      end
    end)
  end

  @doc false
  def add(v1, v2), do: Cldr.Math.add(v1, v2) |> Cldr.Math.maybe_integer()

  @doc false
  def sub(v1, v2), do: Cldr.Math.sub(v1, v2) |> Cldr.Math.maybe_integer()

  @doc false
  def mult(v1, v2), do: Cldr.Math.mult(v1, v2) |> Cldr.Math.maybe_integer()

  @doc false
  def div(v1, v2), do: Cldr.Math.div(v1, v2) |> Cldr.Math.maybe_integer()

  @doc false
  def pow(v1, v2), do: Cldr.Math.pow(v1, v2) |> Cldr.Math.maybe_integer()
end
