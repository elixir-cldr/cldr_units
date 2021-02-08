defmodule Cldr.Unit.Additional do
  @moduledoc false

  # Supports the configuration of additional units
  # not defined by CLDR. These functions are only used a compile time.

  defmacro __using__(_opts) do
    module = __CALLER__.module

    quote do
      @before_compile Cldr.Unit.Additional
      import Cldr.Unit.Additional
      Module.register_attribute(unquote(module), :custom_localizations, accumulate: true)
    end
  end

  defmacro __before_compile__(_ast) do
    caller = __CALLER__.module
    target_module = Module.concat(caller, Unit.Additional)

    caller
    |> Module.get_attribute(:custom_localizations)
    |> Cldr.Unit.Additional.group_localizations()
    |> Cldr.Unit.Additional.define_localization_module(target_module)
  end

  defmacro unit_localization(unit, locale, style, localizations) do
    module = __CALLER__.module
    {localizations, _} = Code.eval_quoted(localizations)
    localization = Cldr.Unit.Additional.validate_localization!(unit, locale, style, localizations)

    quote do
      Module.put_attribute(
        unquote(module),
        :custom_localizations,
        unquote(Macro.escape(localization))
      )
    end
  end

  @doc false
  def define_localization_module(localizations, module) do
    quote bind_quoted: [module: module, localizations: Macro.escape(localizations)] do
      defmodule module do
        for {locale, styles} <- localizations do
          for {style, formats} <- styles do
            def units_for(unquote(locale), unquote(style)) do
              unquote(Macro.escape(formats))
            end
          end
        end

        def units_for(locale, style) do
          %{}
        end
      end
    end
  end

  @doc false
  def group_localizations(localizations) when is_list(localizations) do
    localizations
    |> Enum.group_by(
      fn localization -> localization.locale end,
      fn localization -> Map.take(localization, [:style, :unit, :localizations]) end
    )
    |> Enum.map(fn {locale, rest} ->
      value =
        Enum.group_by(
          rest,
          fn localization -> localization.style end,
          fn localization -> {localization.unit, parse(localization.localizations)} end
        )
        |> Enum.map(fn {style, list} -> {style, Map.new(list)} end)

      {locale, Map.new(value)}
    end)
    |> Map.new()
  end

  defp parse(localizations) do
    Enum.map(localizations, fn
      {:display_name, name} -> {:display_name, name}
      {key, value} -> {key, Cldr.Substitution.parse(value)}
    end)
    |> Map.new()
  end

  @doc false
  def validate_localization!(unit, locale, style, localizations) do
    unless is_atom(unit) do
      raise ArgumentError, "Unit name must be an atom. Found #{inspect(unit)}"
    end

    unless style in [:short, :long, :narrow] do
      raise ArgumentError, "Style must be one of :short, :long or :narrow. Found #{inspect(style)}"
    end

    unless is_binary(locale) do
      raise ArgumentError, "Locale name must be a string. Found #{inspect(locale)}"
    end

    unless Keyword.keyword?(localizations) do
      raise ArgumentError, "Localizations must be a keyword list. Found #{inspect(localizations)}"
    end

    unless Keyword.has_key?(localizations, :other) do
      raise ArgumentError, "Localizations must have an :other key"
    end

    unless Keyword.has_key?(localizations, :display_name) do
      raise ArgumentError, "Localizations must have a :display_name key"
    end

    %{unit: unit, locale: locale, style: style, localizations: localizations}
  end

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

  def merge_base_units([{k1, _v1} = head | other] = core_base_units, additional, acc) do
    case Keyword.pop(additional, k1) do
      {nil, _rest} -> merge_base_units(other, additional, acc ++ [head])
      {{v2, _}, rest} -> merge_base_units(core_base_units, rest, acc ++ [{v2, v2}])
    end
  end

  def base_units do
    conversions()
    |> Enum.map(fn {_k, v} -> {v[:base_unit], v[:base_unit]} end)
    |> Enum.uniq()
    |> Keyword.new()
  end

  def orderable_base_units do
    conversions()
    |> Enum.sort(fn {_k1, v1}, {_k2, v2} ->
      cond do
        Keyword.get(v1, :sort_before) == :all ->
          true

        Keyword.get(v1, :sort_before) == :none ->
          false
          Keyword.get(v1, :sort_before) < Keyword.get(v2, :sort_before)
      end
    end)
    |> Keyword.values()
    |> Enum.map(&{&1[:base_unit], &1[:sort_before]})
    |> Enum.uniq()
    |> Keyword.new()
  end
end
