defmodule Ersatz.Base do

  import Ersatz.Dpll
  import Ersatz.Cnf

  @doc """
  iex> Ersatz.Base.freeVariable({:const, true})
  nil

  iex> Ersatz.Base.freeVariable({:var, "ciao"})
  "ciao"

  iex> Ersatz.Base.freeVariable({:not, {:var, "ciao"}})
  "ciao"

  iex> Ersatz.Base.freeVariable({:or, {:var, "ciao"}, {:const, true}})
  "ciao"
  iex> Ersatz.Base.freeVariable({:or, {:const, false}, {:const, true}})
  nil
  """
  def freeVariable({:const, _}), do: nil
  def freeVariable({:var, v}), do: v
  def freeVariable({:not, e}), do: freeVariable e
  def freeVariable({op, x, y}) when op in [:or, :and] do
    [x, y]
    |> Stream.map(&freeVariable/1)
    |> Enum.find(nil, &(!is_nil(&1)))
  end

  @doc """
  iex> Ersatz.Base.guessVariable("a", true, {:var, "a"})
  {:const, true}
  iex> Ersatz.Base.guessVariable("a", true, {:var, "b"})
  {:var, "b"}

  iex> Ersatz.Base.guessVariable("a", true, {:not, {:var, "b"}})
  {:not, {:var, "b"}}

  iex> Ersatz.Base.guessVariable("a", true, {:or, {:var, "b"}, {:var, "a"}})
  {:or, {:var, "b"}, {:const, true}}

  iex> Ersatz.Base.guessVariable("a", true, {:and, {:var, "b"}, {:var, "a"}})
  {:and, {:var, "b"}, {:const, true}}

  iex> Ersatz.Base.guessVariable("a", true, {:const, false})
  {:const, false}
  """
  def guessVariable(var, val, {:var, v}) do
    if v === var do
      {:const, val}
    else
      {:var, v}
    end
  end
  def guessVariable(var, val, {:not, e}) do
    {:not, guessVariable(var, val, e)}
  end
  def guessVariable(var, val, {:or, x, y}) do
    {:or, guessVariable(var, val, x), guessVariable(var, val, y)}
  end
  def guessVariable(var, val, {:and, x, y}) do
    {:and, guessVariable(var, val, x), guessVariable(var, val, y)}
  end
  def guessVariable(_, _, otherwise), do: otherwise

  @doc """
  iex> Ersatz.Base.simplify({:not, {:const, true}})
  {:const, false}
  iex> Ersatz.Base.simplify({:not, {:not, {:const, true}}})
  {:const, true}

  iex> Ersatz.Base.simplify({:or, {:not, {:const, true}}, {:const, true}})
  {:const, true}

  iex> Ersatz.Base.simplify({:and, {:not, {:const, false}}, {:const, true}})
  {:const, true}
  """
  def simplify({:not, e}) do
    case simplify(e) do
      {:const, b} -> {:const, !b}
      f -> {:not, f}
    end
  end
  def simplify({:or, x, y}) do
    filtered = [x, y]
      |> Stream.map(&simplify/1)
      |> Enum.filter(&(&1 != {:const, false}))

    if {:const, true} in filtered do
      {:const, true}
    else
      case filtered do
        [] -> {:const, false}
        [e] -> e
        [e1, e2] -> {:or, e1, e2}
      end
    end
  end
  def simplify({:and, x, y}) do
    filtered = [x, y]
      |> Stream.map(&simplify/1)
      |> Enum.filter(&(&1 != {:const, true}))

    if {:const, false} in filtered do
      {:const, false}
    else
      case filtered do
        [] -> {:const, true}
        [e] -> e
        [e1, e2] -> {:and, e1, e2}
      end
    end
  end
  def simplify(otherwise), do: otherwise

  def unConst({:const, b}), do: b
  def unConst(_), do: raise "parameter is not a const"

  @doc """
  iex> Ersatz.Base.satisfiable({:and, {:var, "x"}, {:not, {:var, "x"}}})
  false

  aiex> Ersatz.Base.satisfiable({:or, {:var, "x"}, {:not, {:var, "x"}}})
  true
  """
  def satisfiable(expr) do
    case freeVariable expr do
      nil -> unConst expr
      v -> [true, false]
           |> Enum.map(fn b -> simplify (guessVariable v, b, expr) end)
           |> Enum.any?(&satisfiable/1)
    end
  end

  def satisfiableDpll(expr) do
    exprx = expr
    |> unitPropagation()
    |> cnf()
    |> literalElimination()

    case freeVariable(exprx) do
      nil -> unConst(simplify(exprx))
      v -> [true, false]
           |> Enum.map(fn b -> simplify (guessVariable v, b, expr) end)
           |> Enum.any?(&satisfiableDpll/1)
    end
  end
end
