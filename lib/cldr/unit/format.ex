defmodule Cldr.Unit.Format do
  alias Cldr.Unit

  @prefix Cldr.Unit.Prefix.si_power_prefixes()
  @power Cldr.Unit.Prefix.power_units() |> Map.new()

  @doc """
  Return the grammatical case for a
  unit.

  ## Arguments

  ## Options

  ## Returns

  ## Examples

  """
  @doc since: "3.5.0"
  @spec grammatical_case(Unit.t(), Keyword.t()) :: Unit.grammatical_case()

  def grammatical_case(unit, options \\ [])

  def grammatical_case(%Unit{} = unit, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    module =  Module.concat(backend, :Unit)

    features =
      module.grammatical_features("root")
      |> Map.merge(module.grammatical_features(locale))
      |> Map.fetch!(:case)

    Cldr.Unit.Format.reduce(unit, fn
      {:unit, unit} ->
        {:unit, {:compound, unit}}
      {:per, {compound, {_, left}, {_, right}}} ->
        {:per, {{features.per[0], left}, {features.per[1], right}}}
      {:times, {{_, left}, {_, right}}} ->
        {:times, {{features.times[0], left}, {features.times[1], right}}}
      {:power, {{_, left}, {_, right}}} ->
        {:power, {{features.power[0], left}, {features.power[1], right}}}
      {:prefix, {{_, left}, {_, right}}} ->
        {:prefix, {{features.prefix[0], left}, {features.prefix[1], right}}}
    end)
  end

  def grammatical_case(unit, options) when is_binary(unit) do
    grammatical_case(Unit.new!(1, unit), options)
  end

  @doc """
  Traverses a unit's decomposition and invokes
  a function on each node of the composition
  tree.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`

  * `fun` is any single-arity function. It will be invoked
    for each node of the composition tree. The argument is a tuple
    of the following form:

    * `{:unit, argument}`
    * `{:times, {argument_1, argument_2}}`
    * `{:prefix, {prefix_name, argument}}`
    * `{:power, {power_name, argument}}`
    * `{:per, {argument_1, argument_2}}`

    Where the arguments are the results returned
    from the `fun/1`.

  ## Returns

  The result returned from `fun/1`

  """
  def reduce(%Unit{base_conversion: {left, right}}, fun) when is_function(fun) do
    fun.({:per, {do_reduce(left, fun), do_reduce(right, fun)}})
  end

  def reduce(%Unit{base_conversion: conversion}, fun) when is_function(fun) do
    do_reduce(conversion, fun)
  end

  defp do_reduce([{unit, _}], fun) do
    do_reduce(unit, fun)
  end

  defp do_reduce([head | rest], fun) do
    fun.({:times, {do_reduce(head, fun), do_reduce(rest, fun)}})
  end

  defp do_reduce({unit, _}, fun) do
    do_reduce(unit, fun)
  end

  # String decomposition
  for {power, exp} <- @power do
    power_unit = String.to_existing_atom("power#{exp}")
    defp do_reduce(unquote(power) <> "_" <> unit, fun) do
      fun.({:power, {fun.({:unit, unquote(power_unit)}), do_reduce(unit, fun)}})
    end
  end

  for {prefix, exp} <- @prefix do
    prefix_unit = String.to_existing_atom("10p#{exp}" |> String.replace("-", "_"))
    defp do_reduce(unquote(prefix) <> unit, fun) do
      fun.({:prefix, {fun.({:unit, unquote(prefix_unit)}), fun.({:unit, String.to_existing_atom(unit)})}})
    end
  end

  defp do_reduce(unit, fun) when is_binary(unit) do
    fun.({:unit, String.to_existing_atom(unit)})
  end

  defp do_reduce(unit, fun) when is_atom(unit) do
    fun.({:unit, unit})
  end

end