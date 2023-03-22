defimpl Enumerable, for: Cldr.Unit.Range do
  @impl Enumerable
  def count(%{first: first, last: last}) do
    count =
      cond do
        first.value >= 0 and last.value >= 0 ->
          last.value - first.value + 1

        first.value < 0 and last.value >= 0 ->
          abs(first.value) + last.value + 1

        first.value >= 0 and last.value < 0 ->
          first.value + abs(last.value) + 1
      end

    {:ok, count}
  end

  @impl Enumerable
  def member?(range, %Cldr.Unit{} = unit) do
    case Cldr.Unit.convert(unit, range.first.unit) do
      {:ok, converted} ->
        {:ok, converted.value >= range.first.value and converted.value <= range.last.value}

      _other ->
        {:ok, false}
    end
  end

  # TODO implement this properly

  @impl Enumerable
  def slice(_range) do
    {:error, __MODULE__}
  end

  @impl Enumerable
  def reduce(range, {:cont, acc}, fun) do
    if range.first.value <= range.last.value do
      next = Map.put(range.first, :value, range.first.value + 1)
      new_range = Map.put(range, :first, next)

      reduce(new_range, fun.(range.first, acc), fun)
    else
      {:done, acc}
    end
  end

  def reduce(_enum, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def reduce(enum, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(enum, &1, fun)}
  end
end
