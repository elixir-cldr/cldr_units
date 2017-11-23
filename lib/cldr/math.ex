defmodule Cldr.Unit.Math do
  @moduledoc """
  Simple arithmetic functions for the `Unit.t` type
  """
  alias Cldr.Unit
  alias Cldr.Unit.Conversion

  import Kernel, except: [div: 2]
  import Unit, only: [incompatible_unit_error: 2]

  @doc """
  Adds two compatible `%Unit{}` types

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the sum of `unit_1` and the potentially converted
    `unit_2` or

  * {:error, {IncompatibleUnitError, message}}

  ## Examples

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:foot, 1)
      #Unit<:foot, 2>

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:mile, 1)
      #Unit<:foot, 5280.945925937846>

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:gallon, 1)
      {:error, {Cldr.Unit.IncompatibleUnitError,
        "Operations can only be performed between units of the same type. Received #Unit<:foot, 1> and #Unit<:gallon, 1>"}}

  """
  @spec add(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | {:error, {Unit.IncompatibleUnitError, String.t}}

  def add(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 + value_2)
  end

  def add(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    Unit.new!(unit, Decimal.add(value_1, value_2))
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

  def add(%Unit{unit: unit_type_1} = unit_1, %Unit{unit: unit_type_2} = unit_2) do
    if Unit.compatible?(unit_type_1, unit_type_2) do
      add(unit_1, Conversion.convert(unit_2, unit_type_1))
    else
      {:error, incompatible_unit_error(unit_1, unit_2)}
    end
  end

  @doc """
  Adds two compatible `%Unit{}` types
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the sum of `unit_1` and the potentially converted
    `unit_2` or

  * Raises an exception

  """
  @spec add!(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | no_return()

  def add!(unit_1, unit_2) do
    case add(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end


  @doc """
  Subtracts two compatible `%Unit{}` types

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the difference between `unit_1` and the potentially
    converted `unit_2`

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

      iex> Cldr.Unit.sub Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      #Unit<:kilogram, 4.54640709056436>

      iex> Cldr.Unit.sub Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      #Unit<:pint, 2.88662>

      iex> Cldr.Unit.sub Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      #Unit<:pint, 4>

  """
  @spec sub(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | {:error, {Unit.IncompatibleUnitError, String.t}}

  def sub(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 - value_2)
  end

  def sub(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    Unit.new!(unit, Decimal.sub(value_1, value_2))
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

  def sub(%Unit{unit: unit_type_1} = unit_1, %Unit{unit: unit_type_2} = unit_2) do
    if Unit.compatible?(unit_type_1, unit_type_2) do
      sub(unit_1, Conversion.convert(unit_2, unit_type_1))
    else
      {:error, incompatible_unit_error(unit_1, unit_2)}
    end
  end

  @doc """
  Subtracts two compatible `%Unit{}` types
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the difference between `unit_1` and the potentially
    converted `unit_2`

  * Raises an exception

  """
  @spec sub!(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | no_return()

  def sub!(unit_1, unit_2) do
    case sub(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc """
  Multiplies two compatible `%Unit{}` types

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the product of `unit_1` and the potentially
    converted `unit_2`

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

      iex> Cldr.Unit.mult Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      #Unit<:kilogram, 2.2679645471781984>

      iex> Cldr.Unit.mult Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      #Unit<:pint, 10.566899999999999>

      iex> Cldr.Unit.mult Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      #Unit<:pint, 5>

  """
  @spec mult(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | {:error, {Unit.IncompatibleUnitError, String.t}}
  def mult(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 * value_2)
  end

  def mult(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    Unit.new!(unit, Decimal.mult(value_1, value_2))
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

  def mult(%Unit{unit: unit_type_1} = unit_1, %Unit{unit: unit_type_2} = unit_2) do
    if Unit.compatible?(unit_type_1, unit_type_2) do
      mult(unit_1, Conversion.convert(unit_2, unit_type_1))
    else
      {:error, incompatible_unit_error(unit_1, unit_2)}
    end
  end

  @doc """
  Multiplies two compatible `%Unit{}` types
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the product of `unit_1` and the potentially
    converted `unit_2`

  * Raises an exception

  """
  @spec mult!(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | no_return()

  def mult!(unit_1, unit_2) do
    case mult(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc """
  Divides one compatible `%Unit{}` type by another

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the dividend of `unit_1` and the potentially
    converted `unit_2`

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

  iex> Cldr.Unit.div Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
  #Unit<:kilogram, 11.023100000000001>

  iex> Cldr.Unit.div Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
  #Unit<:pint, 2.365878355998448>

  iex> Cldr.Unit.div Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
  #Unit<:pint, 5.0>

  """
  @spec div(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | {:error, {Unit.IncompatibleUnitError, String.t}}

  def div(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
  when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 / value_2)
  end

  def div(%Unit{unit: unit, value: %Decimal{} = value_1},
          %Unit{unit: unit, value: %Decimal{} = value_2}) do
    Unit.new!(unit, Decimal.div(value_1, value_2))
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

  def div(%Unit{unit: unit_type_1} = unit_1, %Unit{unit: unit_type_2} = unit_2) do
    if Unit.compatible?(unit_type_1, unit_type_2) do
      div(unit_1, Conversion.convert(unit_2, unit_type_1))
    else
      {:error, incompatible_unit_error(unit_1, unit_2)}
    end
  end

  @doc """
  Divides one compatible `%Unit{}` type by another
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same time as `unit_1` with a value
    that is the dividend of `unit_1` and the potentially
    converted `unit_2`

  * Raises an exception

  """
  @spec div!(unit_1 :: Unit.t, unit_2 :: Unit.t) ::
    Unit.t | no_return()

  def div!(unit_1, unit_2) do
    case div(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end
end