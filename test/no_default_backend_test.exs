defmodule Cldr.Unit.NoDefaultBackendTest do
  # Not async: this test nils the global :ex_cldr, :default_backend application
  # env for its duration, which would race any concurrent async test that reads
  # the default backend. Isolated in its own sync module so the rest of the
  # suite can stay async.
  use ExUnit.Case, async: false

  test "Format a unit when there is no default backend" do
    default = Application.get_env(:ex_cldr, :default_backend)
    Application.put_env(:ex_cldr, :default_backend, nil)
    on_exit(fn -> Application.put_env(:ex_cldr, :default_backend, default) end)

    assert MyApp.Cldr.Unit.to_string!(7.3, unit: :kilogram) == "7.3 kilograms"
  end
end
