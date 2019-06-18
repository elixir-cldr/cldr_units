defmodule Cldr.Unit.Conversion do
  @moduledoc """
  Unit conversion functions for the units defined
  in `Cldr`.

  """

  alias Cldr.Unit
  import Unit, only: [incompatible_units_error: 2]

  @external_resource Path.join("./priv", "conversion_factors.json")

  @conversion_factors @external_resource
                      |> File.read!()
                      |> Jason.decode!()
                      |> Cldr.Map.atomize_keys()

  def direct_factors do
    unquote(Macro.escape(Map.get(@conversion_factors, :direct_factors)))
  end

  @factors Enum.reject(@conversion_factors, fn {k, _v} -> k == :direct_factors end)
           |> Map.new()
           |> Map.merge(Cldr.Unit.Conversion.FunctionFactors.factors())

  def factors do
    unquote(Macro.escape(@factors))
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...)

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `to_unit` is any unit name returned by `Cldr.Unit.units/0`

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.convert Cldr.Unit.new!(:celsius, 0), :fahrenheit
      #Unit<:fahrenheit, 32.0>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Unit<:celsius, 0.0>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :foot
      #Unit<:foot, 5279.945925937846>

      iex> Cldr.Unit.convert Cldr.Unit.new!(:mile, 1), :gallon
      {:error, {Cldr.Unit.IncompatibleUnitsError,
                "Operations can only be performed between units of the same type. Received :mile and :gallon"}}

  """
  @spec convert(Unit.t(), Unit.unit()) :: Unit.t() | {:error, {module(), String.t()}}

  def convert(%Unit{unit: from_unit, value: value} = from, to_unit) do
    cond do
      unit_mult = get_in(direct_factors(), [from_unit, to_unit]) ->
        {:ok, new_value} = convert(value, 1, unit_mult)
        Unit.new(to_unit, new_value)

      unit_div = get_in(direct_factors(), [to_unit, from_unit]) ->
        {:ok, new_value} = convert(value, unit_div, 1)
        Unit.new(to_unit, new_value)

      true ->
        two_step_convert(from, to_unit)
    end
  end

  defp two_step_convert(%Unit{unit: from_unit, value: value}, to_unit) do
    with {:ok, to_unit} <- Unit.validate_unit(to_unit),
         true <- Unit.compatible?(from_unit, to_unit),
         {:ok, converted} <- convert(value, factor(from_unit), factor(to_unit)) do
      Unit.new(to_unit, converted)
    else
      {:error, _} = error -> error
      false -> {:error, incompatible_units_error(from_unit, to_unit)}
    end
  end

  defp convert(value, from, to) when is_number(value) and is_number(from) and is_number(to) do
    converted = value / from * to
    truncated = trunc(converted)

    if converted == truncated do
      {:ok, truncated}
    else
      {:ok, converted}
    end
  end

  defp convert(%Decimal{} = value, from, to) when is_number(from) and is_number(to) do
    converted =
      value
      |> Decimal.div(decimal_new(from))
      |> Decimal.mult(decimal_new(to))

    {:ok, converted}
  end

  defp convert(value, {to_base_fun, _}, to) when is_number(value) and is_number(to) do
    {:ok, to_base_fun.(value) * to}
  end

  defp convert(%Decimal{} = value, {to_base_fun, _}, to) when is_number(to) do
    {:ok, Decimal.mult(to_base_fun.(value), decimal_new(to))}
  end

  defp convert(value, from, {_to_fun, from_base_fun}) when is_number(value) and is_number(from) do
    {:ok, from_base_fun.(value / from)}
  end

  defp convert(%Decimal{} = value, from, {_to_fun, from_base_fun}) when is_number(from) do
    {:ok, Decimal.div(from_base_fun.(value), decimal_new(from))}
  end

  defp convert(value, {to_base_fun, _}, {_, from_base_fun}) do
    {:ok, from_base_fun.(to_base_fun.(value))}
  end

  defp convert(_value, from, to)
       when from == :not_convertible or to == :not_convertible do
    {:error,
     {Cldr.Unit.UnitNotConvertibleError,
      "No conversion is possible between #{inspect(to)} and #{inspect(from)}"}}
  end

  @doc """
  Convert one unit into another unit of the same
  unit type (length, volume, mass, ...) and raises
  on a unit type mismatch

  ## Options

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `to_unit` is any unit name returned by `Cldr.Unit.units/0`

  ## Returns

  * a `Unit.t` of the unit type `to_unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Conversion.convert! Cldr.Unit.new!(:celsius, 0), :fahrenheit
      #Unit<:fahrenheit, 32.0>

      iex> Cldr.Unit.Conversion.convert! Cldr.Unit.new!(:fahrenheit, 32), :celsius
      #Unit<:celsius, 0.0>

      Cldr.Unit.Conversion.convert Cldr.Unit.new!(:mile, 1), :gallon
      ** (Cldr.Unit.IncompatibleUnitsError) Operations can only be performed between units of the same type. Received :mile and :gallon

  """
  @spec convert!(Unit.t(), Unit.unit()) :: Unit.t() | no_return()

  def convert!(%Unit{} = unit, to_unit) do
    case convert(unit, to_unit) do
      {:error, {exception, reason}} -> raise exception, reason
      unit -> unit
    end
  end

  @doc false
  def factor(unit) do
    unit_type = Unit.unit_type(unit)
    get_in(factors(), [unit_type, unit])
  end

  defp decimal_new(n) when is_integer(n), do: Decimal.new(n)
  defp decimal_new(n) when is_float(n), do: Decimal.from_float(n)
end
