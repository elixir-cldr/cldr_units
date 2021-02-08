defmodule Cldr.Unit.AdditionalUnitTest do
  use ExUnit.Case

  describe "Additional units" do
    test "Cldr.Unit.new/2" do
      assert {:ok, _} = Cldr.Unit.new(:vehicle_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:person_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:vehicle_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:milliperson_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:square_person_kilometer, 1)
    end
  end
end
