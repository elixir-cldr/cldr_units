defmodule Cldr.Unit.Math do
  @moduledoc """
  Simple arithmetic for the `%Unit{}` type
  """
  alias Cldr.Unit
  import Kernel, except: [div: 2]
  import Unit, only: [incompatible_unit_error: 2]

  def add(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    {:ok, Unit.new!(unit, value_1 + value_2)}
  end

  def add(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    {:ok, Unit.new!(unit, Decimal.add(value_1, value_2))}
  end

  def add(%Unit{unit: unit, value: %Decimal{}} = unit_1,
          %Unit{unit: unit, value: value_2})
  when is_number(value_2) do
    add(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def add(%Unit{unit: unit, value: value_2},
          %Unit{unit: unit, value: %Decimal{}} = unit_1)
  when is_number(value_2) do
    add(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def add(%Unit{unit: unit_1}, %Unit{unit: unit_2}) do
    {:error, incompatible_unit_error(unit_1, unit_2)}
  end

  def add!(unit_1, unit_2) do
    case add(unit_1, unit_2) do
      {:ok, unit} -> unit
      {:error, {exception, reason}} -> raise exception, reason
    end
  end



  def sub(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    {:ok, Unit.new!(unit, value_1 - value_2)}
  end

  def sub(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    {:ok, Unit.new!(unit, Decimal.sub(value_1, value_2))}
  end

  def sub(%Unit{unit: unit, value: %Decimal{}} = unit_1,
          %Unit{unit: unit, value: value_2})
  when is_number(value_2) do
    sub(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def sub(%Unit{unit: unit, value: value_2},
          %Unit{unit: unit, value: %Decimal{}} = unit_1)
  when is_number(value_2) do
    sub(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def sub(%Unit{unit: unit_1}, %Unit{unit: unit_2}) do
    {:error, incompatible_unit_error(unit_1, unit_2)}
  end

  def sub!(unit_1, unit_2) do
    case sub(unit_1, unit_2) do
      {:ok, unit} -> unit
      {:error, {exception, reason}} -> raise exception, reason
    end
  end




  def mult(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    {:ok, Unit.new!(unit, value_1 * value_2)}
  end

  def mult(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    {:ok, Unit.new!(unit, Decimal.mult(value_1, value_2))}
  end

  def mult(%Unit{unit: unit, value: %Decimal{}} = unit_1,
          %Unit{unit: unit, value: value_2})
  when is_number(value_2) do
    mult(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def mult(%Unit{unit: unit, value: value_2},
          %Unit{unit: unit, value: %Decimal{}} = unit_1)
  when is_number(value_2) do
    mult(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def mult(%Unit{unit: unit_1}, %Unit{unit: unit_2}) do
    {:error, incompatible_unit_error(unit_1, unit_2)}
  end

  def mult!(unit_1, unit_2) do
    case mult(unit_1, unit_2) do
      {:ok, unit} -> unit
      {:error, {exception, reason}} -> raise exception, reason
    end
  end





  def div(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    {:ok, Unit.new!(unit, value_1 / value_2)}
  end

  def div(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    {:ok, Unit.new!(unit, Decimal.div(value_1, value_2))}
  end

  def div(%Unit{unit: unit, value: %Decimal{}} = unit_1,
          %Unit{unit: unit, value: value_2})
  when is_number(value_2) do
    div(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def div(%Unit{unit: unit, value: value_2},
          %Unit{unit: unit, value: %Decimal{}} = unit_1)
  when is_number(value_2) do
    div(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def div(%Unit{unit: unit_1}, %Unit{unit: unit_2}) do
    {:error, incompatible_unit_error(unit_1, unit_2)}
  end

  def div!(unit_1, unit_2) do
    case div(unit_1, unit_2) do
      {:ok, unit} -> unit
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

end