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

    traverse(unit, fn
      {:unit, unit} ->
        {:compound, unit}

      # For :per we return a tuple which is
      # a consistent representation. Each element
      # is a list.
      {:per, {left, right}} when is_list(left) and is_list(right) ->
        {left, right}

      {:per, {left, {_, right}}} when is_list(left) ->
        {left, [{features.per[1], right}]}

      {:per, {{_, left}, right}} when is_list(right) ->
        {[{features.per[0], left}], right}

      {:per, {{_, left}, {_, right}}} ->
        {[{features.per[0], left}], [{features.per[1], right}]}

      # :times will always have a unit as the
      # `left`, and a unit or a list as the `right`

      # If the `right` is a list then its a `:times`
      # in which case there is no transform to apply
      # and all locales are marked as `:compound` anyway.
      {:times, {left, right}} when is_list(left) and is_list(right) ->
        left ++ right

      {:times, {{_, left}, right}} when is_list(right) ->
        [{features.times[0], left} | right]

      {:times, {left, {_, right}}} when is_list(left) ->
        left ++ [{features.times[1], right}]

      {:times, {{_, left}, {_, right}}} ->
        [{features.times[0], left}, {features.times[1], right}]

      # :power will always have a unit as the
      # `left`, and a unit or a prefix as the `right`

      # If the `right` is a list then its a `:times`
      # in which case there is no transform to apply
      # and all locales are marked as `:compound` anyway.
      {:power, {{_, left}, right}} when is_list(right) ->
        [{features.power[0], left} | right]

      {:power, {{_, left}, {_, right}}} ->
        [{features.power[0], left}, {features.power[1], right}]

      # :prefix can only have a prefix and
      # a unit so apply the transform to both
      {:prefix, {{_, left}, {_, right}}} ->
        [{features.prefix[0], left}, {features.prefix[1], right}]
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
  def traverse(%Unit{base_conversion: {left, right}}, fun) when is_function(fun) do
    fun.({:per, {do_traverse(left, fun), do_traverse(right, fun)}})
  end

  def traverse(%Unit{base_conversion: conversion}, fun) when is_function(fun) do
    do_traverse(conversion, fun)
  end

  defp do_traverse([{unit, _}], fun) do
    do_traverse(unit, fun)
  end

  defp do_traverse([head | rest], fun) do
    fun.({:times, {do_traverse(head, fun), do_traverse(rest, fun)}})
  end

  defp do_traverse({unit, _}, fun) do
    do_traverse(unit, fun)
  end

  # String decomposition
  for {power, exp} <- @power do
    power_unit = String.to_existing_atom("power#{exp}")
    defp do_traverse(unquote(power) <> "_" <> unit, fun) do
      fun.({:power, {fun.({:unit, unquote(power_unit)}), do_traverse(unit, fun)}})
    end
  end

  for {prefix, exp} <- @prefix do
    prefix_unit = String.to_existing_atom("10p#{exp}" |> String.replace("-", "_"))
    defp do_traverse(unquote(prefix) <> unit, fun) do
      fun.({:prefix, {fun.({:unit, unquote(prefix_unit)}), fun.({:unit, String.to_existing_atom(unit)})}})
    end
  end

  defp do_traverse(unit, fun) when is_binary(unit) do
    fun.({:unit, String.to_existing_atom(unit)})
  end

  defp do_traverse(unit, fun) when is_atom(unit) do
    fun.({:unit, unit})
  end

end