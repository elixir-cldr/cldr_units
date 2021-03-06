defmodule Cldr.Unit.GrammaticalCase.Test do
  use ExUnit.Case, async: true
  alias Cldr.Unit

  test "Grammatical Case" do
    u = Unit.new!(3, :meter)

    assert Unit.Format.to_string(u, locale: "de") == {:ok, "3 Meter"}
    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :genitive) == {:ok, "3 Meter"}
    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :dative) == {:ok, "3 Metern"}
    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :nominative) == {:ok, "3 Meter"}
    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :locative) == {:ok, "3 Meter"}

    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :instrumental) ==
             {:ok, "3 Meter"}

    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :vocative) == {:ok, "3 Meter"}
    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :accusative) == {:ok, "3 Meter"}
  end

  test "Invalid Grammatical Case" do
    u = Unit.new!(3, :meter)

    assert Unit.Format.to_string(u, locale: "de", grammatical_case: :bogus) ==
             {
               :error,
               {Cldr.UnknownGrammaticalCaseError,
                "The grammatical case :bogus is not known. The valid cases are " <>
                  inspect(Cldr.Unit.known_grammatical_cases())}
             }
  end
end
