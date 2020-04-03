defmodule Cldr.Unit.TestData do

  @conversion_test_data "test/support/data/conversion_test_data.txt"
  def conversion_test_data do
    @conversion_test_data
    |> File.read!
    |> String.replace(~r/#.*\n/, "")
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
  end

  def conversions do
    conversion_test_data()
    |> Enum.map(&parse_test/1)
  end

  @fields [:category, :from, :to, :factor, :result]
  def parse_test(test) do
    test
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> zip(@fields)
    |> Enum.map(&transform/1)
    |> Map.new
  end

  def zip(fields, data) do
    data
    |> Enum.zip(fields)
  end

  def transform({:factor, factor}) do
    factor =
      factor
      |> String.replace(" * x", "")
      |> String.replace(",", "")
      |> String.trim
      |> String.split("/")
      |> resolve_factor

    {:factor, factor}
  rescue ArgumentError ->
    {:factor, factor}
  end

  @float ~r/^([-+]?[0-9]*)\.([0-9]+)([eE][-+]?[0-9]+)?$/
  def transform({:result, result}) do
    result = String.replace(result, ",", "")

    result =
      case Regex.run(@float, result) do
        [float, _integer, fraction] -> {String.to_float(float), String.length(fraction)}
        [float, _integer, fraction, _exp] -> {String.to_float(float), String.length(fraction)}
      end

    {:result, result}
  end

  def transform(other) do
    other
  end

  def resolve_factor([factor]) do
    to_number(factor)
  end

  def resolve_factor([numerator, denominator]) do
    numerator = to_number(numerator)
    denominator = to_number(denominator)
    Ratio.new(numerator, denominator)
  end

  def resolve_factor(other) do
    other
  end

  def to_number(number_string) when is_binary(number_string) do
    number_string
    |> String.split(".")
    |> to_number
  end

  def to_number([integer]) do
    String.to_integer(integer)
  end

  def to_number([integer, fraction]) do
    String.to_float(integer <> "." <> fraction)
  end

  def round(%Cldr.Unit{value: value} = unit, rounding) when is_float(value) do
    value = Float.round(value, rounding)
    %{unit | value: value}
  end

  def round(%Cldr.Unit{value: value} = unit, _rounding) when is_integer(value) do
    unit
  end

end