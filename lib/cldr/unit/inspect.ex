defmodule Cldr.Unit.Inspect do
  @moduledoc false

  # def format(name, %Ratio{numerator: 0, denominator: _}, usage, format_options) do
  #   do_format(name, 0, usage, format_options)
  # end
  #
  # def format(name, %Ratio{numerator: numerator, denominator: 1}, usage, format_options) do
  #   do_format(name, numerator, usage, format_options)
  # end
  #
  # def format(name, %Ratio{} = value, usage, format_options) do
  #   do_format(name, "Ratio.new(#{value.numerator}, #{value.denominator})", usage, format_options)
  # end

  def format(name, value, usage, format_options) do
    do_format(name, value, usage, format_options)
  end

  def do_format(name, value, :default, []) do
    "Cldr.Unit.new!(#{inspect(name)}, #{format_value(value)})"
  end

  def do_format(name, value, :default, format_options) do
    options = "format_options: #{inspect(format_options)}"
    "Cldr.Unit.new!(#{inspect(name)}, #{format_value(value)}, #{options})"
  end

  def do_format(name, value, usage, []) do
    options = "usage: #{inspect(usage)}"
    "Cldr.Unit.new!(#{inspect(name)}, #{format_value(value)}, #{options})"
  end

  def do_format(name, value, usage, format_options) do
    options = "usage: #{inspect(usage)}, format_options: #{inspect(format_options)}"
    "Cldr.Unit.new!(#{inspect(name)}, #{format_value(value)}, #{options})"
  end

  defp format_value(%Decimal{} = value) do
    value
    |> to_string()
    |> inspect()
  end

  defp format_value(value) do
    to_string(value)
  end
end
