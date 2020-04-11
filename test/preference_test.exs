defmodule Cldr.Unit.Preference.Test do
  use ExUnit.Case
  use Ratio

  alias Cldr.Unit.Test.PreferenceData

  # Currently we're not handling `-inverse` quantities (categories) so
  # omit those tests for now

  for t <- PreferenceData.preferences(), !String.contains?(t.quantity, "-inverse") do

    test_name = """
    ##{t.line}: preference for #{inspect t.input_unit} with usage #{inspect t.usage}
    in region #{inspect t.region} for #{inspect t.input_double}
    is #{inspect t.output_units}
    """
    |> String.replace("\n", " ")

    test test_name do
      assert {:ok, _} = Cldr.Unit.Preference.preferred_units(
        Cldr.Unit.new!(unquote(t.input_unit), unquote(t.input_double)),
        MyApp.Cldr, usage: unquote(t.usage), region: unquote(t.region)
      )
    end
  end

end