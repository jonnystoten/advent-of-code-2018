defmodule Day11 do
  @grid_size 300

  def part1 do
    sat = create_table()

    {{x, y, _size}, _power} = find_highest_power(sat, 3..3)

    "#{x},#{y}"
  end

  def part2 do
    sat = create_table()

    {{x, y, size}, _power} = find_highest_power(sat, 1..@grid_size)

    "#{x},#{y},#{size}"
  end

  defp create_table() do
    for x <- 1..@grid_size, y <- 1..@grid_size do
      {x, y}
    end
    |> Enum.reduce(%{}, fn point, sat ->
      Map.put(sat, point, sat_value(point, sat))
    end)
  end

  defp sat_value({0, _}, _), do: 0
  defp sat_value({_, 0}, _), do: 0

  defp sat_value({x, y}, sat) do
    case Map.fetch(sat, {x, y}) do
      {:ok, value} ->
        value

      :error ->
        power_level(x, y) + sat_value({x, y - 1}, sat) + sat_value({x - 1, y}, sat) -
          sat_value({x - 1, y - 1}, sat)
    end
  end

  defp sum_area({x, y}, size, sat) do
    a = {x, y}
    b = {x + size, y}
    c = {x, y + size}
    d = {x + size, y + size}
    sat_value(d, sat) + sat_value(a, sat) - sat_value(b, sat) - sat_value(c, sat)
  end

  defp find_highest_power(sat, size_range) do
    for size <- size_range, upper = @grid_size - (size - 1), x <- 1..upper, y <- 1..upper do
      {{x, y, size}, sum_area({x - 1, y - 1}, size, sat)}
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
