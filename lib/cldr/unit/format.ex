defmodule Cldr.Unit.Format do
  alias Cldr.Unit

  @prefix Cldr.Unit.Prefix.si_power_prefixes() |> Map.keys
  @power Cldr.Unit.Prefix.power_units() |> Enum.map(&(elem(&1, 0)))

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
    * `{:times, argument_1, argument_2}`
    * `{:prefix, prefix_name, argument}`
    * `{:power, power_name, argument}`
    * `{:per, argument_1, argument_2}`

    Where the arguments are the results returned
    from the `fun/1`.

  ## Returns

  The result returned from `fun/1`

  """
  def traverse(%Unit{base_conversion: {left, right}}, fun) when is_function(fun) do
    fun.({:per, do_traverse(left, fun), do_traverse(right, fun)})
  end

  def traverse(%Unit{base_conversion: conversion}, fun) when is_function(fun) do
    do_traverse(conversion, fun)
  end

  defp do_traverse([{unit, _}], fun) do
    do_traverse(unit, fun)
  end

  defp do_traverse([head | rest], fun) do
    fun.({:times, do_traverse(head, fun), do_traverse(rest, fun)})
  end

  defp do_traverse({unit, _}, fun) do
    do_traverse(unit, fun)
  end

  # String decomposition
  for power <- @power do
    defp do_traverse(unquote(power) <> "_" <> unit, fun) do
      fun.({:power, unquote(power), do_traverse(unit, fun)})
    end
  end

  for prefix <- @prefix do
    defp do_traverse(unquote(prefix) <> unit, fun) do
       fun.({:prefix, unquote(prefix), fun.({:unit, String.to_existing_atom(unit)})})
    end
  end

  defp do_traverse(unit, fun) when is_binary(unit) do
    fun.({:unit, String.to_existing_atom(unit)})
  end

  defp do_traverse(unit, fun) when is_atom(unit) do
    fun.({:unit, unit})
  end

end