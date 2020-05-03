defmodule FunctionClause do
  @moduledoc """
  Format function clauses using Exception.blame/3
  """

  @doc """
  Given a `module`, `function`, and `args` see
  if that function clause would match or not match.
  This is useful for helping diagnose function
  clause errors when many clauses are generated
  at compile time.
  """
  @spec match(module(), atom(), list(any)) :: String.t() | no_return()
  def match(module, function, args) do
    case Exception.blame_mfa(module, function, args) do
      {:ok, kind, clauses} ->
        formatted_clauses(function, kind, clauses, &blame_match/2)

      :error ->
        raise ArgumentError,
              "Function #{inspect(module)}.#{inspect(function)}/#{length(args)} " <>
                "is not known."
    end
  end

  def match_category(unit, usage, territory, number) do
    match_category(Cldr.Unit.Preference, :preferred_units, [unit, usage, territory, number])
    |> IO.puts
    :ok
  end

  def match_category(module, function, args) do
    unit = Cldr.Unit.new!(hd(args), 1)
    {:ok, category} = Cldr.Unit.unit_category(unit)

    case Exception.blame_mfa(module, function, args) do
      {:ok, kind, clauses} ->
        clauses =
          Enum.filter(clauses, fn
            {[%{match?: false, node: node} | _rest], _guards} when node == category -> true
            _ -> false
          end)

        if clauses == [] do
          IO.ANSI.red() <>
            "There are no Cldr.Unit.unit_preferences/4 clauses for the category #{inspect(category)}\n" <>
            "That's probably an upstream bug since invalid categories shouldn't get this far." <>
            IO.ANSI.reset() <>
            "\n"
        else
          IO.ANSI.cyan() <>
            "candidate clauses:\n" <>
            IO.ANSI.reset() <>
            "\n" <>
            formatted_clauses(function, kind, clauses, &blame_match/2)
        end

      :error ->
        raise ArgumentError,
              "Function #{inspect(module)}.#{inspect(function)}/#{length(args)} " <>
                "is not known."
    end
  end

  defp formatted_clauses(function, kind, clauses, ast_fun) do
    format_clause_fun = fn {args, guards} ->
      code = Enum.reduce(guards, {function, [], args}, &{:when, [], [&2, &1]})
      "    #{kind} " <> Macro.to_string(code, ast_fun) <> "\n"
    end

    clauses
    |> Enum.map(format_clause_fun)
    |> Enum.join()
  end

  defp blame_match(%{match?: true, node: node}, _),
    do: Macro.to_string(node)

  defp blame_match(%{match?: false, node: node}, _),
    do: IO.ANSI.red() <> Macro.to_string(node) <> IO.ANSI.reset()

  defp blame_match(_, string), do: string
end
