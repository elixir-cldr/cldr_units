defmodule Cldr.Unit.Conversion do
  @moduledoc """
  Unit conversion functions for the units defined
  in `Cldr`.

  """

  @enforce_keys [:factor, :offset, :base_unit]
  defstruct [
    factor: 1,
    offset: 0,
    base_unit: nil
  ]

  @type t :: %{
    factor: integer | float | Ratio.t(),
    base_unit: [atom(), ...],
    offset: integer | float
  }

  alias Cldr.Unit

  import Unit, only: [incompatible_units_error: 2]

  defmodule Options do
    defstruct [usage: nil, locale: nil, backend: nil, territory: nil]
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...)

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `to_unit` is any unit name returned by `Cldr.Unit.units/0`

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.convert Cldr.Unit.new!(:celsius, 0), :fahrenheit
      #Cldr.Unit<:fahrenheit, 32>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Cldr.Unit<:celsius, 0>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :foot
      #Cldr.Unit<:foot, 5280>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :gallon
      {:error, {Cldr.Unit.IncompatibleUnitsError,
        "Operations can only be performed between units of the same category. Received :mile and :gallon"}}

  """
  @spec convert(Unit.t(), Unit.unit()) :: Unit.t() | {:error, {module(), String.t()}}

  def convert(%Unit{unit: from_unit, value: _value} = unit, from_unit) do
    {:ok, unit}
  end

  def convert(%Unit{} = unit, to_unit) do
    %{unit: from_unit, value: value, base_conversion: from_conversion} = unit

    with {:ok, to_unit, to_conversion} <- Unit.validate_unit(to_unit),
         {:ok, converted} <- convert(value, from_conversion, to_conversion) do
      Unit.new(to_unit, converted, localize: unit.localize)
    else
      {:error, {Cldr.Unit.IncompatibleUnitsError, _}} ->
        {:error, incompatible_units_error(from_unit, to_unit)}
    end
  end

  defp convert(value, from, to) when is_number(value) or is_map(value) do
    use Ratio

    with {:ok, from, to} <- compatible(from, to) do
      value
      |> Ratio.new
      |> convert_to_base(from)
      |> convert_from_base(to)
      |> to_original_number_type(value)
      |> maybe_truncate
      |> wrap_ok
    end
  end

  def convert_to_base(value, %__MODULE__{} = from) do
    use Ratio

    %{factor: from_factor, offset: from_offset} = from
    (value * from_factor) + from_offset
  end

  def convert_to_base(value, {_, %__MODULE__{} = from}) do
    convert_to_base(value, from)
  end

  def convert_to_base(value, {numerator, denominator}) do
    use Ratio

    convert_to_base(1, numerator) / convert_to_base(1, denominator) * value
  end

  def convert_to_base(value, []) do
    value
  end

  def convert_to_base(value, [numerator | rest]) do
    convert_to_base(value, numerator) |> convert_to_base(rest)
  end

  def convert_from_base(value, %__MODULE__{} = to) do
    use Ratio
    %{factor: to_factor, offset: to_offset} = to
    ((value - to_offset) / to_factor)
  end

  def convert_from_base(value, {_, %__MODULE__{} = to}) do
    convert_from_base(value, to)
  end

  def convert_from_base(value, {numerator, denominator}) do
    use Ratio

    convert_from_base(1, numerator) / convert_from_base(1, denominator) * value
  end

  def convert_from_base(value, []) do
    value
  end

  def convert_from_base(value, [numerator | rest]) do
    convert_from_base(value, numerator) |> convert_from_base(rest)
  end

  defp to_original_number_type(%Ratio{} = converted, value) when is_float(value) do
    %Ratio{numerator: numerator, denominator: denominator} = converted

    numerator / denominator
  end

  defp to_original_number_type(%Ratio{} = converted, value) when is_integer(value) do
    %Ratio{numerator: numerator, denominator: denominator} = converted

   (numerator / denominator)
   |> Float.round(0)
   |> trunc
  end

  defp to_original_number_type(%Ratio{} = converted, %Decimal{} = _value) do
    %Ratio{numerator: numerator, denominator: denominator} = converted

    Decimal.new(numerator)
    |> Decimal.div(Decimal.new(denominator))
  end

  defp to_original_number_type(converted, value) when is_number(value) do
    converted
  end

  defp to_original_number_type(converted, %Decimal{} = _value) do
    Decimal.new(converted)
  end

  # Establish whether the two units are compatible. If not
  # then also see if the inverse units are compatible
  defp compatible(from, to, direction \\ :normal)

  defp compatible(from, to, :normal) do
    with {:ok, base_unit_from} <- Unit.base_unit(from),
         {:ok, base_unit_to} <- Unit.base_unit(to),
         true <- to_string(base_unit_from) == to_string(base_unit_to) do
      {:ok, from, to}
    else
      _ -> compatible(from, to, :invert)
    end
  end

  defp compatible(from, to, :invert) do
    inverted_base = invert_base_name(from)

    with {:ok, base_unit_from} <- Unit.base_unit(inverted_base),
         {:ok, base_unit_to} <- Unit.base_unit(to),
         true <- to_string(base_unit_from) == to_string(base_unit_to) do
      {:ok, invert_factors(from), to}
    end
  end

  defp invert_base_name({numerator, denominator}) do
    {denominator, numerator}
  end

  defp invert_base_name(other) do
    other
  end

  # To invert the conversion we invert each of the
  # terms of the conversion.
  # TODO: Implement it properly
  defp invert_factors({numerator, denominator}) do
    {numerator, denominator}
  end

  defp maybe_truncate(converted) when is_number(converted) do
    truncated = trunc(converted)

    if converted == truncated do
      truncated
    else
      converted
    end
  end

  defp maybe_truncate(%Decimal{} = converted) do
    truncated = Decimal.round(converted, 0, :down)

    if Decimal.equal?(converted, truncated) do
      truncated
    else
      converted
    end
  end

  defp wrap_ok(unit) do
    {:ok, unit}
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...) and raises
  on a unit type mismatch

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `to_unit` is any unit name returned by `Cldr.Unit.units/0`

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Conversion.convert! Cldr.Unit.new!(:celsius, 0), :fahrenheit
      #Cldr.Unit<:fahrenheit, 32>

      iex> Cldr.Unit.Conversion.convert! Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Cldr.Unit<:celsius, 0>

      Cldr.Unit.Conversion.convert Cldr.Unit.new!(:mile, 1), :gallon
      ** (Cldr.Unit.IncompatibleUnitsError) Operations can only be performed between units of the same type. Received :mile and :gallon

  """
  @spec convert!(Unit.t(), Unit.unit()) :: Unit.t() | no_return()

  def convert!(%Unit{} = unit, to_unit) do
    case convert(unit, to_unit) do
      {:error, {exception, reason}} -> raise exception, reason
      {:ok, unit} -> unit
    end
  end

  @doc """
  Convert a unit into its base unit.

  For example, the base unit for `length`
  is `meter`. The base unit is an
  intermediary unit used in all
  conversions.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Returns

  * `unit` converted to its base unit as a `t:Unit.t()` or

  * `{;error, {exception, reason}}` as an error

  ## Example

      iex> u = Cldr.Unit.new!(:kilometer, 10)
      iex> Cldr.Unit.Conversion.convert_to_base_unit u
      {:ok, #Cldr.Unit<:meter, 10000>}

  """
  def convert_to_base_unit(%Unit{} = unit) do
    with {:ok, base_unit} <- Unit.base_unit(unit) do
      convert(unit, base_unit)
    end
  end

  def convert_to_base_unit(unit) when is_atom(unit) do
    unit
    |> Unit.new!(1.0)
    |> convert_to_base_unit()
  end

  def convert_to_base_unit([unit | _rest]) when is_atom(unit) do
    convert_to_base_unit(unit)
  end

  @doc """
  Convert a unit into its base unit and
  raises on error

  For example, the base unit for `length`
  is `meter`. The base unit is an
  intermediary unit used in all
  conversions.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  ## Returns

  * `unit` converted to its base unit as a `t:Unit.t()` or

  * raises an exception

  ## Example

      iex> u = Cldr.Unit.new!(:kilometer, 10)
      iex> Cldr.Unit.Conversion.convert_to_base_unit! u
      #Cldr.Unit<:meter, 10000>

  """
  def convert_to_base_unit!(%Unit{} = unit) do
    case convert_to_base_unit(unit) do
      {:error, {exception, reason}} -> raise exception, reason
      {:ok, unit} -> unit
    end
  end

end
