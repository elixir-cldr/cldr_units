defmodule Cldr.Unit.Alias do
  @moduledoc """
  Functions to manage unit name aliases

  """

  @aliases %{
    metre: :meter,
    kilometre: :kilometer
  }

  @aliases Cldr.Config.units()
           |> Map.get(:aliases)
           |> Map.merge(@aliases)

  def aliases do
    @aliases
  end

  @doc """
  Un-aliases the provided unit if there
  is one or return the argument unchanged.

  """
  def alias(alias) do
    Map.get(aliases(), alias) || alias
  end
end
