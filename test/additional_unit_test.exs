defmodule Cldr.Unit.AdditionalUnitTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

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

    test "Cldr.Unit.to_string/2" do
      assert Cldr.Unit.to_string(Cldr.Unit.new!(:vehicle, 1)) == {:ok, "1 vehicle"}
      assert Cldr.Unit.to_string(Cldr.Unit.new!(:vehicle, 2)) == {:ok, "2 vehicles"}
    end
  end

  describe "Configuring additional units" do
    test "Exception raised on non-keyword list bad configuration" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      Application.put_env(:ex_cldr_units, :additional_units, "invalid")

      assert_raise ArgumentError, ~r/Additional unit configuration must be a keyword list.*/, fn ->
        Cldr.Unit.Additional.conversions()
      end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end

    test "Exception raised on config is not a keyword list" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      new_config = [vehicle: "not_a_keyword_list"]

      Application.put_env(:ex_cldr_units, :additional_units, new_config)

      assert_raise ArgumentError,
                   ~r/Additional unit configuration for :vehicle must be a keyword list.*/,
                   fn ->
                     Cldr.Unit.Additional.conversions()
                   end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end

    test "Exception raised on non-atom base unit" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      new_config = [vehicle: [base_unit: "string", factor: 1, offset: 0, sort_before: :all]]

      Application.put_env(:ex_cldr_units, :additional_units, new_config)

      assert_raise ArgumentError, ~r/Additional unit :base_unit must be an atom.*/, fn ->
        Cldr.Unit.Additional.conversions()
      end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end

    test "Exception raised on no factor" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      new_config = [vehicle: [base_unit: :unit]]

      Application.put_env(:ex_cldr_units, :additional_units, new_config)

      assert_raise ArgumentError,
                   ~r/Additional unit configuration must have a :factor configured/,
                   fn ->
                     Cldr.Unit.Additional.conversions()
                   end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end

    test "Factor is not a number of rational" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      new_config = [vehicle: [base_unit: :unit, factor: "string"]]

      Application.put_env(:ex_cldr_units, :additional_units, new_config)

      assert_raise ArgumentError, ~r/Additional unit factor must be a number or a rational.*/, fn ->
        Cldr.Unit.Additional.conversions()
      end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end

    test "Measurement systems is a list" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      new_config = [vehicle: [base_unit: :unit, factor: 1, systems: "string"]]

      Application.put_env(:ex_cldr_units, :additional_units, new_config)

      assert_raise ArgumentError, ~r/Additional unit systems must be a list.*/, fn ->
        Cldr.Unit.Additional.conversions()
      end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end

    test "Measurement systems are valid" do
      original_config = Application.get_env(:ex_cldr_units, :additional_units)
      new_config = [vehicle: [base_unit: :unit, factor: 1, systems: ["invalid"]]]

      Application.put_env(:ex_cldr_units, :additional_units, new_config)

      assert_raise ArgumentError, ~r/Additional unit valid measurement systems are.*/, fn ->
        Cldr.Unit.Additional.conversions()
      end

      Application.put_env(:ex_cldr_units, :additional_units, original_config)
    end
  end

  describe "Defining localizations" do
    test "backend with no localizations" do
      assert capture_io(:stderr, fn ->
               capture_io(fn ->
                 defmodule Backend do
                   use Cldr.Unit.Additional

                   use Cldr,
                     locales: ["en"],
                     providers: [Cldr.Number, Cldr.Unit, Cldr.List]
                 end
               end)
             end) =~
               ~r/The locales \[\"en\"] configured in the CLDR backend Cldr.Unit.AdditionalUnitTest.Backend do not have localizations defined.*/
    end

    test "backend with missing localizations" do
      warnings =
        capture_io(:stderr, fn ->
          capture_io(fn ->
            defmodule Backend2 do
              use Cldr.Unit.Additional

              use Cldr,
                locales: ["en", "fr"],
                providers: [Cldr.Number, Cldr.Unit, Cldr.List]

              unit_localization(:person, "en", :long,
                one: "{0} person",
                other: "{0} people",
                display_name: "people"
              )
            end
          end)
        end)

      assert warnings =~
               ~r/.*The locales \[\"fr\"\] configured in the CLDR backend Cldr.Unit.AdditionalUnitTest.Backend2 do not have localizations defined.*/

      assert warnings =~
               ~r/.*Cldr.Unit.AdditionalUnitTest.Backend2.Unit.Additional does not define localizations for the units \[:vehicle\] in locale \"en\" with style :long.*/
    end

    test "backend with localization missing the :other key" do
      assert_raise ArgumentError, ~r/Localizations must have an :other key/, fn ->
        defmodule Backend3 do
          use Cldr.Unit.Additional

          use Cldr,
            locales: ["en"],
            providers: [Cldr.Number, Cldr.Unit, Cldr.List]

          unit_localization(:person, "en", :long,
            one: "{0} person",
            display_name: "people"
          )
        end
      end
    end

    test "backend with localization missing the :display_name key" do
      assert_raise ArgumentError, "Localizations must have a :display_name key", fn ->
        defmodule Backend4 do
          use Cldr.Unit.Additional

          use Cldr,
            locales: ["en"],
            providers: [Cldr.Number, Cldr.Unit, Cldr.List]

          unit_localization(:person, "en", :long,
            one: "{0} person",
            other: "{0} people"
          )
        end
      end
    end
  end
end
