defmodule Cldr.Unit.Preference do
  @moduledoc """
  In many cultures, the common unit of measure for some
  unit categories varies based upon the usage of the
  unit.

  For example, when describing unit length in the US, the
  common use units vary based upon usage such as:

  * road distance (miles for larger distances, feet for smaller)
  * person height (feet and inches)
  * snowfall (inches)

  This module provides functions to introspect CLDRs
  preference data for difference use cases in different
  locales.

  """

  alias Cldr.Unit
  alias Cldr.Unit.Conversion
  alias Cldr.Unit.Conversion.Options

  @doc """
  Returns a list of the preferred units for a given
  unit, locale, territory and use case.

  The units used to represent length, volume and so on
  depend on a given territory, measurement system and usage.

  For example, in the US, people height is most commonly
  referred to in `inches`, or informally as `feet and inches`.
  In most of the rest of the world it is `centimeters`.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `backend` is any Cldr backend module. That is, any module
    that includes `use Cldr`. The default is `Cldr.default_backend!/0`

  * `options` is a keyword list of options or a
    `t:Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ## Options

  * `:usage` is the unit usage. for example `;person` for a unit
    of type `:length`. The available usage for a given unit category can
    be seen with `Cldr.Unit.unit_category_usage/0`. The default is `nil`.

  * `:scope` is either `:small` or `nil`. In some usage, the units
    used are different when the unit size is small. It is up to the
    developer to determine when `scope: :small` is appropriate.

  * `:alt` is either `:informal` or `nil`. Like `:scope`, the units
    in use depend on whether they are being used in a formal or informal
    context.

  * `:locale` is any locale returned by `Cldr.validate_locale/2`

  ## Returns

  * `{:ok, unit_list}` or

  * `{:error, {exception, reason}}`

  ## Examples

      iex> meter = Cldr.Unit.new!(:meter, 1)
      iex> many_meters = Cldr.Unit.new!(:meter, 10_000)
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :person
      {:ok, [:inch], []}
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :person
      {:ok, [:centimeter], []}
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :road
      {:ok, [:foot], [round_nearest: 1]}
      iex> Cldr.Unit.Preference.preferred_units many_meters, MyApp.Cldr, locale: "en-US", usage: :road
      {:ok, [:mile], []}
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :road
      {:ok, [:meter], [round_nearest: 1]}
      iex> Cldr.Unit.Preference.preferred_units many_meters, MyApp.Cldr, locale: "en-AU", usage: :road
      {:ok, [:kilometer], []}

  ## Notes

  One common pattern is to convert a given unit into the unit
  appropriate for a given locale and usage. This can be
  accomplished with a combination of `Cldr.Unit.Preference.preferred_units/3`
  and `Cldr.Unit.decompose/2`. For example:

      iex> meter = Cldr.Unit.new!(:meter, 1)
      iex> preferred_units = Cldr.Unit.Preference.preferred_units(meter,
      ...>   MyApp.Cldr, locale: "en-US", usage: :person)
      iex> with {:ok, preferred_units, _} <- preferred_units do
      ...>   Cldr.Unit.decompose(meter, preferred_units)
      ...> end
      [Cldr.Unit.new!(:inch, Ratio.new(216172782113783808, 5490788665690109))]

  """
  @spec preferred_units(Cldr.Unit.t(), Cldr.backend() | Keyword.t(), Keyword.t() | Options.t()) ::
    {:ok, [atom(), ...], Keyword.t()} | {:error, {module, binary}}

  def preferred_units(unit, backend, options \\ [])

  def preferred_units(%Unit{} = unit, options, []) when is_list(options) do
    with {:ok, options} <- validate_preference_options(options) do
      preferred_units(unit, options.backend, options)
    end
  end

  def preferred_units(%Unit{} = unit, backend, options) when is_list(options) do
    options = Keyword.put_new(options, :usage, unit.usage)

    with {:ok, options} <- validate_preference_options(backend, options) do
      preferred_units(unit, backend, options)
    end
  end

  def preferred_units(%Unit{} = unit, _backend, %Options{} = options) do
    %{usage: usage, territory: territory} = options
    {:ok, territory_chain} = Cldr.territory_chain(territory)
    {:ok, category} = unit_preference_category(unit)
    {:ok, base_unit} = Conversion.convert_to_base_unit(unit)

    with {:ok, usage} <- validate_usage(category, usage) do
      usage = usage_chain(usage)
      geq = Unit.value(base_unit) |> to_float()
      preferred_units(category, usage, territory_chain, geq)
    end
  end

  @doc false

  @spec unit_preference_category(Unit.t() | String.t() | atom()) ::
          {:ok, Unit.category()} | {:error, {module(), String.t()}}

  def unit_preference_category(unit) do
    with {:ok, _unit, conversion} <- Unit.validate_unit(unit) do
      unit_preference_category(unit, conversion)
    end
  end

  @doc false
  def unit_preference_category(unit, conversion) do
    with {:ok, base_unit} <- Unit.BaseUnit.canonical_base_unit(conversion),
         {:ok, category} <- Map.fetch(Unit.base_unit_category_map(), Kernel.to_string(base_unit)) do
      {:ok, category}
    else
      :error -> {:error, Unit.unknown_category_error(unit)}
      other -> other
    end
  end

  @doc """
  Returns a list of the preferred units for a given
  unit, locale, territory and use case.

  The units used to represent length, volume and so on
  depend on a given territory, measurement system and usage.

  For example, in the US, people height is most commonly
  referred to in `inches`, or `feet and inches`.
  In most of the rest of the world it is `centimeters`.

  ## Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `backend` is any Cldr backend module. That is, any module
    that includes `use Cldr`. The default is `Cldr.default_backend!/0`

  * `options` is a keyword list of options or a
    `t:Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ## Options

  * `:locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct.  The default is `backend.get_locale/0`

  * `:territory` is any valid territory code returned by
    `Cldr.known_territories/0`. The default is the territory defined
    as part of the `:locale`. The option `:territory` has a precedence
    over the territory in a locale.

  * `:usage` is the way in which the unit is intended
    to be used.  The available `usage` varyies according
    to the unit category.  See `Cldr.Unit.unit_category_usage/0`.

  ## Returns

  * `unit_list` or

  * raises an exception

  ## Note

  This function, unlike `Cldr.Unit.preferred_units/3` does not
  return any available formatting hints.

  ## Examples

      iex> meter = Cldr.Unit.new!(:meter, 1)
      iex> Cldr.Unit.Preference.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :person_height
      [:foot, :inch]
      iex> Cldr.Unit.Preference.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :person
      [:inch]
      iex> Cldr.Unit.Preference.preferred_units! meter, MyApp.Cldr, locale: "en-AU", usage: :person
      [:centimeter]
      iex> Cldr.Unit.Preference.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :road
      [:foot]
      iex> Cldr.Unit.Preference.preferred_units! meter, MyApp.Cldr, locale: "en-AU", usage: :road
      [:meter]

  """
  @spec preferred_units!(Cldr.Unit.t(), Cldr.backend() | Keyword.t(), Keyword.t() | Options.t()) ::
    [atom(), ...] | no_return()

  def preferred_units!(unit, backend, options \\ []) do
    case preferred_units(unit, backend, options) do
      {:ok, preferred_units, _} -> preferred_units
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  # Rounding matches the number we used
  # to generate the function clauses

  @rounding Cldr.Unit.rounding()

  defp to_float(%Ratio{} = value) do
    Ratio.to_float(value)
    |> Cldr.Math.round(@rounding)
  end

  defp to_float(%Decimal{} = value) do
    Decimal.to_float(value)
    |> Cldr.Math.round(@rounding)
  end

  defp to_float(other) do
    other
  end

  defp usage_chain(usage) when is_atom(usage) do
    usage_chain()
    |> Map.fetch!(usage)
  end

  # TR35 says that for a given usage, if it
  # can't be found, split it at the last
  # "_", take the head of the split and try
  # again. Repeat until the usage is found or
  # there is nothing more to try.
  #
  # The following precomputes these "usage chains"
  # by taking each known usage and breaking it
  # down as required by TR36.

  @usage_chain Cldr.Unit.unit_category_usage()
               |> Enum.map(fn {_category, usage} ->
                 Enum.map(usage, fn use ->
                   chain =
                     use
                     |> Atom.to_string()
                     |> String.split("_")
                     |> Cldr.Enum.combine_list()
                     |> Enum.map(&String.to_atom/1)
                     |> List.insert_at(0, :default)
                     |> Enum.reverse()

                   {use, chain}
                 end)
               end)
               |> List.flatten()
               |> Map.new()

  defp usage_chain do
    @usage_chain
  end

  defp validate_preference_options(backend, options) when is_list(options) do
    options
    |> Keyword.put(:backend, backend)
    |> validate_preference_options
  end

  defp validate_preference_options(options) when is_list(options) do
    backend = Keyword.get_lazy(options, :backend, &Cldr.Unit.default_backend/0)
    locale = Keyword.get_lazy(options, :locale, &backend.get_locale/0)
    usage = Keyword.get(options, :usage, :default)

    with {:ok, locale} <- backend.validate_locale(locale),
         territory =
           Keyword.get_lazy(options, :territory, fn ->
             Cldr.Locale.territory_from_locale(locale)
           end),
         {:ok, territory} <- Cldr.validate_territory(territory) do
      options = [locale: locale, territory: territory, usage: usage, backend: backend]
      {:ok, struct(Options, options)}
    end
  end

  def validate_usage(category, usage) do
    if get_in(Unit.unit_preferences(), [category, usage]) do
      {:ok, usage}
    else
      {:error, unknown_usage_error(category, usage)}
    end
  end

  for {category, usages} <- Unit.unit_preferences() do
    for {usage, preferences} <- usages do
      for preference <- preferences do
        %{geq: geq, regions: regions, units: units, skeleton: skeleton} = preference

        if geq == 0 do
          def preferred_units(unquote(category), unquote(usage), region, _value)
              when is_atom(region) and region in unquote(regions) do
            # debug(unquote(category), unquote(usage), region, value, 0)
            {:ok, unquote(units), unquote(skeleton)}
          end
        else
          def preferred_units(unquote(category), unquote(usage), region, value)
              when is_atom(region) and region in unquote(regions) and value >= unquote(geq) do
            # debug(unquote(category), unquote(usage), region, value, unquote(geq))
            {:ok, unquote(units), unquote(skeleton)}
          end
        end
      end
    end
  end

  # First we process the potential usage we were offered
  def preferred_units(category, [usage], region, value) do
    # debug(category, usage, region, value)
    preferred_units(category, usage, region, value)
  end

  def preferred_units(category, [usage | other_usage], region, value) do
    # debug(category, usage, region, value)
    case preferred_units(category, usage, region, value) do
      {:ok, units, skeleton} -> {:ok, units, skeleton}
      _other -> preferred_units(category, other_usage, region, value)
    end
  end

  # Second we walk the territory chain with the usage
  # we were provided
  def preferred_units(category, usage, [region], value) do
    # debug(category, usage, region, value)
    preferred_units(category, usage, region, value)
  end

  def preferred_units(category, usage, [region | other_regions], value) do
    # debug(category, usage, region, value)
    case preferred_units(category, usage, region, value) do
      {:ok, units, skeleton} -> {:ok, units, skeleton}
      _other -> preferred_units(category, usage, other_regions, value)
    end
  end

  # If we get here then try with the default case
  # Which should basically always work
  # def preferred_units(category, usage, region, value) when usage != :default do
  #  preferred_units(category, :default, region, value)
  # end

  # And it we get here it's game over
  def preferred_units(category, usage, region, value) do
    {:error, unknown_preferences_error(category, usage, region, value)}
  end

  # defp debug(category, usage, region, value) do
  #   IO.inspect(
  #     """
  #     Category: #{inspect(category)} with usage #{inspect(usage)} for
  #     region #{inspect(region)} and value #{inspect(value)}
  #     """
  #     |> String.replace("\n", " ")
  #   )
  # end
  #
  # defp debug(category, usage, region, value, geq) do
  #   IO.inspect(
  #     """
  #     Preference: #{inspect(category)} with usage #{inspect(usage)} for
  #     region #{inspect(region)} and value #{inspect(value)} with >= #{inspect(geq)}
  #     """
  #     |> String.replace("\n", " ")
  #   )
  # end

  def unknown_preferences_error(category, usage, regions, value) do
    {
      Cldr.Unit.UnknownUnitPreferenceError,
      "No preferences found for #{inspect(category)} " <>
        "with usage #{inspect(usage)} " <>
        "for region #{inspect(regions)} and " <>
        "value #{inspect(value)}"
    }
  end

  def unknown_usage_error(category, usage) do
    {
      Cldr.Unit.UnknownUsageError,
      "The unit category #{inspect(category)} does not define a usage #{inspect(usage)}"
    }
  end
end
