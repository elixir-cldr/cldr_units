defmodule Cldr.Unit.Range do
  @moduledoc """
  Implements a unit range type, similar to `Date.Range`.

  A unit range but be comprise `first` and `last` units that
  have the same base unit. The `last` unit will be converted
  to the unit type of the `first` unit.

  Unit ranges are useful in at least the following cases:

  1. To be able to enumerate a unit range.
  2. To be able to format a unit range in a localised manner using
    `Cldr.Number.to_range_string/2`.

  """

  defstruct [:first, :last]

  @typedoc """
  A unit range consists of two units where the
  last unit can be converted to the same unit type
  as the first unit.

  """
  @type t :: %__MODULE__{first: Cldr.Unit.t(), last: Cldr.Unit.t()}

  @doc """
  Returns a new Cldr.Unit.Range.

  ### Arguments

  * `first` is any `t:Cldr.Unit.t/0` returned by `Cldr.Unit.new/2`.

  * `last` is any `t:Cldr.Unit.t/0` returned by `Cldr.Unit.new/2`
    that is convertible to the same unit as `first` and where its
    converted value is greater than or equal to the value of `first`.

  ### Returns

  * `{:ok, unit_range}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.Unit.Range.new Cldr.Unit.new!(:gram, 1), Cldr.Unit.new!(:gram, 4)
      {:ok, Cldr.Unit.Range.new!(Cldr.Unit.new!(:gram, 1), Cldr.Unit.new!(:gram, 4))}

      iex> Cldr.Unit.Range.new Cldr.Unit.new!(:gram, 1), Cldr.Unit.new!(:liter, 4)
      {:error,
       {Cldr.Unit.InvalidRangeError,
        "Unit ranges require that the last unit can be converted to the first unit. " <>
        "Found Cldr.Unit.new!(:gram, 1) and Cldr.Unit.new!(:liter, 4)"}}

      iex> Cldr.Unit.Range.new Cldr.Unit.new!(:gram, 5), Cldr.Unit.new!(:gram, 4)
      {:error,
       {Cldr.Unit.InvalidRangeError,
        "Unit ranges require that the first unit be less than or equal to the last. " <>
        "Found Cldr.Unit.new!(:gram, 5) and Cldr.Unit.new!(:gram, 4)"}}

  """
  @doc since: "3.16.0"

  @spec new(Cldr.Unit.t(), Cldr.Unit.t()) ::
          {:ok, t()} | {:error, {module(), String.t()}}

  def new(%Cldr.Unit{} = first, %Cldr.Unit{} = last) do
    case Cldr.Unit.convert(last, first.unit) do
      {:ok, last} ->
        if first.value <= last.value do
          {:ok, %__MODULE__{first: first, last: last}}
        else
          {:error,
           {Cldr.Unit.InvalidRangeError,
            "Unit ranges require that the first unit be less than or equal to the last. Found #{inspect(first)} and #{inspect(last)}"}}
        end

      {:error, _} ->
        {:error,
         {Cldr.Unit.InvalidRangeError,
          "Unit ranges require that the last unit can be converted to the first unit. Found #{inspect(first)} and #{inspect(last)}"}}
    end
  end

  @doc """
  Returns a new Cldr.Unit.Range or raises an exception.

  ### Arguments

  * `first` is any `t:Cldr.Unit.t/0` returned by `Cldr.Unit.new/2`.

  * `last` is any `t:Cldr.Unit.t/0` returned by `Cldr.Unit.new/2`
    that is convertible to the same unit as `first` and where its
    converted value is greater than or equal to the value of `first`.

  ### Returns

  * `unit_range` or

  * raises an exception.

  ### Example

      iex> Cldr.Unit.Range.new! Cldr.Unit.new!(:gram, 1), Cldr.Unit.new!(:gram, 4)
      Cldr.Unit.Range.new!(Cldr.Unit.new!(:gram, 1), Cldr.Unit.new!(:gram, 4))

  """
  @doc since: "3.16.0"

  @dialyzer {:nowarn_function, {:new!, 2}}

  @spec new!(Cldr.Unit.t(), Cldr.Unit.t()) :: t() | no_return()

  def new!(%Cldr.Unit{} = first, %Cldr.Unit{} = last) do
    case new(first, last) do
      {:ok, range} -> range
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  defdelegate to_iolist(range), to: Cldr.Unit.Format
  defdelegate to_iolist(range, options), to: Cldr.Unit.Format
  defdelegate to_iolist(range, backend, options), to: Cldr.Unit.Format

  defdelegate to_string(range), to: Cldr.Unit.Format
  defdelegate to_string(range, options), to: Cldr.Unit.Format
  defdelegate to_string(range, backend, options), to: Cldr.Unit.Format
end
