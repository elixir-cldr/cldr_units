defmodule Cldr.Unit.BaseUnit do
  @moduledoc """
  Functions to support the base unit calculations
  for a unit.

  Base unit equality is used to determine whether
  a one unit can be converted to another

  """

  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Parser
  alias Cldr.Unit.Prefix
  alias Cldr.Unit

  @per "_per_"
  @currency_base Cldr.Unit.Parser.currency_base()
  @currencies Cldr.known_currencies()

  @inverted_base_units_name Cldr.Config.units()
              |> Map.get(:base_units)
              |> Kernel.++(Cldr.Unit.Additional.base_units())
              |> Enum.uniq()
              |> Map.new()
              |> Map.values()

  @doc """
  Returns the canonical base unit name
  for a unit.

  The base unit is the common unit through which
  conversions are passed.

  ## Arguments

  * `unit_string` is any string representing
    a unit such as `light_year_per_week`.

  ## Returns

  * `{:ok, canonical_base_unit}` or

  * `{:error, {exception, reason}}`

  ## Examples

      iex> Cldr.Unit.Parser.canonical_base_unit "meter"
      {:ok, :meter}

      iex> Cldr.Unit.Parser.canonical_base_unit "meter meter"
      {:ok, :square_meter}

      iex> Cldr.Unit.Parser.canonical_base_unit "meter per kilogram"
      {:ok, "meter_per_kilogram"}

      iex> Cldr.Unit.Parser.canonical_base_unit "yottagram per mile scandinavian"
      {:ok, "kilogram_per_meter"}

  """
  def canonical_base_unit(unit) when is_binary(unit) do
    with {:ok, parsed} <- Parser.parse_unit(unit) do
      canonical_base_unit(parsed)
    end
  end

  # A "per" unit
  def canonical_base_unit({numerator, denominator}) do
    with numerator <- do_canonical_base_unit(numerator),
         denominator <- do_canonical_base_unit(denominator) do
      {numerator, denominator}
      |> merge_unit_names()
      |> sort_base_units()
      |> reduce_powers()
      |> reduce_factors()
      |> flatten_and_stringify()
      |> Unit.maybe_translatable_unit()
      |> wrap(:ok)
    end
  end

  # A list of conversions
  def canonical_base_unit(numerator) do
    numerator
    |> do_canonical_base_unit()
    |> flatten_and_stringify()
    |> Unit.maybe_translatable_unit()
    |> wrap(:ok)
  end

  @doc """
  Returns the canonical base unit name
  for a unit.

  The base unit is the common unit through which
  conversions are passed.

  ## Arguments

  * `unit_string` is any string representing
    a unit such as `light_year_per_week`.

  ## Returns

  * `canonical_base_unit` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Parser.canonical_base_unit! "meter"
      :meter

      iex> Cldr.Unit.Parser.canonical_base_unit! "meter meter"
      :square_meter

      iex> Cldr.Unit.Parser.canonical_base_unit! "meter per kilogram"
      "meter_per_kilogram"

      iex> Cldr.Unit.Parser.canonical_base_unit! "yottagram per mile scandinavian"
      "kilogram_per_meter"

  """
  def canonical_base_unit!(unit) do
    case canonical_base_unit(unit) do
      {:ok, unit_name} -> unit_name
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  def do_canonical_base_unit(numerator) when is_list(numerator) do
    numerator
    |> Enum.map(&canonical_base_subunit/1)
    |> resolve_unit_names()
    |> sort_base_units()
    |> reduce_powers()
    |> reduce_factors()
  end

  defp canonical_base_subunit({currency, _conversion}) when currency in @currencies do
    [String.downcase(@currency_base <> to_string(currency))]
  end

  defp canonical_base_subunit({_unit_name, %Conversion{base_unit: base_units}}) do
    base_units
    |> parse_base_units()
    |> extract_unit_names()
  end

  defp canonical_base_subunit(subunit) do
    subunit
    |> parse_base_units()
    |> extract_unit_names()
  end

  defp parse_base_units([prefix, unit]) do
    [[prefix, parse_base_units([unit])]]
  end

  defp parse_base_units([unit]) do
    unit
    |> to_string
    |> Cldr.Unit.normalize_unit_name()
    |> Parser.parse_unit!()
  end

  # Base units are either
  #   A {numerator, denominator} tuple
  #   A list of {unit, base_unit} tuples

  defp extract_unit_names({numerator, denominator}) do
    {extract_keys(numerator), extract_keys(denominator)}
  end

  defp extract_unit_names(numerator) do
    extract_keys(numerator)
  end

  # Extract the base units from the conversion
  # And simplify base units (ie unwrap them)
  defp extract_keys(list) do
    Enum.map(list, fn
      [prefix, conversion] ->
        [prefix, hd(extract_keys(conversion))]

      {_unit, conversion} ->
        conversion
        |> Map.fetch!(:base_unit)
        |> case do
          [unit] -> unit
          [prefix, unit] -> [prefix, unit]
        end
    end)
  end

  # Merge all list elements, starting with the first
  # two until the end of the list

  defp resolve_unit_names([first]) do
    first
  end

  defp resolve_unit_names([first, second | rest]) do
    resolve_unit_names([merge_unit_names(first, second) | rest])
  end

  # Take two list elements and merge them noting that either
  # element might be a "per tuple" represented by a tuple
  defp merge_unit_names({numerator_a, denominator_a}, {numerator_b, denominator_b}) do
    {merge_unit_names(numerator_a, numerator_b), merge_unit_names(denominator_a, denominator_b)}
  end

  defp merge_unit_names({numerator_a, denominator_a}, numerator_b) do
    {merge_unit_names(numerator_a, numerator_b), denominator_a}
  end

  defp merge_unit_names(numerator_a, {numerator_b, denominator_b}) do
    {merge_unit_names(numerator_a, numerator_b), denominator_b}
  end

  defp merge_unit_names(numerator_a, numerator_b) do
    numerator_a ++ numerator_b
  end

  # Final pass for "per" base units
  defp merge_unit_names({{_numerator_a, _denominator_a}, {_numerator_b, _denominator_b}}) do
    raise ArgumentError, "unexpected"
  end

  defp merge_unit_names({{numerator_a, denominator_a}, numerator_b}) do
    {numerator_a, merge_unit_names(numerator_b, denominator_a)}
  end

  defp merge_unit_names({numerator_a, {numerator_b, denominator_b}}) do
    {merge_unit_names(numerator_a, denominator_b), numerator_b}
  end

  defp merge_unit_names(other) do
    other
  end

  # Sort the units in canonical order
  defp sort_base_units({numerator, denominator}) do
    {Enum.sort(numerator, &base_unit_sorter/2), Enum.sort(denominator, &base_unit_sorter/2)}
  end

  defp sort_base_units(numerator) do
    Enum.sort(numerator, &base_unit_sorter/2)
  end

  # Relies on base units only ever being a single unit
  # or a list with two elements being a prefix and a unit except
  # for a currency unit in which case it will be a binary of the
  # form `curr-usd` by the time we get here.  And currency forms
  # always sort at the head of the list.

  defp base_unit_sorter(unit_a, unit_b) when is_atom(unit_a) and is_atom(unit_b) do
    Map.fetch!(base_units_in_order(), unit_a) < Map.fetch!(base_units_in_order(), unit_b)
  end

  defp base_unit_sorter(unit_a, [_prefix, unit_b]) when is_atom(unit_a) do
    Map.fetch!(base_units_in_order(), unit_a) < Map.fetch!(base_units_in_order(), unit_b)
  end

  defp base_unit_sorter([_prefix, unit_a], unit_b) when is_atom(unit_b) do
    Map.fetch!(base_units_in_order(), unit_a) < Map.fetch!(base_units_in_order(), unit_b)
  end

  defp base_unit_sorter([_prefix_a, unit_a], [_prefix_b, unit_b]) do
    Map.fetch!(base_units_in_order(), unit_a) < Map.fetch!(base_units_in_order(), unit_b)
  end

  defp base_unit_sorter(@currency_base <> _currency, _) do
    true
  end

  defp base_unit_sorter(_, @currency_base <> _currency) do
    false
  end

  # Compare 2 base unit names and return a comparison :eq, :lt, :gt.
  # Order is determined by the canonical order of units defined by CLDR
  # returned by base_units_in_order/0.

  defp compare([_power_1, unit_1], [_power_2, unit_2]) do
    compare(unit_1, unit_2)
  end

  defp compare([_power_1, unit_1], unit_2) do
    compare(unit_1, unit_2)
  end

  defp compare(unit_1, [_power_2, unit_2]) do
    compare(unit_1, unit_2)
  end

  defp compare(unit_1, unit_2) when is_atom(unit_1) and is_atom(unit_2) do
    order_1 = Map.fetch!(base_units_in_order(), unit_1)
    order_2 = Map.fetch!(base_units_in_order(), unit_2)

    cond do
      order_1 > order_2 -> :gt
      order_1 < order_2 -> :lt
      order_1 == order_2 -> :eq
    end
  end

  # Reduce factors. When its a "per" unit then
  # we reduce the common factors.
  # This is important to ensure that base unit
  # comparisons work correctly across different units
  # of the same type.

  @doc false
  def reduce_factors(list) when is_list(list) do
    list
  end

  def reduce_factors({numerator, denominator}) do
    str_numerator = flatten_and_stringify(numerator)
    str_denominator = flatten_and_stringify(denominator)

    if is_base_unit(str_numerator) || is_base_unit(str_denominator) do
      {numerator, denominator}
    else
      do_reduce_factors({numerator, denominator})
    end
  end

  def do_reduce_factors({[], denominator}) do
    {[], denominator}
  end

  def do_reduce_factors({numerator, []}) do
    {numerator, []}
  end

  # Numerator and denominator cancel each other
  def do_reduce_factors({[unit | rest_1], [unit | rest_2]}) do
    do_reduce_factors({rest_1, rest_2})
  end

  # When we have the same unit, but one of them is raised to a
  # power, we can reduce the power by one. This is true in both directions.
  def do_reduce_factors({[[power, unit] | rest_1], [unit | rest_2]}) do
    sub_unit = subtract_power([power, unit], 1)
    do_reduce_factors({[sub_unit | rest_1], rest_2})
  end

  def do_reduce_factors({[unit | rest_1], [[power, unit] | rest_2]}) do
    sub_unit = subtract_power([power, unit], 1)
    do_reduce_factors({rest_1, [sub_unit | rest_2]})
  end

  # Both units have powers so we subtract the denominator from the
  # numerator.
  def do_reduce_factors({[[power_1, unit] | rest_1], [[power_2, unit] | rest_2]}) do
    {sub_unit_1, sub_unit_2} = subtract_power([power_1, unit], [power_2, unit])
    do_reduce_factors({[sub_unit_1 | rest_1], [sub_unit_2 | rest_2]})
  end

  # We still have to check for embedded power units like :square_meter
  # which can be reduced against :meter.

  def do_reduce_factors({[unit_1 | rest_1], [unit_2 | rest_2]}) do
    {name_1, power_1} = Conversion.name_and_power(unit_1)
    {name_2, power_2} = Conversion.name_and_power(unit_2)

    if name_1 == name_2 do
      cond do
        # if they are the same power then omit both
        power_1 == power_2 ->
          do_reduce_factors({rest_1, rest_2})

        power_1 > power_2 ->
          power_1 = power_1 - power_2
          [new_unit] = Conversion.base_unit(name_1, power_1)
          do_reduce_factors({[new_unit | rest_1], rest_2})

        power_1 < power_2 ->
          power_2 = power_2 - power_1
          [new_unit] = Conversion.base_unit(name_1, power_2)
          do_reduce_factors({rest_1, [new_unit | rest_2]})
      end
    else
      cond do
        compare(unit_1, unit_2) == :lt ->
          {reduced_1, reduced_2} = do_reduce_factors({rest_1, [unit_2 | rest_2]})
          {[unit_1 | reduced_1], reduced_2}

        compare(unit_1, unit_2) == :gt ->
          {reduced_1, reduced_2} = do_reduce_factors({[unit_1 | rest_1], rest_2})
          {reduced_1, [unit_2 | reduced_2]}
      end
    end
  end

  defp is_base_unit(unit) do
    maybe_base_unit = String.to_existing_atom(unit)
    maybe_base_unit in @inverted_base_units_name
  rescue ArgumentError ->
    false
  end

  # Reduce powers where possible. For example
  # :meter and :meter to :square_meter and
  # :square_meter and :square_meter to [:pow4, :meter]

  defp reduce_powers({numerator, denominator}) do
    {reduce_powers(numerator), reduce_powers(denominator)}
  end

  defp reduce_powers([]) do
    []
  end

  defp reduce_powers([first]) do
    [first]
  end

  defp reduce_powers([first, first | rest]) do
    reduce_powers([[:square, first] | rest])
  end

  defp reduce_powers([[:square, first], first | rest]) do
    reduce_powers([[:cubic, first] | rest])
  end

  defp reduce_powers([first, [:square, first] | rest]) do
    reduce_powers([[:cubic, first] | rest])
  end

  defp reduce_powers([first, second | rest]) do
    {base_name_1, power_1} = Conversion.name_and_power(first)
    {base_name_2, power_2} = Conversion.name_and_power(second)

    if base_name_1 == base_name_2 do
      power = power_1 + power_2
      Conversion.base_unit(base_name_1, power)
    else
      [first | reduce_powers([second | rest])]
    end
  end

  # Flaten the list and turn it into a string.

  defp flatten_and_stringify({[], denominator}) do
    flatten_and_stringify(denominator)
  end

  defp flatten_and_stringify({numerator, []}) do
    flatten_and_stringify(numerator)
  end

  defp flatten_and_stringify({numerator, denominator}) do
    flatten_and_stringify(numerator) <> @per <> flatten_and_stringify(denominator)
  end

  defp flatten_and_stringify(numerator) do
    numerator
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.join("_")
  end

  # We wrap in a tuple since a nested list can
  # create ambiguous processing in other places

  @doc false
  def wrap([numerator, denominator], tag) do
    {tag, {numerator, denominator}}
  end

  def wrap([numerator], tag) do
    {tag, numerator}
  end

  def wrap(other, tag) do
    {tag, other}
  end

  @units Cldr.Config.units()
  @base_units @units[:base_units]

  @base_units_in_order @base_units
                       |> Cldr.Unit.Additional.merge_base_units()
                       |> Enum.map(&elem(&1, 1))
                       |> Enum.with_index()
                       |> Map.new()

  @doc false
  def base_units_in_order do
    @base_units_in_order
  end

  defp subtract_power([power, unit], number) when is_number(number) do
    exponent = Prefix.power_units()[power] - number
    power = Prefix.inverse_power_units()[exponent]

    if exponent == 1, do: unit, else: [power, unit]
  end

  defp subtract_power([pow_1, unit], [pow_2, unit]) do
    exp_1 = Prefix.power_units()[pow_1]
    exp_2 = Prefix.power_units()[pow_2]
    min = min(exp_1, exp_2)

    new_exp_1 = exp_1 - min
    new_exp_2 = exp_2 - min

    new_unit_1 = if new_exp_1 == 1, do: unit, else: [new_exp_1, unit]
    new_unit_2 = if new_exp_2 == 1, do: unit, else: [new_exp_2, unit]

    {new_unit_1, new_unit_2}
  end
end
