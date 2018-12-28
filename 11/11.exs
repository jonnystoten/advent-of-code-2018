defmodule PowerGrid do
  use Agent

  defstruct [:serial, power_values: %{}]

  def start_link(serial) do
    Agent.start_link(fn -> %PowerGrid{serial: serial} end, name: __MODULE__)
  end

  def power_level(x, y) do
    Agent.get_and_update(__MODULE__, fn %{power_values: power_values} = grid ->
      new_power_values =
        Map.put_new_lazy(power_values, {x, y}, fn ->
          calculate_power_level(x, y, grid.serial)
        end)

      grid = %{grid | power_values: new_power_values}

      {Map.fetch!(new_power_values, {x, y}), grid}
    end)
  end

  defp calculate_power_level(x, y, serial) do
    rack_id = x + 10

    rack_id
    |> Kernel.*(y)
    |> Kernel.+(serial)
    |> Kernel.*(rack_id)
    |> hundreds_digit()
    |> Kernel.-(5)
  end

  defp hundreds_digit(n) do
    n
    |> div(100)
    |> rem(10)
  end
end

defmodule Day11 do
  @grid_size 300

  def part1 do
    PowerGrid.start_link(input())
    {{x, y}, _power} = find_highest_power()

    "#{x},#{y}"
  end

  defp find_highest_power do
    for x <- 1..(@grid_size - 2), y <- 1..(@grid_size - 2) do
      {{x, y}, cluster_power_level(x, y)}
    end
    |> Enum.max_by(fn {_, power} -> power end)
  end

  defp cluster_power_level(x, y) do
    for a <- x..(x + 2), b <- y..(y + 2) do
      PowerGrid.power_level(a, b)
    end
    |> Enum.sum()
  end

  def part2 do
  end

  defp input do
    2866
  end
end

IO.puts("Part 1: #{Day11.part1()}")
IO.puts("Part 2: #{Day11.part2()}")
