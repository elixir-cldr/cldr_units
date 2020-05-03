defimpl Inspect, for: Cldr.Unit do
  def inspect(%{unit: name, value: value, usage: usage, format_options: format_options}, _opts) do
    options =
      if usage != :default || format_options != [] do
        ", usage: #{inspect(usage)}, format_options: #{inspect(format_options)}"
      else
        ""
      end

    "#Cldr.Unit<#{inspect(name)}, #{inspect(value)}#{options}>"
  end
end
