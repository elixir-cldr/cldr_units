defmodule Cldr.Unit.Format do
  alias Cldr.Unit

  @type grammar ::
          {Unit.translatable_unit(),
           {Unit.grammatical_case(), Cldr.Number.PluralRule.plural_type()}}

  @type grammar_list :: [grammar, ...]

  @doc """
  Traverses the components of a unit
  and resolves a list of base units with
  their gramatical case and plural selector
  definitions for a given locale.

  This function relies upon the internal
  representation of units and grammatical features
  and is primarily for the support of
  formatting a function through `Cldr.Unit.to_string/2`.

  ## Arguments

  * `unit` is a `t:Cldr.Unit` or a binary
    unit string

  ## Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `t:Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  ## Returns

  ## Examples

  """
  @doc since: "3.5.0"
  @spec grammar(Unit.t(), Keyword.t()) :: grammar_list() | {grammar_list(), grammar_list()}

  def grammar(unit, options \\ [])

  def grammar(%Unit{} = unit, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    module = Module.concat(backend, :Unit)

    features =
      module.grammatical_features("root")
      |> Map.merge(module.grammatical_features(locale))

    gcase = Map.fetch!(features, :case)
    plural = Map.fetch!(features, :plural)

    traverse(unit, &grammar(&1, gcase, plural, options))
  end

  def grammar(unit, options) when is_binary(unit) do
    grammar(Unit.new!(1, unit), options)
  end

  defp grammar({:unit, unit}, _gcase, _plural, _options) do
    {unit, {:compound, :compound}}
  end

  defp grammar({:per, {left, right}}, _gcase, _plural, _options)
       when is_list(left) and is_list(right) do
    {left, right}
  end

  defp grammar({:per, {left, {right, _}}}, gcase, plural, _options) when is_list(left) do
    {left, [{right, {gcase.per[1], plural.per[1]}}]}
  end

  defp grammar({:per, {{left, _}, right}}, gcase, plural, _options) when is_list(right) do
    {[{left, {gcase.per[0], plural.per[0]}}], right}
  end

  defp grammar({:per, {{left, _}, {right, _}}}, gcase, plural, _options) do
    {[{left, {gcase.per[0], plural.per[0]}}], [{right, {gcase.per[1], plural.per[1]}}]}
  end

  defp grammar({:times, {left, right}}, _gcase, _plural, _options)
       when is_list(left) and is_list(right) do
    left ++ right
  end

  defp grammar({:times, {{left, _}, right}}, gcase, plural, _options) when is_list(right) do
    [{left, {gcase.times[0], plural.times[0]}} | right]
  end

  defp grammar({:times, {left, {right, _}}}, gcase, plural, _options) when is_list(left) do
    left ++ [{right, {gcase.times[1], plural.times[1]}}]
  end

  defp grammar({:times, {{left, _}, {right, _}}}, gcase, plural, _options) do
    [{left, {gcase.times[0], plural.times[0]}}, {right, {gcase.times[1], plural.times[1]}}]
  end

  defp grammar({:power, {{left, _}, right}}, gcase, plural, _options) when is_list(right) do
    [{left, {gcase.power[0], plural.power[0]}} | right]
  end

  defp grammar({:power, {{left, _}, {right, _}}}, gcase, plural, _options) do
    [{left, {gcase.power[0], plural.power[0]}}, {right, {gcase.power[1], plural.power[1]}}]
  end

  defp grammar({:prefix, {{left, _}, {right, _}}}, gcase, plural, _options) do
    [{left, {gcase.prefix[0], plural.prefix[0]}}, {right, {gcase.prefix[1], plural.prefix[1]}}]
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
    * `{:prefix, {prefix_unit, argument}}`
    * `{:power, {power_unit, argument}}`
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

  @si_prefix Cldr.Unit.Prefix.si_power_prefixes()
  @power Cldr.Unit.Prefix.power_units() |> Map.new()

  # String decomposition
  for {power, exp} <- @power do
    power_unit = String.to_existing_atom("power#{exp}")

    defp do_traverse(unquote(power) <> "_" <> unit, fun) do
      fun.({:power, {fun.({:unit, unquote(power_unit)}), do_traverse(unit, fun)}})
    end
  end

  for {prefix, exp} <- @si_prefix do
    prefix_unit = String.to_existing_atom("10p#{exp}" |> String.replace("-", "_"))

    defp do_traverse(unquote(prefix) <> unit, fun) do
      fun.(
        {:prefix,
         {fun.({:unit, unquote(prefix_unit)}), fun.({:unit, String.to_existing_atom(unit)})}}
      )
    end
  end

  defp do_traverse(unit, fun) when is_binary(unit) do
    fun.({:unit, String.to_existing_atom(unit)})
  end

  defp do_traverse(unit, fun) when is_atom(unit) do
    fun.({:unit, unit})
  end
end
