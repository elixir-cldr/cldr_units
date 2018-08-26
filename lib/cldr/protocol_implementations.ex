defimpl String.Chars, for: Cldr.Unit do
  def to_string(unit) do
    Cldr.Unit.to_string(unit)
  end
end

defimpl Inspect, for: Cldr.Unit do
  def inspect(unit, _opts) do
    "#Unit<#{inspect(unit.unit)}, #{inspect(unit.value)}>"
  end
end
