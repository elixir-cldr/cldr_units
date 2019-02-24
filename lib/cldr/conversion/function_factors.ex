defmodule Cldr.Unit.Conversion.FunctionFactors do
  alias Cldr.Unit.Conversion.FunctionFactors

  def factors do
    %{
      temperature: %{
        celsius: 1,
        fahrenheit: {
          &FunctionFactors.to_fahrenheit/1,
          &FunctionFactors.from_fahrenheit/1
        },
        generic: :not_convertible,
        kelvin: {
          &FunctionFactors.to_kelvin/1,
          &FunctionFactors.from_kelvin/1
        }
      }
    }
  end

  def to_fahrenheit(x) when is_number(x) do
    (x - 32) / 1.8
  end

  def to_fahrenheit(%Decimal{} = x) do
    Decimal.sub(x, Decimal.new(32))
    |> Decimal.div(Decimal.new("1.8"))
  end

  def from_fahrenheit(x) when is_number(x) do
    x * 1.8 + 32
  end

  def from_fahrenheit(%Decimal{} = x) do
    Decimal.mult(x, Decimal.new("1.8"))
    |> Decimal.add(Decimal.new(32))
  end

  def to_kelvin(x) when is_number(x) do
    x - 273.15
  end

  def to_kelvin(%Decimal{} = x) do
    Decimal.sub(x, Decimal.new("273.15"))
  end

  def from_kelvin(x) when is_number(x) do
    x + 273.15
  end

  def from_kelvin(%Decimal{} = x) do
    Decimal.add(x, Decimal.new("273.15"))
  end
end