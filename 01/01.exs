defmodule Day01 do
  def part1 do
    Enum.reduce(input(), &+/2)
  end

  def part2 do
    input()
    |> Stream.cycle()
    |> Enum.reduce_while({0, MapSet.new()}, fn n, {total, seen} ->
      result = total + n

      if MapSet.member?(seen, result) do
        {:halt, result}
      else
        {:cont, {result, MapSet.put(seen, result)}}
      end
    end)
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&String.to_integer/1)
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day01.part1()}")
IO.puts("Part 2: #{Day01.part2()}")
