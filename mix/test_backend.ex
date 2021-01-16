require Cldr.Unit.Backend

defmodule MyApp.Cldr do
  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List],
    unit_providers: Cldr.Unit.Transport
end

defmodule NoDocs.Cldr do
  use Cldr,
    providers: [Cldr.Number, Cldr.Unit, Cldr.List],
    generate_docs: false

  def for_dialyzer do
    Cldr.Unit.to_string!(1.234, unit: :kilogram)
  end
end
