defmodule Day02 do
  def part1 do
    counts = Enum.map(input(), &duplicate_counts/1)
    twos = Enum.count(counts, &Enum.member?(&1, 2))
    threes = Enum.count(counts, &Enum.member?(&1, 3))

    twos * threes
  end

  defp duplicate_counts(line) do
    line
    |> String.graphemes()
    |> Enum.group_by(& &1)
    |> Enum.map(fn {_, xs} -> length(xs) end)
    |> Enum.filter(fn x -> x > 1 end)
  end

  def part2 do
    {a, b} =
      all_pairs()
      |> Enum.find(fn {a, b} -> differs_by_exactly_one?(a, b) end)

    Enum.zip(a, b)
    |> Enum.reject(fn {a, b} -> a != b end)
    |> Enum.map(fn {a, _} -> a end)
    |> Enum.join("")
  end

  defp all_pairs do
    for {a, i} <- Enum.with_index(input()), b <- Enum.take(input(), i) do
      {String.graphemes(a), String.graphemes(b)}
    end
  end

  defp differs_by_exactly_one?(a, a), do: false
  defp differs_by_exactly_one?([h | a_t], [h | b_t]), do: differs_by_exactly_one?(a_t, b_t)
  defp differs_by_exactly_one?([_a_h | a_t], [_b_h | b_t]), do: a_t == b_t

  defp input do
    input_path()
    |> File.read!()
    |> String.split("\n", trim: true)
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day02.part1()}")
IO.puts("Part 2: #{Day02.part2()}")
