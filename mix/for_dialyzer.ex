defmodule Cldr.Unit.Dialyzer do
  def display_name do
    MyApp.Cldr.Unit.display_name(:kilogram)
    MyApp.Cldr.Unit.display_name(Cldr.Unit.new!(:foot, 1))

    Cldr.Unit.display_name(:kilogram, backend: MyApp.Cldr)
    Cldr.Unit.display_name(Cldr.Unit.new!(:foot, 1), backend: MyApp.Cldr)
  end
end