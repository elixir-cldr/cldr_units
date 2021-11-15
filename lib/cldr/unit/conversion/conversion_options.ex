defmodule Cldr.Unit.Conversion.Options do
  @moduledoc """
  Options structure for unit conversions
  """

  @type t :: %__MODULE__{
    usage: atom(),
    locale: Cldr.LanguageTag.t(),
    backend: Cldr.backend(),
    territory: Cldr.Locale.territory()
  }

  defstruct usage: nil, locale: nil, backend: nil, territory: nil

end
