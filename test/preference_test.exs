defmodule Cldr.Unit.Preference.Test do
  use ExUnit.Case
  use Ratio

  alias Cldr.Unit.Test.PreferenceData

  @maybe_data_bugs []

  for t <- PreferenceData.preferences(),
      t.line not in @maybe_data_bugs do
    test_name =
      """
      ##{t.line}: preference for #{inspect(t.input_unit)} with usage #{inspect(t.usage)}
      in region #{inspect(t.region)} for #{inspect(t.input_double)}
      is #{inspect(t.output_units)}
      """
      |> String.replace("\n", " ")

    test test_name do
      assert {:ok, unquote(t.output_units), _} =
               Cldr.Unit.Preference.preferred_units(
                 Cldr.Unit.new!(unquote(t.input_unit), unquote(t.input_double)),
                 MyApp.Cldr,
                 usage: unquote(t.usage),
                 territory: unquote(t.region)
               )
    end
  end
end
