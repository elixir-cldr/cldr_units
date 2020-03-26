defmodule Cldr.Unit.Preference do

  @doc """
  Returns a list of the preferred units for a given
  unit, locale, use case and scope.

  The units used to represent length, volume and so on
  depend on a given territory, measurement system and usage.

  For example, in the US, people height is most commonly
  referred to in `inches`, or informally as `feet and inches`.
  In most of the rest of the world it is `centimeters`.

  ### Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `backend` is any Cldr backend module. That is, any module
    that includes `use Cldr`. The default is `Cldr.default_backend/0`

  * `options` is a keyword list of options or a
    `Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ### Options

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

  ### Returns

  * `{:ok, unit_list}` or

  * `{:error, {exception, reason}}`

  ### Examples

      iex> meter = Cldr.Unit.new :meter, 1
      #Unit<:meter, 1>
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :person, alt: :informal
      {:ok, [:foot, :inch]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :person
      {:ok, [:inch]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :person
      {:ok, [:centimeter]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-US", usage: :road
      {:ok, [:mile]}
      iex> Cldr.Unit.Conversion.preferred_units meter, MyApp.Cldr, locale: "en-AU", usage: :road
      {:ok, [:kilometer]}

  ### Notes

  One common pattern is to convert a given unit into the unit
  appropriate for a given local and usage. This can be
  accomplished with a combination of `Cldr.Unit.Conversion.preferred_units/2`
  and `Cldr.Unit.decompose/2`. For example:

      iex> meter = Cldr.Unit.new(:meter, 1)
      iex> with {:ok, preferred_units} <- Cldr.Unit.preferred_units(meter, MyApp.Cldr, locale: "en-US", usage: :person, alt: :informal) do
      ...>   Cldr.Unit.decompose(meter, preferred_units)
      ...> end
      [Cldr.Unit.new(:foot, 3), Cldr.Unit.new(:inch, 3)]

  """
  def preferred_units(unit, backend, options \\ [])

  def preferred_units(%Unit{} = unit, options, []) when is_list(options) do
    preferred_units(unit, Cldr.default_backend(), options)
  end

  def preferred_units(%Unit{} = unit, backend, options) when is_list(options) do
    preferred_units(unit, backend, struct(Cldr.Unit.Conversion.Options, options))
  end

  @default_territory :"001"
  def preferred_units(%Unit{} = unit, backend, %Options{} = options) do
    %{usage: usage, scope: scope, alt: alt, locale: locale} = options

    with {:ok, locale} <- backend.validate_locale(locale || backend.get_locale()) do
      # TODO territory should also conside the -u-rd flag
      territory = atomize(locale.territory)
      category = Unit.unit_category(unit.unit)
      preferences = Cldr.Unit.unit_preferences()

      preferred_units =
        get_in(preferences, [category, usage, scope, alt, territory]) ||
        get_in(preferences, [category, usage, scope, territory]) ||
        get_in(preferences, [category, usage, alt, territory]) ||
        get_in(preferences, [category, usage, territory]) ||

        get_in(preferences, [category, usage, scope, alt, @default_territory]) ||
        get_in(preferences, [category, usage, scope, @default_territory]) ||
        get_in(preferences, [category, usage, alt, @default_territory]) ||
        get_in(preferences, [category, usage, @default_territory]) ||
        [unit.unit]

      {:ok, preferred_units}
    end
  end

  @doc """
  Returns a list of the preferred units for a given
  unit, locale, use case and scope.

  The units used to represent length, volume and so on
  depend on a given territory, measurement system and usage.

  For example, in the US, people height is most commonly
  referred to in `inches`, or informally as `feet and inches`.
  In most of the rest of the world it is `centimeters`.

  ### Arguments

  * `unit` is any unit returned by `Cldr.Unit.new/2`.

  * `backend` is any Cldr backend module. That is, any module
    that includes `use Cldr`. The default is `Cldr.default_backend/0`

  * `options` is a keyword list of options or a
    `Cldr.Unit.Conversion.Options` struct. The default
    is `[]`.

  ### Options

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

  ### Returns

  * `unit_list` or

  * raises an exception

  ### Examples

      iex> meter = Cldr.Unit.new :meter, 1
      #Unit<:meter, 1>
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :person, alt: :informal
      [:foot, :inch]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :person
      [:inch]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-AU", usage: :person
      [:centimeter]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-US", usage: :road
      [:mile]
      iex> Cldr.Unit.Conversion.preferred_units! meter, MyApp.Cldr, locale: "en-AU", usage: :road
      [:kilometer]

  """
  def preferred_units!(unit, backend, options \\ []) do
    case preferred_units(unit, backend, options) do
      {:ok, preferred_units} -> preferred_units
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defp atomize(string) do
    String.to_existing_atom(string)
  rescue ArgumentError ->
    :"001"
  end

  def to_decimal(%Ratio{numerator: numerator, denominator: denominator}) do
    Decimal.new(numerator)
    |> Decimal.div(Decimal.new(denominator))
  end

  def to_decimal(number) when is_integer(number) do
    Decimal.new(number)
  end

  @global :"001"
  defp find_preference(nil, usage, _territory, _scope, _style) do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "No known unit preference for usage #{inspect(usage)}"}}
  end

  defp find_preference(preferences, _usage, territory, nil, nil) do
    {:ok, Map.get(preferences, territory) || Map.get(preferences, @global)}
  end

  defp find_preference(preferences, usage, territory, :small, nil) do
    {:ok,
     get_in(preferences, [:small, territory]) || get_in(preferences, [:small, @global]) ||
       find_preference(usage, preferences, territory, nil, nil)}
  end

  defp find_preference(preferences, usage, territory, nil, :informal) do
    {:ok,
     get_in(preferences, [:informal, territory]) || get_in(preferences, [:informal, @global]) ||
       find_preference(usage, preferences, territory, nil, nil)}
  end

  defp find_preference(preferences, usage, territory, :small, :informal) do
    {:ok,
     get_in(preferences, [:small, :informal, territory]) ||
       get_in(preferences, [:small, :informal, @global]) ||
       get_in(preferences, [:informal, territory]) ||
       get_in(preferences, [:informal, @global]) ||
       find_preference(usage, preferences, territory, nil, nil)}
  end

  defp find_preference(_preferences, _usage, _territory, scope, style)
       when scope in [:small, nil] do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "Style #{inspect(style)} is not known. It should be :informal or nil"}}
  end

  defp find_preference(_preferences, _usage, _territory, scope, style)
       when style in [:informal, nil] do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "Scope #{inspect(scope)} is not known. It should be :small or nil"}}
  end

  defp find_preference(_preferences, _usage, _territory, scope, style) do
    {:error,
     {Cldr.Unit.UnknownUnitPreferenceError,
      "No known scope #{inspect(scope)} and no known style #{inspect(style)}"}}
  end

  defp int_rem(unit) do
    integer = Unit.round(unit, 0, :down) |> Math.trunc()
    remainder = Math.sub(unit, integer)
    {integer, remainder}
  end

end