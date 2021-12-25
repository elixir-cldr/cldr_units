import Config

config :ex_unit,
  case_load_timeout: 220_000,
  timeout: 120_000

config :ex_cldr,
  default_backend: MyApp.Cldr

config :ex_cldr_units, :additional_units,
  vehicle: [
    base_unit: :unit,
    factor: 1,
    offset: 0,
    sort_before: :all
  ],
  person: [
    base_unit: :unit,
    factor: 1,
    offset: 0,
    sort_before: :all
  ],
  quarter: [
    base_unit: :year,
    factor: %{numerator: 1, denominator: 4},
    offset: 0,
    sort_before: :all,
  ]
