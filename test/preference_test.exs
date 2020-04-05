defmodule Cldr.Unit.Preference.Test do
  use ExUnit.Case

  alias Cldr.Unit.Test.PreferenceData

  for t <- PreferenceData.preferences() do
    test "preference for #{t.input_unit} of usage #{t.usage} in region #{t.region} for #{inspect t.input_double} is #{inspect t.output}" do
      # {:ok, from} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.from))
      # {:ok, to} = Cldr.Unit.Parser.canonical_base_unit(unquote(t.to))
      # assert from == to
    end
  end

end