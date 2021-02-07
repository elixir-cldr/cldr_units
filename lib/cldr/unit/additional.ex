defmodule Cldr.Unit.Additional do
  @moduledoc """
  Supports the configuration of additional units
  not defined by CLDR
  """

  def conversions do
    Application.get_env(:ex_cldr_units, :additional_units, [])
    |> Enum.map(fn {k, v} -> {k, Keyword.put_new(v, :sort_before, :none)} end)
  end

  # Merge base units
  def merge_base_units(core_base_units) do
    additional_base_units =
      orderable_base_units()
      |> Enum.reject(fn {k, _v} -> Keyword.has_key?(core_base_units, k) end)

    merge_base_units(core_base_units, additional_base_units)
  end

  def merge_base_units(core_base_units, additional_base_units, acc \\ [])

  # Insert units at the head
  def merge_base_units(core_base_units, [{k, :all} | rest], acc) do
    merge_base_units(core_base_units, rest, [{k, k} | acc])
  end

  # Insert units at the tail. Since the additional units are sorted
  # we can guarantee that when we hit one with :none we can just take
  # everything left
  def merge_base_units(core_base_units, [{_k, :none} | _rest] = additional, acc) do
    tail_base_units = Enum.map(additional, fn {k, _v} -> {k, k} end)
    acc ++ core_base_units ++ tail_base_units
  end

  def merge_base_units(core_base_units, [], acc) do
    acc ++ core_base_units
  end

  def merge_base_units([], additional, acc) do
    tail_base_units = Enum.map(additional, fn {k, _v} -> {k, k} end)
    acc ++ tail_base_units
  end

  def merge_base_units([{k1, v1} = head | other], additional, acc) do
    case Keyword.pop(additional, k1) do
      {nil, _rest} -> merge_base_units(other, additional, acc ++ [head])
      {{v2, _}, rest} -> merge_base_units(other, rest, acc ++ [{v2, v2}, {k1, v1}])
    end
  end

  def base_units do
    conversions()
    |> Enum.map(fn {_k, v} -> {v[:base_unit], v[:base_unit]} end)
    |> Enum.uniq
    |> Keyword.new
  end

  def orderable_base_units do
    conversions()
    |> Enum.sort(fn {_k1, v1}, {_k2, v2} ->
      cond do
        Keyword.get(v1, :sort_before) == :all -> true
        Keyword.get(v1, :sort_before) == :none -> false
        Keyword.get(v1, :sort_before) < Keyword.get(v2, :sort_before)
      end
    end)
    |> Keyword.values
    |> Enum.map(&{&1[:base_unit], &1[:sort_before]})
    |> Enum.uniq
    |> Keyword.new
  end

end