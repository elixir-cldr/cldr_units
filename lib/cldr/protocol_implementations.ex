defimpl String.Chars, for: Cldr.Unit do
  def to_string(unit) do
    unless default_backend = Application.get_env(:ex_cldr_units, :default_backend) do
      raise RuntimeError, "The String.Chars protocol that implements to_string/1 " <>
      "requires that a default Cldr backend be configured in config.exs or placed " <>
      "in the application environment. For example:\n\n" <>
      "config :ex_cldr_units\n  default_backend: MyApp.Cldr\n"
    end
    Cldr.Unit.to_string!(unit, default_backend)
  end
end

defimpl Inspect, for: Cldr.Unit do
  def inspect(unit, _opts) do
    "#Unit<#{inspect(unit.unit)}, #{inspect(unit.value)}>"
  end
end
