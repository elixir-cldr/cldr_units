defmodule Cldr.Unit.Math do
  @moduledoc """
  Simple arithmetic functions for the `t.Cldr.Unit.t/0` type.

  """
  alias Cldr.Unit
  alias Cldr.Unit.Parser
  alias Cldr.Unit.Conversion

  import Kernel, except: [div: 2, round: 1, trunc: 1]
  import Unit, only: [incompatible_units_error: 2]

  @type rounding_mode :: :down | :up | :ceiling | :floor | :half_even | :half_up | :half_down

  @doc false
  defguard is_per_unit(base_conversion)
           when is_tuple(base_conversion) and
                  tuple_size(base_conversion) == 2

  @doc false
  defguard is_simple_unit(base_conversion) when is_list(base_conversion)

  @doc """
  Adds two compatible `t:Cldr.Unit.t/0` types

  ## Arguments

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`.

  ## Returns

  * A `t:Cldr.Unit.t/0` of the same type as `unit_1` with a value
    that is the sum of `unit_1` and the potentially converted
    `unit_2`, or

  * `{:error, {IncompatibleUnitError, message}}`.

  ## Examples

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:foot, 1)
      Cldr.Unit.new!(:foot, 2)

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:mile, 1)
      Cldr.Unit.new!(:foot, 5281)

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:gallon, 1)
      {:error, {Cldr.Unit.IncompatibleUnitsError,
        "Operations can only be performed between units with the same base unit. Received :foot and :gallon"}}

  """
  @spec add(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def add(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: value_2}) do
    %{unit_1 | value: Conversion.add(value_1, value_2)}
  end

  def add(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      add(unit_1, Conversion.convert!(unit_2, unit_category_1))
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @doc """
  Adds two compatible `t:Cldr.Unit.t/0` types
  and raises on error.

  ## Arguments

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`.

  ## Returns

  * A `t:Cldr.Unit.t/0` of the same type as `unit_1` with a value
    that is the sum of `unit_1` and the potentially converted
    `unit_2` or

  * Raises an exception.

  """
  @spec add!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

  def add!(unit_1, unit_2) do
    case add(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc """
  Subtracts two compatible `t:Cldr.Unit.t/0` types.

  ## Arguments

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`.

  ## Returns

  * A `t:Cldr.Unit.t/0` of the same type as `unit_1` with a value
    that is the difference between `unit_1` and the potentially
    converted `unit_2`, or

  * `{:error, {IncompatibleUnitError, message}}`.

  ## Examples

      iex> Cldr.Unit.sub Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      Cldr.Unit.new!(:kilogram, "4.54640763")

      iex> Cldr.Unit.sub Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      Cldr.Unit.new!(:pint, "2.886623581134812676960800627")

      iex> Cldr.Unit.sub Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      Cldr.Unit.new!(:pint, 4)

  """
  @spec sub(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def sub(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: value_2}) do
    %{unit_1 | value: Conversion.sub(value_1, value_2)}
  end

  def sub(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      sub(unit_1, Conversion.convert!(unit_2, unit_category_1))
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @doc """
  Subtracts two compatible `t:Cldr.Unit.t/0` types
  and raises on error.

  ## Arguments

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`.

  ## Returns

  * A `t:Cldr.Unit.t/0` of the same type as `unit_1` with a value
    that is the difference between `unit_1` and the potentially
    converted `unit_2` or

  * Raises an exception.

  """
  @spec sub!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

  def sub!(unit_1, unit_2) do
    case sub(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc """
  Multiplies any two `t:Cldr.Unit.t/0` types or a t:Cldr.Unit.t/0`
  and a scalar.

  ## Arguments

  * `unit_1` is a unit
    returned by `Cldr.Unit.new/2`.

  * `unit_2` is a unit
    returned by `Cldr.Unit.new/2` or
    a number or Decimal.

  ## Returns

  * A `t:Cldr.Unit.t/0` of a type that is the product
    of `unit_1` and `unit_2` with a value
    that is the product of `unit_1` and `unit_2`'s
    values.

  ## Examples

      iex> Cldr.Unit.mult Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      Cldr.Unit.new!(:kilogram, "2.26796185")

      iex> Cldr.Unit.mult Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      Cldr.Unit.new!(:pint, "10.56688209432593661519599687")

      iex> Cldr.Unit.mult Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      Cldr.Unit.new!(:pint, 5)

  """
  @spec mult(Unit.t(), Unit.t()) :: Unit.t()

  def mult(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2}) do
    Unit.new!(unit, Conversion.mult(value_1, value_2))
  end

  def mult(%Unit{value: value} = unit, number) when is_number(number) do
    %{unit | value: Conversion.mult(value, number)}
  end

  def mult(%Unit{value: value} = unit, %Decimal{} = number) do
    %{unit | value: Conversion.mult(value, number)}
  end

  def mult(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      {:ok, converted} = Conversion.convert(unit_2, unit_category_1)
      mult(unit_1, converted)
    else
      product(unit_1, unit_2)
    end
  end


  @doc """
  Multiplies two compatible `t:Cldr.Unit.t/0` types
  and raises on error.

  ## Options

  * `unit_1` is a unit
    returned by `Cldr.Unit.new/2`.

  * `unit_2` is a unit
    returned by `Cldr.Unit.new/2` or
    a number or Decimal.

  ## Returns

  * A `t:Cldr.Unit.t/0` of the same type as `unit_1` with a value
    that is the product of `unit_1` and the potentially
    converted `unit_2` or

  * Raises an exception.

  """
  @spec mult!(Unit.t(), Unit.t()) :: Unit.t()

  def mult!(unit_1, unit_2) do
    mult(unit_1, unit_2)
  end

  @doc """
  Divides any `t:Cldr.Unit.t/0` type into another or a
  number into a `t:Cldr.Unit.t/0`.

  ## Options

  * `unit_1` is a unit
    returned by `Cldr.Unit.new/2`.

  * `unit_2` is a unit
    returned by `Cldr.Unit.new/2` or
    a number or Decimal.

  ## Returns

  * A `t:Cldr.Unit.t/0` of a type that is the dividend
    of `unit_1` and `unit_2` with a value
    that is the dividend of `unit_1` and `unit_2`'s
    values.

  ## Examples

      iex> Cldr.Unit.Math.div Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      Cldr.Unit.new!(:kilogram, "11.02311310924387903614869007")

      iex> Cldr.Unit.Math.div Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      Cldr.Unit.new!(:pint, "2.365882365000000000000000000")

      iex> Cldr.Unit.Math.div Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      Cldr.Unit.new!(:pint, 5)

  """
  @spec div(Unit.t(), Unit.t()) :: Unit.t()

  def div(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2}) do
    Unit.new!(unit, Conversion.div(value_1, value_2))
  end

  def div(%Unit{value: value} = unit, number) when is_number(number) do
    %{unit | value: Conversion.div(value, number)}
  end

  def div(%Unit{value: value} = unit, %Decimal{} = number) do
    %{unit | value: Conversion.div(value, number)}
  end

  def div(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      div(unit_1, Conversion.convert!(unit_2, unit_category_1))
    else
      product(unit_1, invert(unit_2))
    end
  end

  @doc """
  Divides one `t:Cldr.Unit.t/0` type into another.
  Any unit can be divided by another.

  ## Arguments

  * `unit_1` is a unit
    returned by `Cldr.Unit.new/2`.

  * `unit_2` is a unit
    returned by `Cldr.Unit.new/2` or
    a number or Decimal.

  ## Returns

  * A `t:Cldr.Unit.t/0` of the same type as `unit_1` with a value
    that is the dividend of `unit_1` and the potentially
    converted `unit_2` or

  * Raises an exception.

  """
  @spec div!(Unit.t(), Unit.t()) :: Unit.t()

  def div!(unit_1, unit_2) do
    div(unit_1, unit_2)
  end

  @doc """
  Rounds the value of a unit.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `places` is the number of decimal places to round to.
    The default is `0`.

  * `mode` is the rounding mode to be applied.  The default
    is `:half_up`.

  ## Returns

  * A `%Unit{}` of the same type as `unit` with a value
    that is rounded to the specified number of decimal places.

  ## Rounding modes

  Directed roundings:

  * `:down` - Round towards 0 (truncate), eg 10.9 rounds to 10.0

  * `:up` - Round away from 0, eg 10.1 rounds to 11.0. (Non IEEE algorithm)

  * `:ceiling` - Round toward +∞ - Also known as rounding up or ceiling

  * `:floor` - Round toward -∞ - Also known as rounding down or floor

  Round to nearest:

  * `:half_even` - Round to nearest value, but in a tiebreak, round towards the
    nearest value with an even (zero) least significant bit, which occurs 50%
    of the time. This is the default for IEEE binary floating-point and the recommended
    value for decimal.

  * `:half_up` - Round to nearest value, but in a tiebreak, round away from 0.
    This is the default algorithm for Erlang's Kernel.round/2

  * `:half_down` - Round to nearest value, but in a tiebreak, round towards 0
    (Non IEEE algorithm)

  ## Examples

      iex> Cldr.Unit.round Cldr.Unit.new!(:yard, 1031.61), 1
      Cldr.Unit.new!(:yard, "1031.6")

      iex> Cldr.Unit.round Cldr.Unit.new!(:yard, 1031.61), 2
      Cldr.Unit.new!(:yard, "1031.61")

      iex> Cldr.Unit.round Cldr.Unit.new!(:yard, 1031.61), 1, :up
      Cldr.Unit.new!(:yard, "1031.7")

  """
  @spec round(
          unit :: Unit.t() | number() | Decimal.t(),
          places :: non_neg_integer,
          mode :: rounding_mode()
        ) :: Unit.t() | number() | Decimal.t()

  def round(unit, places \\ 0, mode \\ :half_up)

  def round(value, _places, _mode) when is_integer(value) do
    value
  end

  def round(value, places, mode) when is_float(value) do
    Cldr.Math.round(value, places, mode)
    |> Cldr.Math.maybe_integer()
  end

  def round(%Decimal{} = value, places, mode) do
    Decimal.round(value, places, mode)
    |> Cldr.Math.maybe_integer()
  end

  def round(%Unit{value: value} = unit_1, places, mode) do
    rounded_value =
      value
      |> round(places, mode)

    %{unit_1 | value: rounded_value}
  end

  @doc """
  Truncates a unit's value.

  """

  def trunc(%Unit{value: value} = unit) when is_float(value) do
    %{unit | value: Kernel.trunc(value)}
  end

  def trunc(%Unit{value: value} = unit) when is_integer(value) do
    unit
  end

  def trunc(%Unit{value: %Decimal{} = value} = unit) do
    trunc =
      value
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()

    %{unit | value: trunc}
  end

  @doc """
  Compare two units, converting to a common unit
  type if required.

  If conversion is performed, the results are both
  rounded to a single decimal place before
  comparison.

  Returns `:gt`, `:lt`, or `:eq`.

  ## Example

      iex> x = Cldr.Unit.new!(:kilometer, 1)
      iex> y = Cldr.Unit.new!(:meter, 1000)
      iex> Cldr.Unit.Math.compare x, y
      :eq

  """
  @spec compare(unit_1 :: Unit.t(), unit_2 :: Unit.t()) :: :eq | :lt | :gt

  def compare(
        %Unit{unit: unit, value: %Decimal{}} = unit_1,
        %Unit{unit: unit, value: %Decimal{}} = unit_2
      ) do
    Cldr.Decimal.compare(unit_1.value, unit_2.value)
  end

  def compare(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
      when is_number(value_1) and is_number(value_2) do
    cond do
      value_1 == value_2 -> :eq
      value_1 > value_2 -> :gt
      value_1 < value_2 -> :lt
    end
  end

  # def compare(%Unit{unit: unit, value: %Ratio{} = value_1}, %Unit{unit: unit, value: value_2}) do
  #   Ratio.compare(value_1, Ratio.new(value_2))
  # end
  #
  # def compare(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: %Ratio{} = value_2}) do
  #   Ratio.compare(Ratio.new(value_1), value_2)
  # end

  def compare(%Unit{unit: unit, value: %Decimal{} = value_1}, %Unit{unit: unit, value: value_2}) do
    Decimal.compare(value_1, Decimal.new(value_2))
  end

  def compare(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: %Decimal{} = value_2}) do
    Decimal.compare(Decimal.new(value_1), value_2)
  end

  def compare(%Unit{value: %Decimal{}} = unit_1, %Unit{value: %Decimal{}} = unit_2) do
    unit_2 = Unit.Conversion.convert!(unit_2, unit_1.unit)
    compare(unit_1, unit_2)
  end

  def compare(%Unit{} = unit_1, %Unit{} = unit_2) do
    unit_1 =
      unit_1
      |> round(1, :half_even)

    unit_2 =
      unit_2
      |> Unit.Conversion.convert!(unit_1.unit)
      |> round(1, :half_even)

    compare(unit_1, unit_2)
  end

  @deprecated "Please use Cldr.Unit.Math.compare/2"
  def cmp(unit_1, unit_2) do
    compare(unit_1, unit_2)
  end

  ### Helpers

  defp product(%Unit{base_conversion: conv_1} = unit_1, %Unit{base_conversion: conv_2} = unit_2)
       when is_per_unit(conv_1) and is_per_unit(conv_2) do
    {numerator_1, denominator_1} = conv_1
    {numerator_2, denominator_2} = conv_2

    new_numerator = Enum.sort(numerator_1 ++ numerator_2, &Parser.unit_sorter/2)
    new_denominator = Enum.sort(denominator_1 ++ denominator_2, &Parser.unit_sorter/2)

    new_conversion = combine_power_instances({new_numerator, new_denominator})
    new_value = Conversion.mult(unit_1.value, unit_2.value)

    unit_name =
      new_conversion
      |> Parser.canonical_unit_name()
      |> Unit.maybe_translatable_unit()

    %{unit_1 | unit: unit_name, value: new_value, base_conversion: new_conversion}
  end

  defp product(%Unit{base_conversion: conv_1} = unit_1, %Unit{base_conversion: conv_2} = unit_2)
       when is_per_unit(conv_1) and is_simple_unit(conv_2) do
    {numerator_1, denominator_1} = conv_1

    new_numerator = Enum.sort(numerator_1 ++ conv_2, &Parser.unit_sorter/2)
    new_denominator = denominator_1

    new_conversion = combine_power_instances({new_numerator, new_denominator})
    new_value = Conversion.mult(unit_1.value, unit_2.value)

    unit_name =
      new_conversion
      |> Parser.canonical_unit_name()
      |> Unit.maybe_translatable_unit()

    %{unit_1 | unit: unit_name, value: new_value, base_conversion: new_conversion}
  end

  defp product(%Unit{base_conversion: conv_1} = unit_1, %Unit{base_conversion: conv_2} = unit_2)
       when is_simple_unit(conv_1) and is_per_unit(conv_2) do
    {numerator_2, denominator_2} = conv_2

    new_numerator = Enum.sort(conv_1 ++ numerator_2, &Parser.unit_sorter/2)
    new_denominator = denominator_2

    new_conversion = combine_power_instances({new_numerator, new_denominator})
    new_value = Conversion.mult(unit_1.value, unit_2.value)

    unit_name =
      new_conversion
      |> Parser.canonical_unit_name()
      |> Unit.maybe_translatable_unit()

    %{unit_1 | unit: unit_name, value: new_value, base_conversion: new_conversion}
  end

  defp product(%Unit{base_conversion: conv_1} = unit_1, %Unit{base_conversion: conv_2} = unit_2)
       when is_simple_unit(conv_1) and is_simple_unit(conv_2) do
    new_conversion =
      (conv_1 ++ conv_2)
      |> Enum.sort(&Parser.unit_sorter/2)
      |> combine_power_instances()

    new_value = Conversion.mult(unit_1.value, unit_2.value)

    unit_name =
      new_conversion
      |> Parser.canonical_unit_name()
      |> Unit.maybe_translatable_unit()

    %{unit_1 | unit: unit_name, value: new_value, base_conversion: new_conversion}
  end

  # Invert a unit. This is used to convert a division
  # into a multiplication. Its not a valid standalone
  # unit.

  @doc false
  def invert({numerator, denominator}) do
    {denominator, numerator}
  end

  def invert(numerator) do
    Map.put(null_unit(), :base_conversion, {[], numerator.base_conversion})
  end

  @doc false
  def null_unit do
    %Cldr.Unit{unit: nil, value: 1, usage: :default, format_options: [], base_conversion: []}
  end

  # Combine consecutive identical units into square or cubic units.
  # Assumes the units are ordered using `Parser.unit_sorter/2`.

  defp combine_power_instances({numerator, denominator}) do
    {combine_power_instances(numerator), combine_power_instances(denominator)}
  end

  defp combine_power_instances([{name, conversion} = first, first, first | rest]) do
    conversion_factor = Conversion.pow(conversion.factor, 3)
    conversion_base_unit = [:cubic | conversion.base_unit]
    new_conversion = %{conversion | factor: conversion_factor, base_unit: conversion_base_unit}
    new_name = Unit.maybe_translatable_unit("cubic_#{name}")
    combine_power_instances([{new_name, new_conversion} | rest])
  end

  defp combine_power_instances([{name, conversion} = first, first | rest]) do
    conversion_factor = Conversion.mult(conversion.factor, conversion.factor)
    conversion_base_unit = [:square | conversion.base_unit]
    new_conversion = %{conversion | factor: conversion_factor, base_unit: conversion_base_unit}
    new_name = Unit.maybe_translatable_unit("square_#{name}")
    combine_power_instances([{new_name, new_conversion} | rest])
  end

  defp combine_power_instances([first | rest]) do
    [first | combine_power_instances(rest)]
  end

  defp combine_power_instances([]) do
    []
  end

  defp combine_power_instances(other) do
    other
  end
end
