defmodule SummedAreaTable do
  def new(size, single_value_fn) do
    all_points(size)
    |> Enum.reduce(%{}, fn point, sat ->
      Map.put(sat, point, initial_sat_value(sat, point, single_value_fn))
    end)
  end

  def sum_area(sat, {x, y}, size) do
    a = {x, y}
    b = {x + size, y}
    c = {x, y + size}
    d = {x + size, y + size}
    sat_value(sat, d) + sat_value(sat, a) - sat_value(sat, b) - sat_value(sat, c)
  end

  defp all_points(size) do
    for x <- 1..size, y <- 1..size do
      {x, y}
    end
  end

  defp sat_value(_, {0, _}), do: 0
  defp sat_value(_, {_, 0}), do: 0

  defp sat_value(sat, {x, y}), do: Map.fetch!(sat, {x, y})

  defp initial_sat_value(sat, {x, y}, single_value_fn) do
    single_value_fn.(x, y) + sat_value(sat, {x, y - 1}) + sat_value(sat, {x - 1, y}) -
      sat_value(sat, {x - 1, y - 1})
  end
end

defmodule Day11 do
  @grid_size 300

  def part1 do
    sat = SummedAreaTable.new(@grid_size, &power_level/2)
    {{x, y, _size}, _power} = find_highest_power(sat, 3..3)

    "#{x},#{y}"
  end

  def part2 do
    sat = SummedAreaTable.new(@grid_size, &power_level/2)
    {{x, y, size}, _power} = find_highest_power(sat, 1..@grid_size)

    "#{x},#{y},#{size}"
  end

  defp find_highest_power(sat, size_range) do
    for size <- size_range, upper = @grid_size - (size - 1), x <- 1..upper, y <- 1..upper do
      area = SummedAreaTable.sum_area(sat, {x - 1, y - 1}, size)
      {{x, y, size}, area}
    end
    |> Enum.max_by(fn {_, power} -> power end)
  end

  defp power_level(x, y) do
    rack_id = x + 10

    rack_id
    |> Kernel.*(y)
    |> Kernel.+(input())
    |> Kernel.*(rack_id)
    |> hundreds_digit()
    |> Kernel.-(5)
  end

  defp hundreds_digit(n) do
    n
    |> div(100)
    |> rem(10)
  end

  defp input do
    2866
  end
end

IO.puts("Part 1: #{Day11.part1()}")
IO.puts("Part 2: #{Day11.part2()}")
