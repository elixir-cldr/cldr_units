defmodule Cldr.CanConvertUnitsTest do
  use ExUnit.Case
  import Cldr.Unit.Conversion

  @cldr37_data [
    :inch_ofhg, :pound_force_foot, :liter_per_100_kilometer,
    :meter_per_square_second, :permillion, :millimeter_ofhg,
    :pound_force_per_square_inch
  ]

  for unit <- Cldr.Unit.units(), unit not in @cldr37_data do
    category = Cldr.Unit.unit_category(unit)
    conversion = get_in(direct_factors(), [unit]) || get_in(factors(), [category, unit])

    test "#{inspect unit} has a conversion metric" do
      assert unquote(Macro.escape(conversion))
    end
  end

end