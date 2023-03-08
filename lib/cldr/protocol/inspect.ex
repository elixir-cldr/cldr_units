defimpl Inspect, for: Cldr.Unit do
  def inspect(%{unit: name, value: value, usage: usage, format_options: format_options}, _opts) do
    Cldr.Unit.Inspect.format(name, value, usage, format_options)
  end
end
