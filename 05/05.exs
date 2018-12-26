defmodule Day05 do
  def part1 do
    input()
    |> react_polymer()
    |> Enum.count()
  end

  defguardp same_case_opposite_polarity?(c1, c2) when abs(c1 - c2) == 32

  defp react_polymer(input) do
    react_polymer(input, [])
  end

  defp react_polymer([h1, h2 | tail], [back | reacted])
       when same_case_opposite_polarity?(h1, h2) do
    react_polymer([back | tail], reacted)
  end

  defp react_polymer([h1, h2 | tail], reacted) when same_case_opposite_polarity?(h1, h2) do
    react_polymer(tail, reacted)
  end

  defp react_polymer([head | tail], reacted) do
    react_polymer(tail, [head | reacted])
  end

  defp react_polymer(remaining, reacted), do: Enum.reverse(remaining ++ reacted)

  def part2 do
    ?a..?z
    |> Enum.map(fn a ->
      input()
      |> Enum.reject(&(&1 == a))
      |> Enum.reject(&(&1 == a - 32))
      |> react_polymer()
      |> Enum.count()
    end)
    |> Enum.min()
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.split("\n", trim: true)
    |> hd()
    |> String.to_charlist()
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day05.part1()}")
IO.puts("Part 2: #{Day05.part2()}")
