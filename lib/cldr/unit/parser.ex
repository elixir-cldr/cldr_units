defmodule Cldr.Unit.Parser do
  @moduledoc """
  Parse unit strings into composable
  unit structures.  These structures can
  then be used to produced localized output,
  or to be converted to another unit of the
  same unit category.

  """

  alias Cldr.Unit.Conversions
  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Alias
  alias Cldr.Unit.Prefix
  alias Cldr.Unit

  @doc false
  defdelegate wrap(term, token), to: Cldr.Unit.BaseUnit

  @doc false
  defdelegate base_units_in_order, to: Cldr.Unit.BaseUnit

  @currencies Cldr.known_currencies()

  @doc false
  @per "_per_"
  def per do
    @per
  end

  @doc false
  @currency_base "curr_"
  def currency_base do
    @currency_base
  end

  @doc """
  Parses a unit name expressed as a string and returns the parsed
  name or an error.

  ## Arguments

  * `unit_string` is a unit name (such as
    "meter") as a `String.t()`

  ## Returns

  * `{:ok, normalized_unit}` or

  * `{:error, {exception, reason}}`

  ## Notes

  A normalised unit is a `2-tuple` with
  the first element a list of standard units
  that are before the first "per" in the
  unit name.  The second element is a list
  of standard units after the first "per"
  (if any).

  The structure of the standard unit is
  `{standard_unit, conversion_to_base_unit}`.

  This function is not normally called by
  consumers of this library. It is called by
  `Cldr.Unit.validate_unit/1` which is the
  main public API.

  ## Example

      iex> Cldr.Unit.Parser.parse_unit "kilogram per light year"
      {:ok,
       {[
          {:kilogram,
           %Cldr.Unit.Conversion{
             base_unit: [:kilogram],
             factor: Ratio.new(144115188075855875, 144115188075855872),
             offset: 0
           }}
        ],
        [
          {:light_year,
           %Cldr.Unit.Conversion{
             base_unit: [:meter],
             factor: 9460730472580800,
             offset: 0
           }}
        ]}}

  """

  @spec parse_unit(String.t()) ::
          {:ok, [Unit.base_conversion()]}
          | {:ok, {[Unit.base_conversion()], [Unit.base_conversion()]}}
          | {:error, {module(), String.t()}}

  def parse_unit(unit_string) when is_binary(unit_string) do
    unit_string
    |> Cldr.Unit.normalize_unit_name()
    |> String.split(@per, parts: 2)
    |> parse_subunits()
    |> wrap(:ok)
  rescue
    e in [Cldr.UnknownUnitError, Cldr.Unit.UnknownBaseUnitError, Cldr.UnknownCurrencyError] ->
      {:error, {e.__struct__, e.message}}
  end

  def parse_unit!(unit_string) when is_binary(unit_string) do
    case parse_unit(unit_string) do
      {:ok, parsed} -> parsed
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp parse_subunits([numerator]) do
    [parse_subunit(numerator)]
  end

  defp parse_subunits([numerator, denominator]) do
    numerator =
      parse_subunit(numerator)

    denominator =
      denominator
      |> Cldr.Unit.validate_unit()
      |> reduce_subunits()

    [numerator, denominator]
  end

  defp parse_subunit(unit_string) when is_binary(unit_string) do
    unit_string
    |> split_into_units
    |> expand_power_instances()
    |> combine_power_instances()
    |> Enum.map(&resolve_base_unit/1)
    |> Enum.sort(&unit_sorter/2)
  end

  # Per TR35: https://unicode.org/reports/tr35/tr35-general.html#Unit_Identifiers

  # Multiplication binds more tightly than division, so kilogram-meter-per-second-ampere is
  # interpreted as (kg ⋅ m) / (s ⋅ a).

  # Thus if -per- occurs multiple times, each occurrence after the first is equivalent to
  # a multiplication:

  # kilogram-meter-per-second-ampere ⩧ kilogram-meter-per-second-per-ampere.

  defp reduce_subunits({:ok, name, {numerator, denominator}}) do
    (numerator ++ reduce_subunits({:ok, name, denominator}))
    |> Enum.sort(&unit_sorter/2)
  end

  defp reduce_subunits({:ok, _name, numerator}) do
    numerator
  end

  defp reduce_subunits({:error, {exception, reason}}) do
    raise exception, reason
  end

  @doc """
  Returns the canonical unit name
  for a unit

  ## Arguments

  * `unit_string` is any string representing
    a unit such as `light_year_per_week`.

  ## Returns

  * `{:ok, canonical_name}` or

  * `{:error, {exception, reason}}`

  ## Examples

      iex> Cldr.Unit.Parser.canonical_unit_name "meter"
      {:ok, :meter}

      iex> Cldr.Unit.Parser.canonical_unit_name "meter meter"
      {:ok, :square_meter}

      iex> Cldr.Unit.Parser.canonical_unit_name "meter per kilogram"
      {:ok, "meter_per_kilogram"}

      iex> Cldr.Unit.Parser.canonical_unit_name "meter kilogram"
      {:ok, "kilogram_meter"}

      iex> Cldr.Unit.Parser.canonical_unit_name "meter kilogram per fluxom"
      {:error, {Cldr.UnknownUnitError, "Unknown unit was detected at \\"fluxom\\""}}

  """
  def canonical_unit_name(unit_string) when is_binary(unit_string) do
    with {:ok, parsed} <- parse_unit(unit_string) do
      {:ok, canonical_unit_name(parsed)}
    end
  end

  def canonical_unit_name({numerator, denominator}) do
    to_string(canonical_subunit_name(numerator)) <>
      @per <>
      to_string(canonical_subunit_name(denominator))
  end

  def canonical_unit_name(numerator) do
    canonical_subunit_name(numerator)
  end

  @doc """
  Returns the canonical unit name
  for a unit or raises on error

  ## Arguments

  * `unit_string` is any string representing
    a unit such as `light_year_per_week`.

  ## Returns

  * `{:ok, canonical_name}` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Parser.canonical_unit_name! "meter"
      :meter

      iex> Cldr.Unit.Parser.canonical_unit_name! "meter meter"
      :square_meter

      iex> Cldr.Unit.Parser.canonical_unit_name! "meter per kilogram"
      "meter_per_kilogram"

      iex> Cldr.Unit.Parser.canonical_unit_name! "meter kilogram"
      "kilogram_meter"

      iex> Cldr.Unit.Parser.canonical_unit_name "curr-usd"
      {:ok, "curr_usd"}

      iex> Cldr.Unit.Parser.canonical_unit_name "curr-usd-per-kilogram"
      {:ok, "curr_usd_per_kilogram"}

      => Cldr.Unit.Parser.canonical_unit_name! "meter kilogram per fluxom"
      ** (CaseClauseError) no case clause matching: {:error,
          {Cldr.UnknownUnitError, "Unknown unit was detected at \"fluxom\""}}

  """
  def canonical_unit_name!(unit_string) when is_binary(unit_string) do
    case canonical_unit_name(unit_string) do
      {:ok, unit_name} -> unit_name
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp canonical_subunit_name([subunit]) do
    canonical_subunit_name(subunit)
  end

  defp canonical_subunit_name(subunits) when is_list(subunits) do
    subunits
    |> Enum.map(&canonical_subunit_name/1)
    |> Enum.map(&to_string/1)
    |> Enum.join("_")
  end

  defp canonical_subunit_name({currency, _}) when is_atom(currency) and currency in @currencies do
    String.downcase(@currency_base <> Atom.to_string(currency))
  end

  defp canonical_subunit_name({unit_name, _}) do
    unit_name
  end

  @unit_strings Conversions.conversions()
                |> Map.keys()
                |> Cldr.Map.stringify_values()
                |> Enum.uniq()
                |> Enum.sort(fn a, b -> String.length(a) > String.length(b) end)

  # In order to tokenize a unit string it needs to be split
  # at the boundaries of known units - after we strip
  # any SI prefixes and any power (square, cubic) prefixes.
  #
  # The process is:
  #
  # 1. Replace any aliases
  #
  # 2. Ignore "square" and "cubic" prefixes, they
  #    are just passed through for later use
  #
  # 3. For each known unit, defined as a key on
  #    the map returned by `Cldr.Unit.Conversions.conversions/0`,
  #    sorted in descending order of length so we match
  #    longest first, generate a function matching the head
  #    of the string. This will match any unit except those
  #    with an SI prefix
  #
  # 4. Match the beginning of the string to an SI prefix and
  #    then match the remaining string. Reassemble the prefix
  #    to the base unit before returning.

  defp split_into_units("") do
    []
  end

  for {unit_alias, unit} <- Alias.aliases() do
    defp split_into_units(<<unquote(to_string(unit_alias)), rest::binary>>) do
      split_into_units(unquote(to_string(unit)) <> rest)
    end
  end

  for unit <- @unit_strings do
    defp split_into_units(<<unquote(unit), rest::binary>>) do
      [unquote(unit) | split_into_units(rest)]
    end
  end

  for {prefix, _power} <- Prefix.power_units() do
    defp split_into_units(<<unquote(prefix) <> "_", rest::binary>>) do
      [unquote(prefix) | split_into_units(rest)]
    end
  end

  for {prefix, _scale} <- Prefix.si_factors() do
    defp split_into_units(<<unquote(prefix), rest::binary>>) do
      [head | rest] = split_into_units(rest)
      [unquote(prefix) <> head | rest]
    end
  end

  for {prefix, _scale} <- Prefix.binary_factors() do
    defp split_into_units(<<unquote(prefix), rest::binary>>) do
      [head | rest] = split_into_units(rest)
      [unquote(prefix) <> head | rest]
    end
  end

  defp split_into_units(<<@currency_base, currency::binary-3, rest::binary>>) do
    case Cldr.validate_currency(currency) do
      {:ok, currency} ->
        [currency | split_into_units(rest)]
      _other ->
        {exception, reason} = Cldr.unknown_currency_error(currency)
        raise exception, reason
    end
  end

  defp split_into_units(<<"_", rest::binary>>) do
    split_into_units(rest)
  end

  defp split_into_units(other) do
    case Integer.parse(other) do
      {integer, rest} when is_integer(integer) ->
        [head | rest] = split_into_units(rest)
        [{integer, head} | rest]
      _other ->
        raise Cldr.UnknownUnitError, "Unknown unit was detected at #{inspect(other)}"
    end
  end

  # In order to correctly identify the units with their
  # correct power (square or cubic) any existing power units
  # have to be expanded so that later on we can group
  # them with any single units of the same name.

  defp expand_power_instances([]) do
    []
  end

  for {prefix, power} <- Prefix.power_units() do
    defp expand_power_instances([unquote(prefix), unit | rest]) do
      List.duplicate(unit, unquote(power)) ++ expand_power_instances(rest)
    end

    defp expand_power_instances([<<unquote(prefix) <> "_" <> unit>> | rest]) do
      List.duplicate(unit, unquote(power)) ++ expand_power_instances(rest)
    end
  end

  defp expand_power_instances([unit | rest]) do
    [unit | expand_power_instances(rest)]
  end

  # Reassemble the power units by grouping and
  # combining with a square or cubic prefix
  # if there is more than one instance

  defp combine_power_instances(units) do
    units
    |> Enum.group_by(& &1)
    |> Enum.map(fn
      {k, v} when length(v) == 1 ->
        k

      {k, v} when length(v) == 2 ->
        "square_#{k}"

      {k, v} when length(v) == 3 ->
        "cubic_#{k}"

      {k, v} ->
        raise(
          Cldr.UnknownUnitError,
          "Unable to parse more than square and cubic powers. The requested unit " <>
            "would require a base unit of #{inspect(k)} to the power of #{length(v)}"
        )
    end)
  end

  # For each unit, resolve its base unit. First
  # ignore any power prefix or any SI unit prefix and then
  # look up the base unit. Afterwards take a note of any
  # scale or power that need to be abplied to the base unit
  # to reflect the power and/or SI unit.

  for {prefix, scale} <- Prefix.si_factors() do
    defp resolve_base_unit(<<unquote(prefix), base_unit::binary>> = unit) do
      with {_, conversion} <- resolve_base_unit(base_unit) do
        factor = Ratio.mult(conversion.factor, unquote(Macro.escape(scale)))
        {Unit.maybe_translatable_unit(unit), %{conversion | factor: factor}}
      else
        {:error, {exception, reason}} -> raise(exception, reason)
      end
    end
  end

  for {prefix, scale} <- Prefix.binary_factors() do
    defp resolve_base_unit(<<unquote(prefix), base_unit::binary>> = unit) do
      with {_, conversion} <- resolve_base_unit(base_unit) do
        factor = Ratio.mult(conversion.factor, unquote(Macro.escape(scale)))
        {Unit.maybe_translatable_unit(unit), %{conversion | factor: factor}}
      else
        {:error, {exception, reason}} -> raise(exception, reason)
      end
    end
  end

  for {prefix, power} <- Prefix.power_units() do
    defp resolve_base_unit(<<unquote(prefix) <> "_", subunit::binary>> = unit) do
      with {_, conversion} <- resolve_base_unit(subunit) do
        factor = Ratio.pow(conversion.factor, unquote(power))
        base_unit = [String.to_atom(unquote(prefix)) | conversion.base_unit]
        {Unit.maybe_translatable_unit(unit), %{conversion | base_unit: base_unit, factor: factor}}
      else
        {:error, {exception, reason}} -> raise(exception, reason)
      end
    end
  end

  defp resolve_base_unit(unit) when is_binary(unit) do
    with {:ok, [{_, conversion}]} <- Conversions.conversion_for(unit) do
      {Unit.maybe_translatable_unit(unit), conversion}
    else
      {:error, {exception, reason}} -> raise(exception, reason)
    end
  end

  @currencies Cldr.known_currencies()
  defp resolve_base_unit(currency) when currency in @currencies do
    {currency, %Cldr.Unit.Conversion{base_unit: [currency], factor: 1, offset: 0}}
  end

  # Integer-prefixed units like "300-gram". We process
  # them like power units (unit with a prefix)
  defp resolve_base_unit({integer, unit}) do
    {name, unit} = resolve_base_unit(unit)
    name = "#{integer}_#{name}"
    factor = Ratio.mult(unit.factor, integer)
    {name, %{unit | factor: factor}}
  end

  defp resolve_base_unit(currency) when is_atom(currency) do
    raise Cldr.UnknownCurrencyError, "The currency #{inspect currency} is unknown"
  end

  # Units are sorted in the order present in the base units
  # list. Within any base unit, SI prefixes are sorted by the
  # largest first. Therefore the sort keys may be an integer
  # for a simple unit with no prefix or a tuple with the
  # integer ranking for the unit and an integer ranking for
  # the SI prefix.

  defp unit_sorter(a, b) do
    case {unit_sort_key(a), unit_sort_key(b)} do
      {{key, order_1}, {key, order_2}} -> order_1 < order_2
      {{key_1, _order_1}, key_2} when is_integer(key_2) -> key_1 < key_2
      {key_1, {key_2, _order_2}} when is_integer(key_1) -> key_1 < key_2
      {key_1, key_2} when is_integer(key_1) and is_integer(key_2) -> key_1 < key_2
      _other -> true
    end
  end

  for {prefix, _power} <- Prefix.power_units() do
    defp unit_sort_key({<<unquote(prefix) <> "_", unit::binary>>, conversion}) do
      unit_sort_key({unit, conversion})
    end
  end

  for {prefix, order} <- Prefix.si_sort_order() do
    defp unit_sort_key({<<unquote(prefix), unit::binary>>, conversion}) do
      {unit_sort_key({unit, conversion}), unquote(order)}
    end
  end

  for {prefix, order} <- Prefix.binary_sort_order() do
    defp unit_sort_key({<<unquote(prefix), unit::binary>>, conversion}) do
      {unit_sort_key({unit, conversion}), unquote(order)}
    end
  end

  defp unit_sort_key({currency, %Conversion{base_unit: [_base_unit]}})
      when currency in @currencies do
    -1
  end

  defp unit_sort_key({_unit, %Conversion{base_unit: [base_unit]}}) do
    Map.fetch!(base_units_in_order(), base_unit)
  end

  defp unit_sort_key({_unit, %Conversion{base_unit: [_prefix, base_unit]}}) do
    Map.fetch!(base_units_in_order(), base_unit)
  end

end
