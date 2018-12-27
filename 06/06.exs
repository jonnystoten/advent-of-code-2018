defmodule Day06 do
  def part1 do
    points = input()
    {{min_x, max_x}, {min_y, max_y}} = min_max_points(points)

    grid =
      for x <- min_x..max_x, y <- min_y..max_y, into: %{} do
        distances = Enum.map(points, fn {id, px, py} -> {id, abs(x - px) + abs(y - py)} end)
        {min_id, min_d} = Enum.min_by(distances, fn {_id, distance} -> distance end)

        min_value =
          if Enum.count(distances, fn {_id, distance} -> distance == min_d end) == 1 do
            min_id
          else
            nil
          end

        {{x, y}, min_value}
      end

    infinites =
      grid
      |> Enum.filter(fn {{x, y}, _id} -> x in [min_x, max_x] or y in [min_y, max_y] end)
      |> Enum.map(fn {_k, id} -> id end)
      |> Enum.uniq()

    {_k, v} =
      grid
      |> Enum.map(fn {_k, id} -> id end)
      |> Enum.reject(&(&1 in infinites))
      |> Enum.group_by(& &1)
      |> Enum.max_by(fn {_k, v} -> Enum.count(v) end)

    Enum.count(v)
  end

  def part2 do
    points = input()
    {{min_x, max_x}, {min_y, max_y}} = min_max_points(points)

    safe_points = for x <- min_x..max_x, y <- min_y..max_y, safe_area?(x, y, points), do: {x, y}

    Enum.count(safe_points)
  end

  defp safe_area?(x, y, danger_points) do
    total_distance =
      danger_points
      |> Enum.map(fn {_, px, py} -> abs(x - px) + abs(y - py) end)
      |> Enum.sum()

    total_distance < 10_000
  end

  defp min_max_points(points) do
    min_max_x =
      points
      |> Enum.map(fn {_, x, _} -> x end)
      |> Enum.min_max()

    min_max_y =
      points
      |> Enum.map(fn {_, _, y} -> y end)
      |> Enum.min_max()

    {min_max_x, min_max_y}
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.map(fn {line, index} ->
      [x, y] =
        line
        |> String.split(", ")
        |> Enum.map(&String.to_integer/1)

      {index, x, y}
    end)
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day06.part1()}")
IO.puts("Part 2: #{Day06.part2()}")
