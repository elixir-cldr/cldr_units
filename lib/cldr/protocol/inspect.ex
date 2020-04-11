defimpl Inspect, for: Cldr.Unit do
  def inspect(%{unit: name, value: value}, _opts) do
    "#Cldr.Unit<#{inspect(name)}, #{inspect(value)}>"
  end
end
