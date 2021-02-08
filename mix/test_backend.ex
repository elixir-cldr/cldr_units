require Cldr.Unit.Backend

defmodule MyApp.Cldr do
  use Cldr.Unit.Additional

  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]

  unit_localization(:person, "en", :long,
    one: "{0} person",
    other: "{0} people",
    display_name: "people"
  )

  unit_localization(:person, "en", :short,
    one: "{0} per",
    other: "{0} pers",
    display_name: "people"
  )

  unit_localization(:person, "en", :narrow,
    one: "{0} p",
    other: "{0} p",
    display_name: "p"
  )

end

defmodule NoDocs.Cldr do
  use Cldr,
    providers: [Cldr.Number, Cldr.Unit, Cldr.List],
    generate_docs: false

  def for_dialyzer do
    Cldr.Unit.to_string!(1.234, unit: :kilogram)
  end
end
