defmodule Cldr.Unit.Preference.Test do
  use ExUnit.Case
  use Ratio

  alias Cldr.Unit.Test.PreferenceData

  @maybe_data_bugs [105, 106, 437, 278, 438, 151, 152, 277]

  # Currently we're not handling `-inverse` quantities (categories) so
  # omit those tests for now

  for t <- PreferenceData.preferences(),
    !String.contains?(t.quantity, "-inverse"),
    t.line not in @maybe_data_bugs do

    test_name = """
    ##{t.line}: preference for #{inspect t.input_unit} with usage #{inspect t.usage}
    in region #{inspect t.region} for #{inspect t.input_double}
    is #{inspect t.output_units}
    """
    |> String.replace("\n", " ")

    test test_name do
      assert {:ok, unquote(t.output_units)} = Cldr.Unit.Preference.preferred_units(
        Cldr.Unit.new!(unquote(t.input_unit), unquote(t.input_double)),
        MyApp.Cldr, usage: unquote(t.usage), territory: unquote(t.region)
      )
    end
  end

end


# Bugs reported on the CLDR Jira issue tracker

# * #105 -> data bug. 6 seconds cannot become 1 minute and 6 seconds
#
# * #106 -> data bug. 0 seconds cannot become 1 minute and 0 seconds
#
# * #437 -> data bug. 0.4 years cannot become 2 years and 4.8 months
#
# * #278 -> data bug. 0 kilograms is 0, but should be only pounds, not stones and pounds
#
# * #438 -> data bug. 0.0 year can't convert to 1 year and one month. The rule suggests should just be month
#
# * #151 -> data bug. 0.3048 meters is less than 0.9 meters therefore should just be inches.
#
# * #152 -> data. 0 meters for CA should be inches, not 3 feet and zero inches
#
# * #277 -> Maybe conversion bug. The test data is 6.35029318 and the converted unit is 0.635029318
