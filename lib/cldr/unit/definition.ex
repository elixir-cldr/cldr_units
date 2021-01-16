defmodule Cldr.Unit.Definition do
  @moduledoc """
  Defines the behaviour required to add a new
  unit definition.

  Note that a definition module is used only
  at compile time to add a new custom unit.
  """

  alias Cldr.Unit
  alias Cldr.Unit.Conversion
  alias Cldr.Locale

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
  @type template :: String.t

  @typedoc """
  The definition of a unit.

  A unit is defined as a map with
  four required elements:

  * `:unit_name` is the name of the
    unit defined as a string or an atom

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

  """
  @type definition ::
    %{
      unit_name: Unit.unit(),
      base_unit: Unit.unit(),
      factor: Conversion.factor(),
      offset: Conversion.offset()
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

end