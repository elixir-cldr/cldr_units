defmodule Cldr.Unit.Alias do
  def aliases do
    %{
      "metre" => :meter,
      "kilometre" => :kilometer





    }
  end

  def alias(alias) do
    Map.get(aliases(), alias)
  end
end