defmodule Cldr.Unit.AdditionalUnitTest do
  use ExUnit.Case

  describe "Additional units" do
    test "Cldr.Unit.new/2" do
      assert {:ok, _} = Cldr.Unit.new(:vehicle, 1)
      assert {:ok, _} = Cldr.Unit.new(:person, 1)
      assert {:ok, _} = Cldr.Unit.new(:vehicle_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:person_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:vehicle_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:milliperson_kilometer, 1)
      assert {:ok, _} = Cldr.Unit.new(:square_person_kilometer, 1)
    end

    test "Cldr.Unit.Format.to_string/2" do
      assert Cldr.Unit.Format.to_string(Cldr.Unit.new!(:vehicle, 1)) == {:ok, "1 vehicle"}
      assert Cldr.Unit.Format.to_string(Cldr.Unit.new!(:vehicle, 2)) == {:ok, "2 vehicles"}
    end
  end
end
