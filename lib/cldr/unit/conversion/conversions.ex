defmodule Cldr.Unit.Conversions do
  @moduledoc false

  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Parser

  # CLDR ships some conversion factors and offsets as decimal strings whose
  # significant-digit count exceeds Decimal 3.0's default `:max_digits` of 34
  # (e.g. exact rational expansions of imperial conversions). `Decimal.new/1`
  # rejects those strings on Decimal 3.0; `Decimal.parse/2` with
  # `max_digits: :infinity` accepts them and is available since Decimal 2.4.
  # Older Decimal versions (1.x, 2.0–2.3) have no parse-time digit limit, so
  # `Decimal.new/1` is fine there.
  parse_decimal =
    if function_exported?(Decimal, :parse, 2) do
      fn string ->
        case Decimal.parse(string, max_digits: :infinity) do
          {decimal, ""} ->
            decimal

          _other ->
            raise ArgumentError, "Could not parse Decimal: #{inspect(string)}"
        end
      end
    else
      &Decimal.new/1
    end

  @conversions Map.get(Cldr.Config.units(), :conversions)
               |> Kernel.++(Cldr.Unit.Additional.conversions())
               |> Enum.map(fn
                 {k, v} -> {k, struct(Conversion, v)}
               end)
               |> Enum.map(fn
                 {unit, %{special: special} = conversion} when not is_nil(special) ->
                   {unit, conversion}

                 {unit, %{factor: factor} = conversion} when is_number(factor) ->
                   {unit, conversion}

                 {unit, %{factor: factor} = conversion} when is_binary(factor) ->
                   {unit, %{conversion | factor: parse_decimal.(factor)}}

                 {unit, %{factor: factor} = conversion} ->
                   {unit, %{conversion | factor: Decimal.div(factor.numerator, factor.denominator)}}
               end)
               |> Enum.map(fn
                 {unit, %{special: special} = conversion} when not is_nil(special) ->
                   {unit, conversion}

                 {unit, %{offset: offset} = conversion} when is_number(offset) ->
                   {unit, conversion}

                 {unit, %{offset: offset} = conversion} when is_binary(offset) ->
                   {unit, %{conversion | offset: parse_decimal.(offset)}}

                 {unit, %{offset: offset} = conversion} ->
                   {unit, %{conversion | offset: Decimal.div(offset.numerator, offset.denominator)}}
               end)
               |> Enum.map(fn
                 {unit, %{base_unit: base_unit} = conversion} ->
                   {unit, [{unit, %{conversion | base_unit: [base_unit]}}]}
               end)
               |> Map.new()

  @identity_conversions Enum.map(@conversions, fn
                          {_k, [{_v, %Conversion{base_unit: [base_unit]}}]} ->
                            {base_unit,
                             [
                               {base_unit,
                                %Conversion{base_unit: [base_unit], offset: 0, factor: 1}}
                             ]}
                        end)
                        |> Map.new()

  @all_conversions Map.merge(@conversions, @identity_conversions)

  def conversions do
    unquote(Macro.escape(@all_conversions))
  end

  def conversion_for(unit) when is_atom(unit) do
    case Map.fetch(conversions(), unit) do
      {:ok, conversion} ->
        {:ok, conversion}

      :error ->
        unit_string = Atom.to_string(unit)
        Parser.parse_unit(unit_string)
    end
  end

  def conversion_for(unit) when is_binary(unit) do
    unit
    |> String.to_existing_atom()
    |> conversion_for()
  rescue
    ArgumentError ->
      {:error, Cldr.Unit.unit_error(unit)}
  end

  def conversion_for!(unit) do
    case conversion_for(unit) do
      {:ok, conversion} -> conversion
      {:error, {exception, reason}} -> raise exception, reason
    end
  end
end
