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

  @float ~r/^([-+]?[0-9]*)\.([0-9]+)([eE]([-+]?[0-9]+))?$/
  def transform({:result, result}) do
    result = String.replace(result, ",", "")

    result =
      case Regex.run(@float, result) do
        [float, _integer, fraction] ->
          {String.to_float(float), String.length(fraction), 9}
        [float, integer, fraction, _, exp] ->
          # Its a bigint
          if (p = String.to_integer(exp) - String.length(fraction)) > 0 do
            int =
              String.to_integer(integer <> fraction <> String.duplicate("0", p))
            {int, 0, String.length(fraction) + String.length(integer)}
          else
            {String.to_float(float), String.length(fraction), 9}
          end
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

  def round(%Cldr.Unit{value: value} = unit, digits, significant) when is_number(value) do
    value =
      value
      |> round(digits)
      |> round_significant(significant)

    %{unit | value: value}
  end

  def round(float, digits) when is_float(float) do
    Float.round(float, digits)
  end

  def round(other, _digits) do
    other
  end

  def round_significant(0.0 = value, _) do
    value
  end

  def round_significant(integer, round_digits) when is_integer(integer) do
    number_of_digits = Cldr.Digits.number_of_integer_digits(integer)
    rounding = number_of_digits - round_digits - 1
    p = if rounding > 0, do: Cldr.Math.power(10, rounding) |> trunc(), else: 1

    integer
    |> div(p)
    |> Kernel.*(p)
  end

  def round_significant(float, digits) when is_float(float) do
    Cldr.Math.round_significant(float, digits)
  end
end