defmodule Cldr.Unit.Math do
  @moduledoc false

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

  @spec add(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def add(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: value_2}) do
    %{unit_1 | value: Conversion.add(value_1, value_2)}
    |> maybe_adjust_value_type(value_1, value_2)
  end

  def add(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      add(unit_1, Conversion.convert!(unit_2, unit_category_1))
      |> maybe_adjust_value_type(unit_1.value, unit_2.value)
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @spec add!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

  def add!(unit_1, unit_2) do
    case add(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @spec sub(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def sub(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: value_2}) do
    %{unit_1 | value: Conversion.sub(value_1, value_2)}
    |> maybe_adjust_value_type(value_1, value_2)
  end

  def sub(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      sub(unit_1, Conversion.convert!(unit_2, unit_category_1))
      |> maybe_adjust_value_type(unit_1.value, unit_2.value)
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @spec sub!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

  def sub!(unit_1, unit_2) do
    case sub(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @spec mult(Unit.t(), Unit.t()) ::
      Unit.t() | {:error, {module(), String.t()}}

  def mult(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2}) do
    Unit.new!(unit, Conversion.mult(value_1, value_2))
    |> maybe_adjust_value_type(value_1, value_2)
  end

  def mult(%Unit{value: value} = unit, number) when is_number(number) do
    %{unit | value: Conversion.mult(value, number)}
    |> maybe_adjust_value_type(unit.value, number)
  end

  def mult(%Unit{value: value} = unit, %Decimal{} = number) do
    %{unit | value: Conversion.mult(value, number)}
    |> maybe_adjust_value_type(unit.value, number)
  end

  def mult(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      {:ok, converted} = Conversion.convert(unit_2, unit_category_1)
      mult(unit_1, converted)
      |> maybe_adjust_value_type(unit_1.value, unit_2.value)
    else
      product(unit_1, unit_2)
    end
  end

  @spec mult!(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def mult!(unit_1, unit_2) do
    mult(unit_1, unit_2)
  end

  @spec div(Unit.t(), Unit.t()) ::
      Unit.t() | {:error, {module(), String.t()}}

  def div(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2}) do
    Unit.new!(unit, Conversion.div(value_1, value_2))
    |> maybe_adjust_value_type(value_1, value_2)
  end

  def div(%Unit{value: value} = unit, number) when is_number(number) do
    %{unit | value: Conversion.div(value, number)}
    |> maybe_adjust_value_type(unit.value, number)
  end

  def div(%Unit{value: value} = unit, %Decimal{} = number) do
    %{unit | value: Conversion.div(value, number)}
    |> maybe_adjust_value_type(unit.value, number)
  end

  def div(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      div(unit_1, Conversion.convert!(unit_2, unit_category_1))
      |> maybe_adjust_value_type(unit_1.value, unit_2.value)
    else
      product(unit_1, invert(unit_2))
    end
  end

  @spec div!(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def div!(unit_1, unit_2) do
    div(unit_1, unit_2)
  end

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

  defp maybe_adjust_value_type(unit, v1, v2) when is_integer(v1) and is_integer(v2) do
    %{unit | value: Cldr.Math.maybe_integer(unit.value)}
  end

  defp maybe_adjust_value_type(unit, %Decimal{} = _v1, _v2) do
    %{unit | value: Decimal.new(unit.value)}
  end

  defp maybe_adjust_value_type(unit, _v1, %Decimal{} = _v2) do
    %{unit | value: Decimal.new(unit.value)}
  end

  defp maybe_adjust_value_type(unit, _v1, _v2) do
    unit
  end
end
