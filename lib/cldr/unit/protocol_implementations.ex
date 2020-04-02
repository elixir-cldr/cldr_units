defimpl String.Chars, for: Cldr.Unit do
  def to_string(unit) do
    Cldr.Unit.to_string!(unit, Cldr.default_backend())
  end
end

defimpl Inspect, for: Cldr.Unit do
  def inspect(%{unit: name, value: value}, _opts) do
    "#Cldr.Unit<#{inspect(name)}, #{inspect(value)}>"
  end
end
