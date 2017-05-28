defmodule Ersatz.Cnf do

  @doc """
  iex> Ersatz.Cnf.fixNegations({:not, {:not, {:const, true}}})
  {:const, true}

  iex> Ersatz.Cnf.fixNegations({:not, {:and, {:const, true}, {:const, false}}})
  {:or, {:const, false}, {:const, true}}

  iex> Ersatz.Cnf.fixNegations({:not, {:or, {:const, true}, {:const, false}}})
  {:and, {:const, false}, {:const, true}}

  iex> Ersatz.Cnf.fixNegations({:not, {:const, true}})
  {:const, false}

  iex> Ersatz.Cnf.fixNegations({:and, {:const, true}, {:const, true}})
  {:and, {:const, true}, {:const, true}}

  iex> Ersatz.Cnf.fixNegations({:or, {:const, true}, {:const, true}})
  {:or, {:const, true}, {:const, true}}

  iex> Ersatz.Cnf.fixNegations({:const, true})
  {:const, true}
  """
  def fixNegations({:not, {:not, x}}), do: fixNegations x
  def fixNegations({:not, {:and, x, y}}) do
    {:or, fixNegations({:not, x}), fixNegations({:not, y})}
  end
  def fixNegations({:not, {:or, x, y}}) do
    {:and, fixNegations({:not, x}), fixNegations({:not, y})}
  end
  def fixNegations({:not, {:const, b}}), do: {:const, !b}
  def fixNegations({:not, x}), do: {:not, fixNegations(x)}
  def fixNegations({:and, x, y}) do
    {:and, fixNegations(x), fixNegations(y)}
  end
  def fixNegations({:or, x, y}) do
    {:or, fixNegations(x), fixNegations(y)}
  end
  def fixNegations(otherwise), do: otherwise

  @doc """
  iex> Ersatz.Cnf.distribute({:or, {:const, true}, {:and, {:const, false}, {:const, true}}})
  {:and, {:or, {:const, true}, {:const, false}}, {:or, {:const, true}, {:const, true}}}

  iex> Ersatz.Cnf.distribute({:or, {:and, {:const, false}, {:const, true}}, {:const, true}})
  {:and, {:or, {:const, false}, {:const, true}}, {:or, {:const, false}, {:const, true}}}

  iex> Ersatz.Cnf.distribute({:or, {:not, {:const, true}}, {:const, true}})
  {:or, {:not, {:const, true}}, {:const, true}}

  iex> Ersatz.Cnf.distribute({:and, {:not, {:const, true}}, {:const, true}})
  {:and, {:not, {:const, true}}, {:const, true}}

  iex> Ersatz.Cnf.distribute({:not, {:const, true}})
  {:not, {:const, true}}

  iex> Ersatz.Cnf.distribute({:const, true})
  {:const, true}
  """
  def distribute({:or, x, {:and, y, z}}) do
    {:and,
      {:or, distribute(x), distribute(y)},
      {:or, distribute(x), distribute(z)}
    }
  end
  def distribute({:or, {:and, x, y}, z}) do
    {:and,
      {:or, distribute(x), distribute(y)},
      {:or, distribute(x), distribute(z)}
    }
  end
  def distribute({:or, x, y}), do: {:or, distribute(x), distribute(y)}
  def distribute({:and, x, y}), do: {:and, distribute(x), distribute(y)}
  def distribute({:not, x}), do: {:not, distribute(x)}
  def distribute(otherwise), do: otherwise

  # room for improvement: return if expr was modified
  @doc """
  iex> Ersatz.Cnf.cnf {:or, {:var, "a"}, {:not, {:and, {:var, "b"}, {:or, {:var, "a"}, {:var, "c"}}}}}
  {:and, {:or, {:var, "a"}, {:or, {:not, {:var, "b"}}, {:not, {:var, "a"}}}}, {:or, {:var, "a"}, {:or, {:not, {:var, "b"}}, {:not, {:var, "c"}}}}}
  """
  def cnf(expr) do
    updated = distribute (fixNegations expr)
    if updated == expr do
      expr
    else
      cnf updated
    end
  end
end
