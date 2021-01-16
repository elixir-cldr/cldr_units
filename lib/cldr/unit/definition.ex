defmodule Cldr.Unit.Definition do
  @moduledoc """
  Defines the behaviour required to add a new
  unit definition.

  Note that a definition module is used only
  at compile time to add a new custom unit.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Cldr.Unit.Definition
      @before_compile Cldr.Unit.Definition
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def localize(_locale, _style) do
        :error
      end
    end
  end

  alias Cldr.{Config, Unit, Locale}
  alias Cldr.Unit.Conversion

  @typedoc """
  Defines a localisation string template.

  A template is string with a placeholder.
  Placeholders are of the format `{0}` where
  the `0` is the value being substituted.

  For units there is typically only one
  substituation, the value of the unit. This
  is the case for the localisation templates
  for the keys `:one`, `:two`, `:few`, `:many`
  and `:other`. In this case, the shorthand
  `#` can be used as a synonym for `{0}`.

  The `:per_unit_pattern` is used when localising
  compound units and therefore it is required
  to contain two placeholders: `{0}` and `{1}`.

  Parsing of templates is performed by
  `Cldr.Substitution.parse/1`.

  """
  @type template :: String.t()

  @typedoc """


  """
  @type system_of_measurement :: :metric | :ussystem | :uksystem

  @typedoc """
  The definition of a unit.

  A unit is defined as a 2-tuple with the
  first elements being the unit name and the
  second element being a map of
  four required elements:

  * `:base_unit` is the name of the
    base unit. For example, if you are
    defining a unit of type `length`
    then the base unit is `:meter`. Base
    units can be identified by calling
    `Cldr.Unit.base_unit/1`.

  * `:factor` is the factor applied to
    the newly defined unit to convert it
    to the base unit.

  * `:offset` is added to the unit
    after it is converted to the base unit.

  * `:systems` is a list of systems of measurement
    to which this unit applies. The valid list
    elements are `:metric`, `:uksystem`, `:ussystem`

  There are no defaults and all map entries must
  be defined.

  """
  @type definition ::
          {
            name :: Unit.unit(),
            %{
              base_unit: Unit.unit(),
              factor: Conversion.factor(),
              offset: Conversion.offset(),
              systems: list(system_of_measurement())
            }
          }

  @typedoc """
  Defines the localisation templates
  for the unit.

  Localised templates are expected
  for each locale defined in a backend
  and is required for the backend default
  locale.

  Each localization is a map that defines
  a template for each of the pluralization
  categories defined by CLDR.

  All categories are optional except
  `:other` which is required.

  """
  @type localization ::
          %{
            optional(:zero) => template(),
            optional(:one) => template(),
            optional(:two) => template(),
            optional(:few) => template(),
            optional(:many) => template(),
            required(:other) => template(),
            optional(:per_unit_pattern) => template()
          }

  @doc """
  Defines a new unit
  """
  @callback define() :: definition()

  @doc """
  Defines the localisations for the unit

  A definition for at least the default
  locale in use for a backend is required.

  The `localize/2` function will be called for
  each locale name defined in a backend. It will
  be called for each locale and each unit style
  combination.

  The styles are `:narrow`, `:short` and `:long`.

  """
  @callback localize(Locale.locale_name(), style :: Unit.style()) :: localization()

  @doc false
  def additional_units(%Config{unit_providers: nil}) do
    []
  end

  def additional_units(%Config{unit_providers: provider} = config) when is_atom(provider) do
    additional_units(%{config | unit_providers: [provider]})
  end

  def additional_units(%Config{unit_providers: providers}) when is_list(providers) do
    providers
    |> Enum.map(& &1.define/0)
  end

  @doc false
  def additional_localizations(%Config{unit_providers: nil}) do
    []
  end

  def additional_localizations(%Config{unit_providers: provider} = config) when is_atom(provider) do
    additional_localizations(%{config | unit_providers: [provider]})
  end

  def additional_localizations(%Config{unit_providers: providers, locales: locales})
      when is_list(providers) do
    for provider <- providers, locale <- locales, style <- Cldr.Unit.styles() do
      {locale, style, provider.localize(locale, style)}
    end
    |> Enum.reject(& elem(&1, 2) == :error)
  end
end
