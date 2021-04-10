require Cldr.Unit.Backend

defmodule MyApp.Cldr do
  use Cldr.Unit.Additional

  use Cldr,
    locales: ["en", "fr", "de", "bs", "af", "af-NA", "se-SE", "he", "ar"],
    default_locale: "en",
    providers: [Cldr.Number, Cldr.Unit, Cldr.List]

  unit_localization(:person, "en", :long,
    nominative: %{
      one: "{0} person",
      other: "{0} people"
    },
    display_name: "people"
  )

  unit_localization(:person, "en", :short,
    nominative: %{
      one: "{0} per",
      other: "{0} pers"
    },
    display_name: "people"
  )

  unit_localization(:person, "en", :narrow,
    nominative: %{
      one: "{0} p",
      other: "{0} p"
    },
    display_name: "p"
  )

  unit_localization(:vehicle, "en", :long,
    nominative: %{
      one: "{0} vehicle",
      other: "{0} vehicles"
    },
    display_name: "vehicles"
  )

  unit_localization(:vehicle, "en", :short,
    nominative: %{
      one: "{0} veh",
      other: "{0} veh"
    },
    display_name: "vehicles"
  )

  unit_localization(:vehicle, "en", :narrow,
    nominative: %{
      one: "{0} v",
      other: "{0} v"
    },
    display_name: "v"
  )
end

defmodule NoDocs.Cldr do
  use Cldr,
    providers: [Cldr.Number, Cldr.Unit, Cldr.List],
    generate_docs: false

  def for_dialyzer do
    Cldr.Unit.Format.to_string!(1.234, unit: :kilogram)
  end
end
