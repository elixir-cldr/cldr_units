unit = Cldr.Unit.new!("millimeter per cubic fathom", 3)

Benchee.run(
  %{
    "Old version" => fn -> Cldr.Unit.to_string(unit) end,
    "New version" => fn -> Cldr.Unit.Format.to_string(unit) end
  },
  time: 10,
  memory_time: 2
)