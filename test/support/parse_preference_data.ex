defmodule Cldr.Unit.Test.PreferenceData do
  # Quantity;   Usage;  Region; Input (r);  Input (d);  Input Unit; Output (r); Output (d); Output Unit

  # mass;   person; GB; 0;  0.0;    kilogram;   1;  stone;  0;  0.0;    pound

  @preference_test_data "test/support/data/preference_test_data.txt"
  @offset 1

  def preference_test_data do
    @preference_test_data
    |> File.read!
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
  end

  def preferences do
    preference_test_data()
    |> Enum.with_index
    |> Enum.map(&parse_test/1)
    |> Enum.reject(&is_nil/1)
  end

  @fields [:quantity, :usage, :region, :input_rational, :input_double, :input_unit, :output]

  def parse_test({"", _}) do
    nil
  end

  def parse_test({<< "#", _rest :: binary >>, _}) do
    nil
  end

  def parse_test({test, index}) do
    test
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> zip(@fields)
    |> Enum.map(&transform/1)
    |> set_output_units()
    |> Map.new
    |> Map.put(:line, index + @offset)
  end

  def zip(data, fields) do
    {input, output} = :lists.split(6, data)

    fields
    |> Enum.zip((input ++ [output]))
  end

  def set_output_units(test) do
    Keyword.put(test, :output_units, Enum.map(Keyword.get(test, :output), &elem(&1, 0)))
  end

  def transform({:output, [first_rational, first_unit, output_rational, output_double, output_unit]}) do
    {:output,
      [
        {first_unit, [first_rational, nil]},
        {output_unit, [output_rational, output_double]}
      ]
    }
  end

  def transform({:output, [output_rational, output_double, output_unit]}) do
    {:output, [{output_unit, [output_rational, output_double]}]}
  end

  def transform({:input_double, string}) do
    {:input_double, String.to_float(string)}
  end

  def transform({:input_rational, string}) do
    {:input_rational, to_rational(string)}
  end

  def transform({:region, string}) do
    {:region, String.to_atom(string)}
  end

  def transform({:usage, string}) do
    {:usage, String.to_atom(String.replace(string, "-", "_"))}
  end

  def transform({:input_unit, string}) do
    {:input_unit, String.replace(string, "-", "_")}
  end

  def transform(x) do
    x
  end

  def to_rational(string) do
    rational =
      string
      |> String.split("/")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.to_integer/1)

    case rational do
      [numerator, denominator] -> Ratio.new(numerator, denominator)
      [integer] -> integer
      _other -> raise ArgumentError, "Can't convert #{inspect string} to a rational"
    end
  end
end