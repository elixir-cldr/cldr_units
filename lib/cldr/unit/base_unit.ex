defmodule Cldr.Unit.BaseUnit do
  @moduledoc """
  Functions to support the base unit calculations
  for a unit.

  Base unit equality is used to determine whether
  a one unit can be converted to another

  """

  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Parser
  alias Cldr.Unit

  @per "_per_"
  @currency_base Cldr.Unit.Parser.currency_base()
  @currencies Cldr.known_currencies()

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
      # |> reduce_factors()
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

  def do_canonical_base_unit(numerator) when is_list(numerator) do
    numerator
    |> Enum.map(&canonical_base_subunit/1)
    |> resolve_unit_names()
    |> sort_base_units()
    |> reduce_powers()
    # |> reduce_factors()
  end

  defp canonical_base_subunit({currency, _conversion}) when currency in @currencies do
    [String.downcase(@currency_base <> to_string(currency))]
  end

  defp canonical_base_subunit({_unit_name, %Conversion{base_unit: base_units}}) do
    base_units
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

  # Reduce factors. When its a "per" unit then
  # we reduce the common factors.
  # This is important to ensure that base unit
  # comparisons work correctly across different units
  # of the same type.

  # Currently not being used but in the future this
  # might be required.

  @doc false
  def reduce_factors({[], denominator}) do
    {[], denominator}
  end

  def reduce_factors({numerator, []}) do
    {numerator, []}
  end

  # Numerator and denominator cancel each other
  def reduce_factors({[unit | rest_1], [unit | rest_2]}) do
    reduce_factors({rest_1, rest_2}) #|> IO.inspect(label: "1")
  end

  def reduce_factors({[[:square, unit] | rest_1], [unit | rest_2]}) do
    reduce_factors({[unit | rest_1], rest_2}) #|> IO.inspect(label: "2")
  end

  def reduce_factors({[unit | rest_1], [[:square, unit] | rest_2]}) do
    reduce_factors({rest_1, [unit | rest_2]}) #|> IO.inspect(label: "3")
  end

  def reduce_factors({[unit | rest_1], [[:cubic, unit] | rest_2]}) do
    reduce_factors({rest_1, [[:square, unit] | rest_2]}) #|> IO.inspect(label: "4")
  end

  def reduce_factors({[[:square, unit] | rest_1], [[:square, unit] | rest_2]}) do
    reduce_factors({rest_1, rest_2}) #|> IO.inspect(label: "5")
  end

  def reduce_factors({[[:cubic, unit] | rest_1], [[:cubic, unit] | rest_2]}) do
    reduce_factors({rest_1, rest_2}) #|> IO.inspect(label: "6")
  end

  def reduce_factors({[[:cubic, unit] | rest_1], [[:square, unit] | rest_2]}) do
    reduce_factors({[unit | rest_1], rest_2}) #|> IO.inspect(label: "7")
  end

  def reduce_factors({[[:cubic, unit] | rest_1], [unit | rest_2]}) do
    reduce_factors({[[:square, unit] | rest_1], rest_2}) #|> IO.inspect(label: "8")
  end

  def reduce_factors({[unit_1 | rest_1], rest_2}) do
    {numerator, denominator} = reduce_factors({rest_1, rest_2})
    {[unit_1 | numerator], denominator} #|> IO.inspect(label: "9")
  end

  def reduce_factors(other) do
    other #|> IO.inspect(label: "Other")
  end

  # Reduce powers to square and cubic
  defp reduce_powers({numerator, denominator}) do
    {reduce_powers(numerator), reduce_powers(denominator)}
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

  defp reduce_powers([first | rest]) do
    [first | reduce_powers(rest)]
  end

  # Flaten the list and turn it into a string
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
  def canonical_base_unit!(unit_string) when is_binary(unit_string) do
    case canonical_base_unit(unit_string) do
      {:ok, unit_name} -> unit_name
      {:error, {exception, reason}} -> raise exception, reason
    end
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

  @base_units_in_order Cldr.Config.units()
                       |> Map.get(:base_units)
                       |> Cldr.Unit.Additional.merge_base_units()
                       |> Enum.map(&elem(&1, 1))
                       |> Enum.with_index()
                       |> Map.new()

  @doc false
  def base_units_in_order do
    @base_units_in_order
  end
end
