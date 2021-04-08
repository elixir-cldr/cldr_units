defimpl String.Chars, for: Cldr.Unit do
  def to_string(unit) do
    locale = Cldr.get_locale()
    Cldr.Unit.Format.to_string!(unit, locale: locale)
  end
end
