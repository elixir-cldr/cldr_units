defmodule Cldr.Unit.Preference do
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
    that includes `use Cldr`. The default is `Cldr.default_backend/0`

  * `options` is a keyword list of options or a
    `Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ## Options

  * `:usage` is the unit usage. for example `;person` for a unit
    of type `:length`. The available usage for a given unit category can
    be seen with `Cldr.Config.unit_preferences/0`. The default is `nil`.

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
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :person
      {:ok, [:inch], []}
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :person
      {:ok, [:centimeter], []}
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :road
      {:ok, [:foot], [round_nearest: 10]}
      iex> Cldr.Unit.Preference.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :road
      {:ok, [:meter], [round_nearest: 10]}

  ## Notes

  One common pattern is to convert a given unit into the unit
  appropriate for a given local and usage. This can be
  accomplished with a combination of `Cldr.Unit.Conversion.preferred_units/2`
  and `Cldr.Unit.decompose/2`. For example:

      iex> meter = Cldr.Unit.new!(:meter, 1)
      iex> preferred_units = Cldr.Unit.Preference.preferred_units(meter, MyApp.Cldr, locale: "en-US", usage: :person)
      iex> with {:ok, preferred_units, _} <- preferred_units do
      ...>   Cldr.Unit.decompose(meter, preferred_units)
      ...> end
      [Cldr.Unit.new!(:inch, Ratio.new(216172782113783808, 5490788665690109))]

  """
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
    {:ok, category} = Unit.unit_category(unit)
    {:ok, base_unit} = Conversion.convert_to_base_unit(unit)

    with {:ok, usage} <- validate_usage(category, usage) do
      usage = usage_chain(usage, :default)
      geq = Unit.value(base_unit) |> Ratio.to_float
      preferred_units(category, usage, territory_chain, geq)
    end
  end

  # TODO precompute usage chains
  # This isn't great that we're convering
  # stuff backwards and forwaard. We should
  # precompute the usage chains.
  def usage_chain(unit, default) when is_atom(unit) do
    unit
    |> Atom.to_string
    |> String.split("_")
    |> usage_chain
    |> Enum.reverse
    |> Enum.map(&String.to_atom/1)
    |> Kernel.++([default])
  end

  def usage_chain([head]) do
    [head]
  end

  def usage_chain([head | [next | tail]]) do
    [head | usage_chain([head <> "_" <> next | tail])]
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
    that includes `use Cldr`. The default is `Cldr.default_backend/0`

  * `options` is a keyword list of options or a
    `Cldr.Unit.Conversion.Options` struct. The default
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
    to the unit category.  See `Cldr.Unit.unit_preferences/0`.

  ## Returns

  * `unit_list` or

  * raises an exception

  ## Note

  This function, unline `Cldr.Unit.preferred_units/3` does not
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
  def preferred_units!(unit, backend, options \\ []) do
    case preferred_units(unit, backend, options) do
      {:ok, preferred_units, _} -> preferred_units
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp validate_preference_options(backend, options) when is_list(options) do
    options
    |> Keyword.put(:backend, backend)
    |> validate_preference_options
  end

  defp validate_preference_options(options) when is_list(options) do
    backend = Keyword.get_lazy(options, :backend, &Cldr.default_backend/0)
    locale = Keyword.get_lazy(options, :locale, &backend.get_locale/0)
    usage = Keyword.get(options, :usage, :default)

    with {:ok, locale} <- backend.validate_locale(locale),
         territory = Keyword.get_lazy(options, :territory,
           fn -> Cldr.Locale.territory_from_locale(locale) end),
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

  # And it we get here is't game over
  def preferred_units(category, usage, region, value) do
    {:error, unknown_preferences_error(category, usage, region, value)}
  end

  def debug(category, usage, region, value) do
    IO.inspect("""
    Category: #{inspect category} with usage #{inspect usage} for
    region #{inspect region} and value #{inspect value}
    """
    |> String.replace("\n"," "))
  end

  def debug(category, usage, region, value, geq) do
    IO.inspect("""
    Preference: #{inspect category} with usage #{inspect usage} for
    region #{inspect region} and value #{inspect value} with >= #{inspect geq}
    """
    |> String.replace("\n"," "))
  end

  def unknown_preferences_error(category, usage, regions, value) do
    {
      Cldr.Unit.UnknownUnitPreferenceError,
      "No preferences found for #{inspect category} " <>
      "with usage #{inspect usage} " <>
      "for region #{inspect regions} and " <>
      "value #{inspect value}"
    }
  end

  def unknown_usage_error(category, usage) do
    {
      Cldr.Unit.UnknownUsageError,
      "The unit category #{inspect category} does not define a usage #{inspect usage}"
    }
  end
end