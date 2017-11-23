# In test mode we compile and test all locales
use Mix.Config

config :ex_cldr,
  default_locale: "en",
  locales: ["root", "fr", "de", "zh", "en", "bs", "pl", "ru", "th", "he", "af", "af-NA"],
  gettext: Cldr.Gettext,
  precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}]

config :ex_unit,
  case_load_timeout: 220_000,
  timeout: 120_000
