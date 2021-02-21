defmodule Cldr.Unit.GrammaticalCase.Test do
  use ExUnit.Case, async: true
  alias Cldr.Unit

  test "Grammatical Case" do
    u = Unit.new!(3, :meter)

    assert Unit.to_string(u, locale: "de") == {:ok, "3 Meter"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :genetive) == {:ok, "3 Meter"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :dative) == {:ok, "3 Metern"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :nominative) == {:ok, "3 Meter"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :locative) == {:ok, "3 Meter"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :instrumental) == {:ok, "3 Meter"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :vocative) == {:ok, "3 Meter"}
    assert Unit.to_string(u, locale: "de", grammatical_case: :accusative) == {:ok, "3 Meter"}
  end

  test "Invalid Grammatical Case" do
    u = Unit.new!(3, :meter)

    assert Unit.to_string(u, locale: "de", grammatical_case: :bogus) ==
    {
      :error,
      {Cldr.UnknownGrammaticalCaseError,
        "The grammatical case :bogus is not known. The valid cases are " <>
        "[:nominative, :genetive, :accusative, :dative, :locative, :instrumental, :vocative]"
      }
    }
  end

end
