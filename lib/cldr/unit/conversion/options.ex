defmodule Cldr.Unit.Conversion.Options do
  @moduledoc """
  Options structure for unit conversions
  """

  alias Cldr.{Locale, LanguageTag}

  @type t :: %__MODULE__{
    usage: atom(),
    locale: LanguageTag.t(),
    backend: Cldr.backend(),
    territory: Locale.territory_code()
  }

  defstruct usage: nil, locale: nil, backend: nil, territory: nil

end
