defmodule Cldr.Unit.Math do
  @moduledoc """
  Simple arithmetic functions for the `Unit.t` type
  """
  alias Cldr.Unit
  alias Cldr.Unit.Conversion

  import Kernel, except: [div: 2, round: 1, trunc: 1]
  import Unit, only: [incompatible_units_error: 2]

  @doc """
  Adds two compatible `%Unit{}` types

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the sum of `unit_1` and the potentially converted
    `unit_2` or

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:foot, 1)
      #Cldr.Unit<:foot, 2>

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:mile, 1)
      #Cldr.Unit<:foot, 5281>

      iex> Cldr.Unit.Math.add Cldr.Unit.new!(:foot, 1), Cldr.Unit.new!(:gallon, 1)
      {:error, {Cldr.Unit.IncompatibleUnitsError,
        "Operations can only be performed between units with the same base unit. Received :foot and :gallon"}}

  """
  @spec add(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def add(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_1) and is_number(value_2) do
    %{unit_1 | value: value_1 + value_2}
  end

  def add(%Unit{unit: unit, value: %Decimal{}} = u1, %Unit{unit: unit, value: %Decimal{}} = u2) do
    %{u1 | value: Decimal.add(u1.value, u2.value)}
  end

  def add(%Unit{unit: unit, value: %Decimal{}} = unit_1, %Unit{unit: unit, value: value_2} = unit_2)
      when is_number(value_2) do
    add(unit_1, %{unit_2 | value: Decimal.new(value_2)})
  end

  def add(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: %Decimal{}} = unit_2)
      when is_number(value_1) do
    add(%{unit_1 | value: Decimal.new(value_1)}, unit_2)
  end

  def add(%Unit{unit: unit, value: %Ratio{} = value_1} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    %{unit_1 | value: Ratio.add(value_1, value_2)}
  end

  def add(%Unit{unit: unit, value: value_2} = unit_1, %Unit{unit: unit, value: %Ratio{} = value_1})
      when is_number(value_2) do
    %{unit_1 | value: Ratio.add(value_1, value_2)}
  end

  def add(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      add(unit_1, Conversion.convert!(unit_2, unit_category_1))
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @doc """
  Adds two compatible `%Unit{}` types
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the sum of `unit_1` and the potentially converted
    `unit_2` or

  * Raises an exception

  """
  @spec add!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

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

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the difference between `unit_1` and the potentially
    converted `unit_2`

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

      iex> Cldr.Unit.sub Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      #Cldr.Unit<:kilogram, 81900798833369519 <|> 18014398509481984>

      iex> Cldr.Unit.sub Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      #Cldr.Unit<:pint, 36794683014431043834033898368027039378825884348261 <|> 12746616238742849396626455585282990375683527307233>

      iex> Cldr.Unit.sub Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      #Cldr.Unit<:pint, 4>

  """
  @spec sub(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def sub(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
      when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 - value_2)
  end

  def sub(%Unit{unit: unit, value: %Decimal{} = value_1} = unit_1, %Unit{
        unit: unit,
        value: %Decimal{} = value_2
      }) do
    %{unit_1 | value: Decimal.sub(value_1, value_2)}
  end

  def sub(%Unit{unit: unit, value: %Decimal{}} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    sub(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def sub(%Unit{unit: unit, value: value_2}, %Unit{unit: unit, value: %Decimal{}} = unit_1)
      when is_number(value_2) do
    sub(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def sub(%Unit{unit: unit, value: %Ratio{} = value_1} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    %{unit_1 | value: Ratio.sub(value_1, value_2)}
  end

  def sub(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: %Ratio{} = value_2})
      when is_number(value_1) do
    %{unit_1 | value: Ratio.sub(value_1, value_2)}
  end

  def sub(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      sub(unit_1, Conversion.convert!(unit_2, unit_category_1))
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @doc """
  Subtracts two compatible `%Unit{}` types
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the difference between `unit_1` and the potentially
    converted `unit_2`

  * Raises an exception

  """
  @spec sub!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

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

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the product of `unit_1` and the potentially
    converted `unit_2`

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

      iex> Cldr.Unit.mult Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      #Cldr.Unit<:kilogram, 40855968570202005 <|> 18014398509481984>

      iex> Cldr.Unit.mult Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      #Cldr.Unit<:pint, 134691990896416015745491897791939562497958760939520 <|> 12746616238742849396626455585282990375683527307233>

      iex> Cldr.Unit.mult Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      #Cldr.Unit<:pint, 5>

  """
  @spec mult(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def mult(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
      when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 * value_2)
  end

  def mult(%Unit{unit: unit, value: %Decimal{} = value_1} = unit_1, %Unit{
        unit: unit,
        value: %Decimal{} = value_2
      }) do
    %{unit_1 | value: Decimal.mult(value_1, value_2)}
  end

  def mult(%Unit{unit: unit, value: %Decimal{}} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    mult(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def mult(%Unit{unit: unit, value: value_2}, %Unit{unit: unit, value: %Decimal{}} = unit_1)
      when is_number(value_2) do
    mult(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def mult(%Unit{unit: unit, value: %Ratio{} = value_1} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    %{unit_1 | value: Ratio.mult(value_1, value_2)}
  end

  def mult(%Unit{unit: unit, value: value_1} = unit_1, %Unit{unit: unit, value: %Ratio{} = value_2})
      when is_number(value_1) do
    %{unit_1 | value: Ratio.mult(value_1, value_2)}
  end

  def mult(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      {:ok, conversion} = Conversion.convert(unit_2, unit_category_1)
      mult(unit_1, conversion)
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @doc """
  Multiplies two compatible `%Unit{}` types
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the product of `unit_1` and the potentially
    converted `unit_2`

  * Raises an exception

  """
  @spec mult!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

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

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the dividend of `unit_1` and the potentially
    converted `unit_2`

  * `{:error, {IncompatibleUnitError, message}}`

  ## Examples

      iex> Cldr.Unit.div Cldr.Unit.new!(:kilogram, 5), Cldr.Unit.new!(:pound, 1)
      #Cldr.Unit<:kilogram, 8171193714040401 <|> 90071992547409920>

      iex> Cldr.Unit.div Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:liter, 1)
      #Cldr.Unit<:pint, 26938398179283203149098379558387912499591752187904 <|> 63733081193714246983132277926414951878417636536165>

      iex> Cldr.Unit.div Cldr.Unit.new!(:pint, 5), Cldr.Unit.new!(:pint, 1)
      #Cldr.Unit<:pint, 5.0>

  """
  @spec div(Unit.t(), Unit.t()) :: Unit.t() | {:error, {module(), String.t()}}

  def div(%Unit{unit: unit, value: value_1}, %Unit{unit: unit, value: value_2})
      when is_number(value_1) and is_number(value_2) do
    Unit.new!(unit, value_1 / value_2)
  end

  def div(%Unit{unit: unit, value: %Decimal{} = value_1}, %Unit{
        unit: unit,
        value: %Decimal{} = value_2
      }) do
    Unit.new!(unit, Decimal.div(value_1, value_2))
  end

  def div(%Unit{unit: unit, value: %Decimal{}} = unit_1, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    div(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def div(%Unit{unit: unit, value: value_2}, %Unit{unit: unit, value: %Decimal{}} = unit_1)
      when is_number(value_2) do
    div(unit_1, Unit.new!(unit, Decimal.new(value_2)))
  end

  def div(%Unit{unit: unit, value: %Ratio{} = value_1}, %Unit{unit: unit, value: value_2})
      when is_number(value_2) do
    Unit.new!(unit, Ratio.div(value_1, value_2))
  end

  def div(%Unit{unit: unit, value: value_2}, %Unit{unit: unit, value: %Ratio{} = value_1})
      when is_number(value_2) do
    Unit.new!(unit, Ratio.div(value_1, value_2))
  end

  def div(%Unit{unit: unit_category_1} = unit_1, %Unit{unit: unit_category_2} = unit_2) do
    if Unit.compatible?(unit_category_1, unit_category_2) do
      div(unit_1, Conversion.convert!(unit_2, unit_category_1))
    else
      {:error, incompatible_units_error(unit_1, unit_2)}
    end
  end

  @doc """
  Divides one compatible `%Unit{}` type by another
  and raises on error

  ## Options

  * `unit_1` and `unit_2` are compatible Units
    returned by `Cldr.Unit.new/2`

  ## Returns

  * A `%Unit{}` of the same type as `unit_1` with a value
    that is the dividend of `unit_1` and the potentially
    converted `unit_2`

  * Raises an exception

  """
  @spec div!(Unit.t(), Unit.t()) :: Unit.t() | no_return()

  def div!(unit_1, unit_2) do
    case div(unit_1, unit_2) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc """
  Rounds the value of a unit.

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `places` is the number of decimal places to round to.  The default is `0`.

  * `mode` is the rounding mode to be applied.  The default is `:half_up`.

  ## Returns

  * A `%Unit{}` of the same type as `unit` with a value
    that is rounded to the specified number of decimal places

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
      #Cldr.Unit<:yard, 1031.6>

      iex> Cldr.Unit.round Cldr.Unit.new!(:yard, 1031.61), 2
      #Cldr.Unit<:yard, 1031.61>

      iex> Cldr.Unit.round Cldr.Unit.new!(:yard, 1031.61), 1, :up
      #Cldr.Unit<:yard, 1031.7>

  """
  @spec round(
          unit :: Unit.t(),
          places :: non_neg_integer,
          mode :: :down | :up | :ceiling | :floor | :half_even | :half_up | :half_down
        ) :: Unit.t()

  def round(unit, places \\ 0, mode \\ :half_up)

  def round(%Unit{value: %Ratio{} = value} = unit, places, mode) do
    value = Ratio.to_float(value)
    round(%{unit | value: value}, places, mode)
  end

  def round(%Unit{value: value} = unit_1, places, mode) do
    rounded_value = Cldr.Math.round(value, places, mode)
    %{unit_1 | value: rounded_value}
  end

  @doc """
  Truncates a unit's value

  """
  def trunc(%Unit{value: %Ratio{} = value} = unit) do
    value = Ratio.to_float(value)
    trunc(%{unit | value: value})
  end

  def trunc(%Unit{value: value} = unit) when is_float(value) do
    %{unit | value: Kernel.trunc(value)}
  end

  def trunc(%Unit{value: value} = unit) when is_integer(value) do
    unit
  end

  def trunc(%Unit{value: %Decimal{} = value} = unit) do
    %{unit | value: Decimal.round(value, 0, :floor)}
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
  def compare(
        %Unit{unit: unit, value: %Decimal{}} = unit_1,
        %Unit{unit: unit, value: %Decimal{}} = unit_2
      ) do
    Cldr.Decimal.compare(unit_1.value, unit_2.value)
  end

  def compare(%Unit{value: %Decimal{}} = unit_1, %Unit{value: %Decimal{}} = unit_2) do
    unit_2 = Unit.Conversion.convert!(unit_2, unit_1.unit)
    compare(unit_1, unit_2)
  end

  def compare(%Unit{unit: unit} = unit_1, %Unit{unit: unit} = unit_2) do
    Ratio.compare(Ratio.new(unit_1.value), Ratio.new(unit_2.value))
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
end
