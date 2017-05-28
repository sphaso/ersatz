defmodule Ersatz.QuartoTieTest do
  use ExUnit.Case

  def equals(a, b), do: {:or, {:and, a, b}, {:and, {:not, a}, {:not, b}}}

  def randy(a, b), do: {:and, a, b}

  def randy_list([a]), do: a
  def randy_list([a, b | tail]), do: randy_list(tail ++ [randy(a, b)])

  defp each_property([a, b, c, d]) do
    [0, 1, 2, 3]
    |> Enum.map(fn num ->
      randy(
        randy(
          equals({:var, "#{a}#{num}"}, {:var, "#{b}#{num}"}),
          equals({:var, "#{c}#{num}"}, {:var, "#{d}#{num}"})
        ),
        equals({:var, "#{b}#{num}"}, {:var, "#{c}#{num}"})
      )
    end)
  end

  defp unique_square(a, b) do
    clause = [0, 1, 2, 3]
    |> Enum.map(fn num ->
      equals({:var, "#{a}#{num}"}, {:var, "#{b}#{num}"})
    end)
    |> randy_list()

    {:not, clause}
  end

  def skip_one([_a]), do: []
  def skip_one([_a | tail]), do: tail

  def generate_clauses do
    cols = [
              ["a", "e", "i", "m"],
              ["b", "f", "j", "n"],
              ["c", "g", "k", "o"],
              ["d", "h", "l", "p"],
           ]

    rows = [
              ["a", "b", "c", "d"],
              ["e", "f", "g", "h"],
              ["i", "j", "k", "l"],
              ["m", "n", "o", "p"]
            ]

    diags = [
              ["a", "f", "k", "p"],
              ["d", "g", "j", "m"]
            ]

    no_win = [cols, rows, diags]
    |> Stream.concat()
    |> Stream.flat_map(&each_property/1)
    |> Enum.map(fn clause -> {:not, clause} end)
    |> Enum.reduce(&randy/2)

    squares = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"]
    uniques = squares
    |> Enum.flat_map(fn sq ->
      squares
      |> Enum.drop_while(fn x -> x != sq end)
      |> skip_one()
      |> Enum.map(fn sq2 -> unique_square(sq, sq2) end)
    end)
    |> Enum.reduce(&randy/2)
    #|> IO.inspect

    randy(no_win, uniques)
  end

  test "quarto can end in a tie" do
    generate_clauses()
    |> Ersatz.Base.satisfiableDpll()
    |> assert
  end
end
