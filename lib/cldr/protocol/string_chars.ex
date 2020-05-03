defimpl String.Chars, for: Cldr.Unit do
  def to_string(unit) do
    locale = Cldr.get_locale()
    Cldr.Unit.to_string!(unit, locale.backend, locale: locale)
  end
end
