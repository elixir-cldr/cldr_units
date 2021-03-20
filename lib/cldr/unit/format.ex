defmodule Cldr.Unit.Format do
  alias Cldr.Unit

  defmacrop is_grammar(unit) do
    quote do
      is_tuple(unquote(unit))
    end
  end

  @typep grammar ::
           {Unit.translatable_unit(),
            {Unit.grammatical_case(), Cldr.Number.PluralRule.plural_type()}}

  @typep grammar_list :: [grammar, ...]

  @translatable_units Cldr.Unit.known_units()
  @si_keys Cldr.Unit.Prefix.si_keys()
  @power_keys Cldr.Unit.Prefix.power_keys()

  @default_case :nominative
  @default_style :long
  @default_plural :other

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string/3` for full details.

  """
  @spec to_string(list_or_number :: Unit.value | Unit.t() | [Unit.t()]) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    to_string(unit, backend, locale: locale)
  end

  @doc """
  Formats a number into a string according to a unit definition for a locale.

  During processing any `:format_options` of a `Unit.t()` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `list_or_number` is any number (integer, float or Decimal) or a
    `t:Cldr.Unit` struct or a list of `t:Cldr.Unit` structs

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list of options.

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `t:Cldr.Unit` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `style` is one of those returned by `Cldr.Unit.styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * `:grammatical_case` indicates that a localisation for the given
    locale and given grammatical case should be used. See `Cldr.Unit.known_grammatical_cases/0`
    for the list of known grammatical cases. Note that not all locales
    define all cases. However all locales do define the `:nominative`
    case, which is also the default.

  * `:gender` indicates that a localisation for the given
    locale and given grammatical gender should be used. See `Cldr.Unit.known_gender/0`
    for the list of known grammatical genders. Note that not all locales
    define all genders. The default gender is `Cldr.Unit.default_gender/1`
    for the given locale.

  * `:list_options` is a keyword list of options for formatting a list
    which is passed through to `Cldr.List.to_string/3`. This is only
    applicable when formatting a list of units.

  * Any other options are passed to `Cldr.Number.to_string/2`
    which is used to format the `number`

  ## Returns

  * `{:ok, formatted_string}` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:gallon, 123), MyApp.Cldr
      {:ok, "123 gallons"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:gallon, 1), MyApp.Cldr
      {:ok, "1 gallon"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:gallon, 1), MyApp.Cldr, locale: "af"
      {:ok, "1 gelling"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:gallon, 1), MyApp.Cldr, locale: "bs"
      {:ok, "1 galon"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:gallon, 1234), MyApp.Cldr, format: :long
      {:ok, "1 thousand gallons"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:gallon, 1234), MyApp.Cldr, format: :short
      {:ok, "1K gallons"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:megahertz, 1234), MyApp.Cldr
      {:ok, "1,234 megahertz"}

      iex> Cldr.Unit.Format.to_string Cldr.Unit.new!(:megahertz, 1234), MyApp.Cldr, style: :narrow
      {:ok, "1,234MHz"}

      iex> unit = Cldr.Unit.new!(123, :foot)
      iex> Cldr.Unit.Format.to_string unit, MyApp.Cldr
      {:ok, "123 feet"}

      iex> Cldr.Unit.Format.to_string 123, MyApp.Cldr, unit: :foot
      {:ok, "123 feet"}

      iex> Cldr.Unit.Format.to_string Decimal.new(123), MyApp.Cldr, unit: :foot
      {:ok, "123 feet"}

      iex> Cldr.Unit.Format.to_string 123, MyApp.Cldr, unit: :megabyte, locale: "en", style: :unknown
      {:error, {Cldr.UnknownFormatError, "The unit style :unknown is not known."}}

  """

  @spec to_string(Unit.value | Unit.t() | list(Unit.t()), Cldr.backend() | Keyword.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, {atom, binary}}

  def to_string(list_or_unit, backend, options \\ [])

  # Options but no backend
  def to_string(list_or_unit, options, []) when is_list(options) do
    locale = Cldr.get_locale()
    to_string(list_or_unit, locale.backend, options)
  end

  # It's a list of units so we format each of them
  # and combine the list
  def to_string(unit_list, backend, options) when is_list(unit_list) do
    with {locale, _style, options} <- normalize_options(backend, options),
         {:ok, locale} <- backend.validate_locale(locale) do
      options =
        options
        |> Keyword.put(:locale, locale)

      list_options =
        options
        |> Keyword.get(:list_options, [])
        |> Keyword.put(:locale, locale)

      unit_list
      |> Enum.map(&to_string!(&1, backend, options))
      |> Cldr.List.to_string(backend, list_options)
    end
  end

  # It's a number, not a unit struct
  def to_string(number, backend, options) when is_number(number) do
    with {:ok, unit} <- Cldr.Unit.new(options[:unit], number) do
      to_string(unit, backend, options)
    end
  end

  def to_string(%Decimal{} = number, backend, options) do
    with {:ok, unit} <- Cldr.Unit.new(options[:unit], number) do
      to_string(unit, backend, options)
    end
  end

  # Now we have a unit, a backend and some options but ratio
  # values need to be converted to decimals
  def to_string(%Unit{value: %Ratio{}} = unit, backend, options) when is_list(options) do
    unit = Cldr.Unit.to_decimal_unit(unit)
    to_string(unit, backend, options)
  end

  def to_string(%Unit{} = unit, backend, options) when is_list(options) do
    with {locale, _style, _options} <- normalize_options(backend, options),
         {:ok, _locale} <- backend.validate_locale(locale),
         {:ok, list} <- to_iolist(unit, Keyword.put(options, :backend, backend)) do
      list
      |> :erlang.iolist_to_binary()
      |> String.replace(~r/([\s])+/, "\\1")
      |> Cldr.Unit.wrap(:ok)
    end
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  The curent process's locale is set with
  `Cldr.put_locale/1`.

  See `Cldr.Unit.to_string!/3` for full details.

  """
  @spec to_string!(list_or_number :: Unit.value() | Unit.t() | [Unit.t()]) ::
          String.t() | no_return()

  def to_string!(unit) do
    locale = Cldr.get_locale()
    backend = locale.backend
    to_string!(unit, backend, locale: locale)
  end

  @doc """
  Formats a number into a string according to a unit definition
  for the current process's locale and backend or raises
  on error.

  During processing any `:format_options` of a `t:Cldr.Unit` are merged with
  `options` with `options` taking precedence.

  ## Arguments

  * `number` is any number (integer, float or Decimal) or a
    `t:Cldr.Unit` struct

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module. The default is `Cldr.default_backend!/0`.

  * `options` is a keyword list

  ## Options

  * `:unit` is any unit returned by `Cldr.Unit.known_units/0`. Ignored if
    the number to be formatted is a `t:Cldr.Unit` struct

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `Cldr.get_locale/0`

  * `:style` is one of those returned by `Cldr.Unit.available_styles`.
    The current styles are `:long`, `:short` and `:narrow`.
    The default is `style: :long`

  * Any other options are passed to `Cldr.Number.to_string/2`
    which is used to format the `number`

  ## Returns

  * `formatted_string` or

  * raises an exception

  ## Examples

      iex> Cldr.Unit.Format.to_string! Cldr.Unit.new!(:gallon, 123), MyApp.Cldr
      "123 gallons"

      iex> Cldr.Unit.Format.to_string! Cldr.Unit.new!(:gallon, 1), MyApp.Cldr
      "1 gallon"

      iex> Cldr.Unit.Format.to_string! Cldr.Unit.new!(:gallon, 1), MyApp.Cldr, locale: "af"
      "1 gelling"

  """
  @spec to_string!(Unit.value() | Unit.t() | list(Unit.t()), Cldr.backend() | Keyword.t(), Keyword.t()) ::
          String.t() | no_return()

  def to_string!(unit, backend, options \\ []) do
    case to_string(unit, backend, options) do
      {:ok, string} -> string
      {:error, {exception, message}} -> raise exception, message
    end
  end

  defp normalize_options(backend, options) do
    locale = Keyword.get(options, :locale, backend.get_locale())
    style = Keyword.get(options, :style, @default_style)

    options =
      options
      |> Keyword.delete(:locale)
      |> Keyword.put(:style, style)
      |> Keyword.put_new(:grammatical_case, @default_case)

    {locale, style, options}
  end

  # Direct formatting of the unit since
  # it is translatable directly
  def to_iolist(unit, options \\ [])

  def to_iolist(%Cldr.Unit{unit: name} = unit, options) when name in @translatable_units do
    {locale, backend, format, grammatical_case, gender, plural} = extract_options!(unit, options)
    formats = Cldr.Unit.units_for(locale, format, backend)
    number_format_options = Keyword.merge(unit.format_options, options)
    unit_grammar = {name, {grammatical_case, plural}}

    formatted_number = format_number!(unit, number_format_options)
    unit_pattern = get_unit_pattern!(unit_grammar, formats, grammatical_case, gender, plural)
    {:ok, Cldr.Substitution.substitute(formatted_number, unit_pattern)}
  end

  def to_iolist(%Cldr.Unit{} = unit, options) do
    {locale, backend, format, grammatical_case, gender, plural} = extract_options!(unit, options)
    formats = Cldr.Unit.units_for(locale, format, backend)
    number_format_options = Keyword.merge(unit.format_options, options)
    formatted_number = format_number!(unit, number_format_options)
    grammar = grammar(unit, locale: locale, backend: backend)

    {:ok, to_iolist(grammar, formatted_number, formats, grammatical_case, gender, plural)}
  end

  # For the numerator of a unit
  defp to_iolist(grammar, formatted_number, formats, grammatical_case, gender, plural)
      when is_list(grammar) do
    grammar
    |> to_iolist(formats, grammatical_case, gender, plural)
    |> substitute_number(formatted_number)
  end

  # For compound "per" units
  defp to_iolist({numerator, denominator}, formatted_number, formats, grammatical_case, gender, plural) do
    per_pattern =
      get_in(formats, [:per, :compound_unit_pattern])

    numerator_pattern =
      to_iolist(numerator, formatted_number, formats, grammatical_case, gender, plural)

    denominator_pattern =
      to_iolist(denominator, formats, grammatical_case, gender, plural)
      |> extract_unit

    Cldr.Substitution.substitute([numerator_pattern, denominator_pattern], per_pattern)
  end

  # Recurive processing of a unit grammar
  defp to_iolist([], _formats, _grammatical_case, _gender, _plural) do
    []
  end

  # SI Prefixes
  defp to_iolist([{si_prefix, _} | rest], formats, grammatical_case, gender, plural)
      when si_prefix in @si_keys do
    si_pattern = get_si_pattern!(formats, si_prefix, grammatical_case, gender, plural)
    rest = to_iolist(rest, formats, grammatical_case, gender, plural)
    merge_SI_prefix(si_pattern, rest)
  end

  # Power prefixes
  defp to_iolist([{power_prefix, _} | rest], formats, grammatical_case, gender, plural)
      when power_prefix in @power_keys do
    power_pattern =
      get_power_pattern!(formats, power_prefix, grammatical_case, gender, plural)

    rest =
      rest
      |> to_iolist(formats, grammatical_case, gender, plural)
      |> extract_unit

    merge_power_prefix(power_pattern, rest)
  end

  defp to_iolist([unit], formats, grammatical_case, gender, plural) when is_grammar(unit) do
    get_unit_pattern!(unit, formats, grammatical_case, gender, plural)
  end

  defp to_iolist([pattern_list], _formats, _grammatical_case, _gender, _plural) do
    pattern_list
  end

  # List head is a grammar unit
  defp to_iolist([unit | rest], formats, grammatical_case, gender, plural) when is_grammar(unit) do
    times_pattern =
      get_in(formats, [:times, :compound_unit_pattern])

    unit_pattern_1 =
      get_unit_pattern!(unit, formats, grammatical_case, gender, plural)

    unit_pattern_2 =
      to_iolist(rest, formats, grammatical_case, gender, plural)
      |> extract_unit()

    Cldr.Substitution.substitute([unit_pattern_1, unit_pattern_2], times_pattern)
  end

  # List head is a format pattern
  defp to_iolist([unit_pattern_1 | rest], formats, grammatical_case, gender, plural) do
    times_pattern =
      get_in(formats, [:times, :compound_unit_pattern])

    unit_pattern_2 =
      to_iolist(rest, formats, grammatical_case, gender, plural)
      |> extract_unit()

    Cldr.Substitution.substitute([unit_pattern_1, unit_pattern_2], times_pattern)
  end

  defp get_unit_pattern!(unit, formats, grammatical_case, gender, plural) do
    {name, {unit_case, unit_plural}} = unit
    unit_case = if unit_case == :compound, do: grammatical_case, else: unit_case
    unit_plural = if unit_plural == :compound, do: plural, else: unit_plural

    get_in(formats, [name, unit_case, unit_plural]) ||
      get_in(formats, [name, @default_case, unit_plural]) ||
      get_in(formats, [name, @default_case, @default_plural]) ||
      raise(Cldr.Unit.NoPatternError, {name, unit_case, gender, unit_plural})
  end

  defp get_si_pattern!(formats, si_prefix, grammatical_case, gender, plural) do
    get_in(formats, [si_prefix, :unit_prefix_pattern]) ||
      raise(Cldr.Unit.NoPatternError, {si_prefix, grammatical_case, gender, plural})
  end

  defp get_power_pattern!(formats, power_prefix, grammatical_case, gender, plural) do
    power_formats =
      get_in(formats, [power_prefix, :compound_unit_pattern])

    get_in(power_formats, [gender, plural, grammatical_case]) ||
      get_in(power_formats, [gender, plural]) ||
      get_in(power_formats, [plural, grammatical_case]) ||
      get_in(power_formats, [plural]) ||
      get_in(power_formats, [@default_case]) ||
      raise(Cldr.Unit.NoPatternError, {power_prefix, grammatical_case, gender, plural})
  end

  defp extract_unit([place, string]) when is_integer(place) do
    String.trim(string)
  end

  defp extract_unit([string, place]) when is_integer(place) do
    String.trim(string)
  end

  defp extract_unit([unit | rest]) do
    [extract_unit(unit) | rest]
  end

  defp extract_unit(other) do
    IO.inspect other, label: "Extract Unit"
    other
  end

  defp format_number!(unit, options) do
    number_format_options = Keyword.merge(unit.format_options, options)
    Cldr.Number.to_string!(unit.value, number_format_options)
  end

  defp substitute_number([place, unit], formatted_number) when is_integer(place) do
    Cldr.Substitution.substitute(formatted_number, [place, unit])
  end

  defp substitute_number([unit, place], formatted_number) when is_integer(place) do
    Cldr.Substitution.substitute(formatted_number, [place, unit])
  end

  defp substitute_number([head | rest], formatted_number) when is_list(rest) do
    [Cldr.Substitution.substitute(formatted_number, head) | rest]
  end


  # Merging power and SI prefixes into a pattern is a heuristic since the
  # underlying data does not convey those rules.

  @merge_SI_prefix ~r/([^\s]+)$/u
  defp merge_SI_prefix([prefix, place], [place, string]) when is_integer(place) do
    string = maybe_downcase(prefix, string)
    [place, String.replace(string, @merge_SI_prefix, "#{prefix}\\1")]
  end

  defp merge_SI_prefix([prefix, place], [string, place]) when is_integer(place) do
    string = maybe_downcase(prefix, string)
    [String.replace(string, @merge_SI_prefix, "#{prefix}\\1"), place]
  end

  defp merge_SI_prefix([place, prefix], [place, string]) when is_integer(place) do
    string = maybe_downcase(prefix, string)
    [place, String.replace(string, @merge_SI_prefix, "#{prefix}\\1")]
  end

  defp merge_SI_prefix([place, prefix], [string, place]) when is_integer(place) do
    string = maybe_downcase(prefix, string)
    [String.replace(string, @merge_SI_prefix, "#{prefix}\\1"), place]
  end

  defp merge_SI_prefix(prefix_pattern, [unit_pattern | rest]) do
    [merge_SI_prefix(prefix_pattern, unit_pattern) | rest]
  end

  @merge_power_prefix ~r/([^\s]+)/u
  defp merge_power_prefix([prefix, place], [place, string]) when is_integer(place) do
    [place, String.replace(string, @merge_power_prefix, "#{prefix}\\1")]
  end

  defp merge_power_prefix([prefix, place], [string, place]) when is_integer(place) do
    [String.replace(string, @merge_power_prefix, "#{prefix}\\1"), place]
  end

  defp merge_power_prefix([place, prefix], [place, string]) when is_integer(place) do
    [place, String.replace(string, @merge_power_prefix, "\\1#{prefix}")]
  end

  defp merge_power_prefix([place, prefix], [string, place]) when is_integer(place) do
    [String.replace(string, @merge_power_prefix, "\\1#{prefix}"), place]
  end

  defp merge_power_prefix([place, prefix], list) when is_integer(place) and is_list(list) do
    [list, prefix]
  end

  defp merge_power_prefix([prefix, place], [string | rest]) when is_integer(place) do
    string = maybe_downcase(prefix, string)
    [prefix, [string | rest]]
  end

  defp merge_power_prefix([prefix, place], string) when is_integer(place) and is_binary(string) do
    string = maybe_downcase(prefix, string)
    [prefix, string]
  end

  # If the prefix has no trailing whitespace then
  # downcase the string since it will be
  # joined adjacent to the prefix
  defp maybe_downcase(prefix, string) do
    if String.match?(prefix, ~r/\s+$/u) do
      string
    else
      String.downcase(string)
    end
  end

  defp extract_options!(unit, options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)
    unit_backend = Module.concat(backend, :Unit)

    format = Keyword.get(options, :style, @default_style)
    grammatical_case = Keyword.get(options, :grammatical_case, @default_case)
    gender = Keyword.get(options, :grammatical_gender, unit_backend.default_gender(locale))
    plural = Cldr.Number.PluralRule.plural_type(unit.value, backend, locale: locale)
    {locale, backend, format, grammatical_case, gender, plural}
  end

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

    grammatical_case = Map.fetch!(features, :case)
    plural = Map.fetch!(features, :plural)

    traverse(unit, &grammar(&1, grammatical_case, plural, options))
  end

  def grammar(unit, options) when is_binary(unit) do
    grammar(Unit.new!(1, unit), options)
  end

  defp grammar({:unit, unit}, _grammatical_case, _plural, _options) do
    {unit, {:compound, :compound}}
  end

  defp grammar({:per, {left, right}}, _grammatical_case, _plural, _options)
       when is_list(left) and is_list(right) do
    {left, right}
  end

  defp grammar({:per, {left, {right, _}}}, grammatical_case, plural, _options) when is_list(left) do
    {left, [{right, {grammatical_case.per[1], plural.per[1]}}]}
  end

  defp grammar({:per, {{left, _}, right}}, grammatical_case, plural, _options)
       when is_list(right) do
    {[{left, {grammatical_case.per[0], plural.per[0]}}], right}
  end

  defp grammar({:per, {{left, _}, {right, _}}}, grammatical_case, plural, _options) do
    {[{left, {grammatical_case.per[0], plural.per[0]}}],
     [{right, {grammatical_case.per[1], plural.per[1]}}]}
  end

  defp grammar({:times, {left, right}}, _grammatical_case, _plural, _options)
       when is_list(left) and is_list(right) do
    left ++ right
  end

  defp grammar({:times, {{left, _}, right}}, grammatical_case, plural, _options)
       when is_list(right) do
    [{left, {grammatical_case.times[0], plural.times[0]}} | right]
  end

  defp grammar({:times, {left, {right, _}}}, grammatical_case, plural, _options)
       when is_list(left) do
    left ++ [{right, {grammatical_case.times[1], plural.times[1]}}]
  end

  defp grammar({:times, {{left, _}, {right, _}}}, grammatical_case, plural, _options) do
    [
      {left, {grammatical_case.times[0], plural.times[0]}},
      {right, {grammatical_case.times[1], plural.times[1]}}
    ]
  end

  defp grammar({:power, {{left, _}, right}}, grammatical_case, plural, _options)
       when is_list(right) do
    [{left, {grammatical_case.power[0], plural.power[0]}} | right]
  end

  defp grammar({:power, {{left, _}, {right, _}}}, grammatical_case, plural, _options) do
    [
      {left, {grammatical_case.power[0], plural.power[0]}},
      {right, {grammatical_case.power[1], plural.power[1]}}
    ]
  end

  defp grammar({:prefix, {{left, _}, {right, _}}}, grammatical_case, plural, _options) do
    [
      {left, {grammatical_case.prefix[0], plural.prefix[0]}},
      {right, {grammatical_case.prefix[1], plural.prefix[1]}}
    ]
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
    power_unit = String.to_atom("power#{exp}")

    defp do_traverse(unquote(power) <> "_" <> unit, fun) do
      fun.({:power, {fun.({:unit, unquote(power_unit)}), do_traverse(unit, fun)}})
    end
  end

  for {prefix, exp} <- @si_prefix do
    prefix_unit = String.to_atom("10p#{exp}" |> String.replace("-", "_"))

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
