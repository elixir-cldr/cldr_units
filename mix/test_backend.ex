defmodule TestBackend.Cldr do
  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]

end