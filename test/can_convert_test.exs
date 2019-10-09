defmodule Cldr.CanConvertUnitsTest do
  use ExUnit.Case
  import Cldr.Unit.Conversion

  for unit <- Cldr.Unit.units() do
    category = Cldr.Unit.unit_category(unit)
    conversion = get_in(direct_factors(), [unit]) || get_in(factors(), [category, unit])

    test "#{inspect unit} has a conversion metric" do
      assert unquote(Macro.escape(conversion))
    end
  end

end