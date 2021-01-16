defmodule Cldr.Unit.Transport do
  use Cldr.Unit.Definition

  def define do
    {
      :teu,
      %{
        base_unit: :teu,
        factor: 1,
        offset: 0,
        systems: [:metric, :ussystem, :uksystem]
      }
    }
  end

  def localize("en", :short) do
    %{
      one: "# teu",
      other: "# teu"
    }
  end

  def localize("en", :long) do
    %{
      one: "# twenty-foot equivalent unit",
      other: "# twenty-foot equivalent units"
    }
  end
end
