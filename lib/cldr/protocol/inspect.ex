defimpl Inspect, for: Cldr.Unit do
  def inspect(%{unit: name, value: value, usage: usage, format_options: format_options}, _opts) do
    Cldr.Unit.Inspect.format(name, value, usage, format_options)
  end
end

defimpl Inspect, for: Cldr.Unit.Range do
  def inspect(%{first: first, last: last}, _opts) do
    first = inspect(first)
    last = inspect(last)

    "Cldr.Unit.Range.new!(#{first}, #{last})"
  end
end
