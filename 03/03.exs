defmodule Rectangle do
  defstruct [:id, :x1, :x2, :y1, :y2]
end

defmodule Day03 do
  def part1 do
    count_double_claimed(input())
  end

  defp count_double_claimed(list), do: count_double_claimed(list, MapSet.new(), MapSet.new())

  defp count_double_claimed([], _claimed, double_claimed), do: Enum.count(double_claimed)

  defp count_double_claimed([head | tail], claimed, double_claimed) do
    %{"x" => x, "y" => y, "w" => w, "h" => h} = parse_input(head)

    squares =
      for i <- x..(x + w - 1), j <- y..(y + h - 1) do
        {i, j}
      end

    double_claimed =
      Enum.reduce(squares, double_claimed, fn val, acc ->
        if MapSet.member?(claimed, val) do
          MapSet.put(acc, val)
        else
          acc
        end
      end)

    claimed = Enum.reduce(squares, claimed, fn val, acc -> MapSet.put(acc, val) end)

    count_double_claimed(tail, claimed, double_claimed)
  end

  def part2 do
    {all_rectangles, collisions} = get_collisions(input())

    all_rectangles
    |> Enum.map(& &1.id)
    |> Enum.find(fn id -> not Map.has_key?(collisions, id) end)
  end

  defp get_collisions(list), do: get_collisions(list, [], %{})

  defp get_collisions([], rectangles, collisions), do: {rectangles, collisions}

  defp get_collisions([head | tail], other_rectangles, collisions) do
    %{"id" => id, "x" => x, "y" => y, "w" => w, "h" => h} = parse_input(head)

    rectangle = %Rectangle{id: id, x1: x, x2: x + w, y1: y, y2: y + h}

    collisions =
      other_rectangles
      |> Enum.filter(fn other -> overlap?(rectangle, other) end)
      |> Enum.reduce(collisions, fn other, collisions ->
        collisions
        |> Map.update(rectangle.id, [other.id], &[other.id | &1])
        |> Map.update(other.id, [rectangle.id], &[rectangle.id | &1])
      end)

    get_collisions(tail, [rectangle | other_rectangles], collisions)
  end

  defp overlap?(a = %Rectangle{}, b = %Rectangle{}) do
    a.x1 < b.x2 and a.x2 > b.x1 and a.y1 < b.y2 and a.y2 > b.y1
  end

  defp parse_input(input) do
    regex = ~r/#(?<id>\d+) @ (?<x>\d+),(?<y>\d+): (?<w>\d+)x(?<h>\d+)/

    Regex.named_captures(regex, input)
    |> Map.new(fn {k, v} -> {k, String.to_integer(v)} end)
  end

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

IO.puts("Part 1: #{Day03.part1()}")
IO.puts("Part 2: #{Day03.part2()}")
