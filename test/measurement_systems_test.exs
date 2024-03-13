defmodule Cldr.Unit.MeasurementSystemTest do
  use ExUnit.Case, async: true

  test "Measurement system from locale" do
    assert Cldr.Unit.measurement_system_from_locale("en-AU") == :metric
    assert Cldr.Unit.measurement_system_from_locale("en-US") == :ussystem
    assert Cldr.Unit.measurement_system_from_locale("en-GB") == :uksystem

    assert Cldr.Unit.measurement_system_from_locale("001") ==
             {:error,
              {Cldr.LanguageTag.ParseError,
               "Expected one of the regular language tags in BCP-47 while processing a grandfathered language tag inside a BCP47 language tag. Could not parse the remaining \"001\" starting at position 1"}}
  end

  test "Measurement system for a territory" do
    assert Cldr.Unit.measurement_system_for_territory(:AU) == :metric
    assert Cldr.Unit.measurement_system_for_territory(:US) == :ussystem
    assert Cldr.Unit.measurement_system_for_territory(:GB) == :uksystem
    assert Cldr.Unit.measurement_system_for_territory(:GB, :temperature) == :uksystem
    assert Cldr.Unit.measurement_system_for_territory(:"001") == :metric

    assert Cldr.Unit.measurement_system_for_territory(:invalid) ==
             {:error, {Cldr.UnknownTerritoryError, "The territory :invalid is unknown"}}
  end

  test "Measurement systems for a unit" do
    assert Cldr.Unit.measurement_systems_for_unit(:hectare) == [:metric, :si_acceptable]
    assert Cldr.Unit.measurement_systems_for_unit(:liter) == [:metric, :prefixable, :si_acceptable]
    assert Cldr.Unit.measurement_systems_for_unit("liter") == [:metric, :prefixable, :si_acceptable]
    assert Cldr.Unit.measurement_systems_for_unit("liter_per_kilometer") == [:metric, :prefixable, :si_acceptable]
    assert Cldr.Unit.measurement_systems_for_unit("acre_foot") == [:uksystem, :ussystem]

    assert Cldr.Unit.measurement_systems_for_unit(:litdf) ==
             {:error, {Cldr.UnknownUnitError, "The unit :litdf is not known."}}
  end

  test "Measurement systems inclusion for a unit" do
    assert Cldr.Unit.measurement_system?(:hectare, :metric)
    assert Cldr.Unit.measurement_system?(:liter, [:metric])
    refute Cldr.Unit.measurement_system?(:liter, [:ussystem])

    assert Cldr.Unit.measurement_system?(:litdf, :metric) ==
             {:error, {Cldr.UnknownUnitError, "The unit :litdf is not known."}}
  end

  test "All known units (except :unit) resolve measurement systems" do
    errors =
      Cldr.Unit.known_units()
      |> Kernel.--([:unit])
      |> Enum.map(fn unit ->
        Cldr.Unit.measurement_systems_for_unit(unit)
      end)
      |> Enum.filter(fn i -> if is_list(i), do: false, else: true end)

    assert errors == []
  end

   test "That measurement systems for :unit returns an error" do
     assert Cldr.Unit.measurement_systems_for_unit(:unit) ==
       {:error, {Cldr.Unit.UnknownMeasurementSystemError, "The measurement systems for \"unit\" are not known"}}
    end

end
