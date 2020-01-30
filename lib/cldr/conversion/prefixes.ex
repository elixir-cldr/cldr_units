defmodule Cldr.Unit.Prefix do
  @moduledoc false
  #
  # use Ratio
  #
  # @config %{data_dir: @data_dir, locales: ["en"], default_locale: "en"}
  #
  # @localisable_units "en"
  #            |> Cldr.Config.get_locale(@config)
  #            |> Map.get(:units)
  #            |> Map.get(:short)
  #            |> Enum.map(fn {k, v} -> {k, Map.keys(v)} end)
  #            |> Enum.into(%{})
  #            |> Map.delete(:compound)
  #            |> Map.values()
  #            |> List.flatten()
  #
  # # Take the localisable factors. See if there is
  # # a conversion factor in place.  If not, detect where they
  # # have an SI prefix (milli, hecto, ....) and if so
  # # add another factor with that prefix and appropriate
  # # factor
  # def add_si_prefix_factors(localisable) do
  #   Enum.reduce localisable, localisable, fn localisable_unit, acc ->
  #     if factors(localisable_unit) do
  #       acc
  #     else
  #       string_unit = to_string(localisable_unit)
  #       is_convertible? = is_convertible?(localisable_unit)
  #
  #       maybe_add_si_factor(string_unit, is_convertible?, acc)
  #     end
  #   end
  # end
  #
  # defp maybe_add_si_factor(("milli" <> suffix) = unit, true, acc) do
  #   if conversion = factors(make_existing_atom(suffix)) do
  #     {new_unit, factor} = make_factor(conversion, unit, Ratio.new(1, 1000), Ratio.new(0))
  #     Map.put(acc, new_unit, factor)
  #   else
  #     acc
  #   end
  # end
  #
  # defp maybe_add_si_factor(_unit, false, acc) do
  #   acc
  # end
  #
  # defp make_factor(conversion, factor, offset) do
  #
  # end
  #
  # defp make_existing_atom(string) do
  #   String.to_existing_atom(string)
  # rescue
  #   nil
  # end
end