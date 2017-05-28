defmodule Ersatz.Dpll do

  @doc """
  iex> Ersatz.Dpll.literals({:var, "a"})
  MapSet.new(["a"])

  iex> Ersatz.Dpll.literals({:not, {:const, true}})
  MapSet.new

  iex> Ersatz.Dpll.literals({:const, true})
  MapSet.new

  iex> Ersatz.Dpll.literals({:or, {:var, "a"}, {:var, "a"}})
  MapSet.new(["a"])

  iex> Ersatz.Dpll.literals({:and, {:var, "a"}, {:var, "b"}})
  MapSet.new(["a", "b"])
  """
  def literals({:var, a}), do: MapSet.new([a])
  def literals({:not, x}), do: literals(x)
  def literals({:const, _}), do: MapSet.new()
  def literals({:or, x, y}), do: MapSet.union(literals(x), literals(y))
  def literals({:and, x, y}), do: MapSet.union(literals(x), literals(y))

  def combinePolarities([x, y], w) do
    polarities = [x, y]
                 |> Stream.map(&literalPolarity(&1, w))
                 |> Enum.filter(&(!is_nil(&1)))
    case polarities do
      [] -> nil
      ps -> if Enum.all?(ps, &(&1 == :positive)) do
                :positive
            else
              if Enum.all?(ps, &(&1 == :negative)) do
                :negative
              else
                :mixed
              end
            end
      end
  end

  @doc """
  iex> Ersatz.Dpll.literalPolarity({:var, "a"}, "a")
  :positive
  iex> Ersatz.Dpll.literalPolarity({:var, "a"}, "b")
  nil

  iex> Ersatz.Dpll.literalPolarity({:not, {:var, "a"}}, "a")
  :negative
  iex> Ersatz.Dpll.literalPolarity({:not, {:var, "a"}}, "b")
  nil

  iex> Ersatz.Dpll.literalPolarity({:and, {:var, "a"}, {:var, "b"}}, "a")
  :positive
  iex> Ersatz.Dpll.literalPolarity({:and, {:var, "a"}, {:or, {:var, "b"}, {:not, {:var, "a"}}}}, "a")
  :mixed

  iex> Ersatz.Dpll.literalPolarity({:or, {:var, "a"}, {:var, "b"}}, "a")
  :positive
  iex> Ersatz.Dpll.literalPolarity({:or, {:var, "a"}, {:and, {:var, "b"}, {:not, {:var, "a"}}}}, "a")
  :mixed

  iex> Ersatz.Dpll.literalPolarity({:const, true}, "a")
  nil
  """
  def literalPolarity({:var, v}, w) do
    if v == w do
      :positive
    else
      nil
    end
  end
  def literalPolarity({:not, {:var, v}}, w) do
    if v == w do
      :negative
    else
      nil
    end
  end
  def literalPolarity({:and, x, y}, w), do: combinePolarities([x, y], w)
  def literalPolarity({:or, x, y}, w), do: combinePolarities([x, y], w)
  def literalPolarity({:const, _}, _), do: nil

  def extractPolarized(v, :positive), do: {v, true}
  def extractPolarized(v, :negative), do: {v, false}
  def extractPolarized(_, _), do: nil

  @doc """
  iex> Ersatz.Dpll.literalElimination({:and, {:or, {:var, "a"}, {:var, "b"}}, {:or, {:var, "a"}, {:not, {:var, "b"}}}})
  {:and, {:or, {:const, true}, {:var, "b"}}, {:or, {:const, true}, {:not, {:var, "b"}}}}
  """
  def literalElimination(expr) do
    ls = MapSet.to_list(literals(expr))
    ps = Enum.map(ls, fn l -> literalPolarity(expr, l) end)
    ls
    |> Stream.zip(ps)
    |> Stream.map(fn {a, b} -> extractPolarized(a, b) end)
    |> Stream.filter(&(!is_nil(&1)))
    |> Enum.reduce(expr, fn ({v, b}, acc) -> Ersatz.Base.guessVariable(v, b, acc) end)
  end

  def unitClause({:var, v}), do: {v, true}
  def unitClause({:not, {:var, v}}), do: {v, false}
  def unitClause(_), do: nil

  def clauses({:and, x, y}), do: clauses(x) ++ clauses(y)
  def clauses(expr), do: [expr]

  def allUnitClauses(expr) do
    expr
    |> clauses()
    |> Stream.map(&unitClause/1)
    |> Stream.filter(&(!is_nil(&1)))
  end

  @doc """
  iex> Ersatz.Dpll.unitPropagation({:and, {:var, "a"}, {:or, {:var, "b"}, {:not, {:var, "a"}}}})
  {:and, {:const, true}, {:or, {:var, "b"}, {:not, {:const, true}}}}
  """
  def unitPropagation(expr) do
    expr
    |> allUnitClauses()
    |> Enum.reduce(expr, fn ({a, b}, acc) -> Ersatz.Base.guessVariable(a, b, acc) end)
  end

end
