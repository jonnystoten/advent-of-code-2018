defmodule Point do
  defstruct [:position, :velocity]
end

defmodule Day10 do
  def part1 do
    {points, _t} = find_message(input())

    {{min_x, max_x}, {min_y, max_y}} =
      points
      |> min_max_x_y()

    for y <- min_y..max_y do
      for x <- min_x..max_x do
        if Enum.any?(points, fn %Point{position: {px, py}} -> px == x and py == y end) do
          "#"
        else
          " "
        end
      end
      |> Enum.concat(["\n"])
    end
  end

  defp find_message(points), do: tick(points, 0, :infinity)

  defp tick(points, t, last_width) do
    new_points = Enum.map(points, &move_point/1)

    {min, max} =
      new_points
      |> Enum.map(fn %Point{position: {x, _y}} -> x end)
      |> Enum.min_max()

    width = max - min

    if width > last_width do
      {points, t}
    else
      tick(new_points, t + 1, width)
    end
  end

  defp move_point(point = %Point{position: {pos_x, pos_y}, velocity: {vel_x, vel_y}}) do
    %Point{point | position: {pos_x + vel_x, pos_y + vel_y}}
  end

  defp min_max_x_y(points) do
    min_max_x =
      points
      |> Enum.map(fn %Point{position: {x, _y}} -> x end)
      |> Enum.min_max()

    min_max_y =
      points
      |> Enum.map(fn %Point{position: {_x, y}} -> y end)
      |> Enum.min_max()

    {min_max_x, min_max_y}
  end

  def part2 do
    {_points, t} = find_message(input())
    t
  end

  # position=< 6, 10> velocity=<-2, -1>
  # position=< 2, -4> velocity=< 2,  2>
  # position=<-6, 10> velocity=< 2, -2>
  defp parse_input(input) do
    regex =
      ~r/position=<\s*(?<pos_x>-?\d+),\s*(?<pos_y>-?\d+)> velocity=<\s*(?<vel_x>-?\d+), \s*(?<vel_y>-?\d+)>/

    %{pos_x: pos_x, pos_y: pos_y, vel_x: vel_x, vel_y: vel_y} =
      Regex.named_captures(regex, input)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), String.to_integer(v)} end)
      |> Enum.into(%{})

    %Point{position: {pos_x, pos_y}, velocity: {vel_x, vel_y}}
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_input/1)
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1:")
IO.puts(Day10.part1())
IO.puts("Part 2: #{Day10.part2()}")
