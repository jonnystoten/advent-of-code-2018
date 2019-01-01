defmodule State do
  defstruct grid: %{}, carts: []
end

defmodule Cart do
  defstruct [:position, :direction, next_turn: :left]
end

defmodule Day13 do
  def part1 do
    {x, y} =
      input()
      |> Map.update!(:carts, fn carts -> Enum.sort_by(carts, & &1.position) end)
      |> crash_location()

    "#{x},#{y}"
  end

  def part2 do
    {x, y} =
      input()
      |> Map.update!(:carts, fn carts -> Enum.sort_by(carts, & &1.position) end)
      |> location_of_last_cart()

    "#{x},#{y}"
  end

  defp crash_location(state) do
    case crash_location_tick(state) do
      {:crash, {x, y}} -> {x, y}
      {:no_crash, new_carts} -> crash_location(%State{state | carts: new_carts})
    end
  end

  defp location_of_last_cart(%State{carts: [cart]}), do: cart.position
  defp location_of_last_cart(state), do: location_of_last_cart(tick(state))

  defp crash_location_tick(%State{grid: grid, carts: carts}),
    do: crash_location_tick(grid, carts, [])

  defp crash_location_tick(_, [], moved_carts),
    do: {:no_crash, Enum.sort_by(moved_carts, & &1.position)}

  defp crash_location_tick(grid, [head | tail], moved_carts) do
    %Cart{direction: direction, position: position, next_turn: next_turn} = head
    new_position = new_position(position, direction)

    {new_direction, new_next_turn} =
      case Map.fetch(grid, new_position) do
        {:ok, tile} -> {new_direction(direction, tile, next_turn), next_turn(next_turn, tile)}
        :error -> {direction, next_turn}
      end

    new_cart = %Cart{direction: new_direction, position: new_position, next_turn: new_next_turn}

    if crash?(new_cart, tail ++ moved_carts) do
      {:crash, new_position}
    else
      crash_location_tick(grid, tail, [new_cart | moved_carts])
    end
  end

  defp tick(%State{grid: grid, carts: carts}), do: tick(grid, carts, [])

  defp tick(grid, [], moved_carts),
    do: %State{grid: grid, carts: Enum.sort_by(moved_carts, & &1.position)}

  defp tick(grid, [head | tail], moved_carts) do
    %Cart{direction: direction, position: position, next_turn: next_turn} = head
    new_position = new_position(position, direction)

    {new_direction, new_next_turn} =
      case Map.fetch(grid, new_position) do
        {:ok, tile} -> {new_direction(direction, tile, next_turn), next_turn(next_turn, tile)}
        :error -> {direction, next_turn}
      end

    new_cart = %Cart{direction: new_direction, position: new_position, next_turn: new_next_turn}

    if crash?(new_cart, tail ++ moved_carts) do
      tail = Enum.reject(tail, &(&1.position == new_position))
      moved_carts = Enum.reject(moved_carts, &(&1.position == new_position))
      tick(grid, tail, moved_carts)
    else
      tick(grid, tail, [new_cart | moved_carts])
    end
  end

  defp crash?(%Cart{position: position}, other_carts) do
    other_carts
    |> Enum.any?(fn %Cart{position: other_position} -> position == other_position end)
  end

  defp new_position({x, y}, :up), do: {x, y - 1}
  defp new_position({x, y}, :down), do: {x, y + 1}
  defp new_position({x, y}, :left), do: {x - 1, y}
  defp new_position({x, y}, :right), do: {x + 1, y}

  defp new_direction(:up, :left_curve, _), do: :left
  defp new_direction(:up, :right_curve, _), do: :right
  defp new_direction(:up, :intersection, _next_turn = :left), do: :left
  defp new_direction(:up, :intersection, _next_turn = :right), do: :right

  defp new_direction(:down, :left_curve, _), do: :right
  defp new_direction(:down, :right_curve, _), do: :left
  defp new_direction(:down, :intersection, _next_turn = :left), do: :right
  defp new_direction(:down, :intersection, _next_turn = :right), do: :left

  defp new_direction(:left, :left_curve, _), do: :up
  defp new_direction(:left, :right_curve, _), do: :down
  defp new_direction(:left, :intersection, _next_turn = :left), do: :down
  defp new_direction(:left, :intersection, _next_turn = :right), do: :up

  defp new_direction(:right, :left_curve, _), do: :down
  defp new_direction(:right, :right_curve, _), do: :up
  defp new_direction(:right, :intersection, _next_turn = :left), do: :up
  defp new_direction(:right, :intersection, _next_turn = :right), do: :down

  defp new_direction(direction, :intersection, _next_turn = :straight), do: direction

  defp next_turn(:left, :intersection), do: :straight
  defp next_turn(:straight, :intersection), do: :right
  defp next_turn(:right, :intersection), do: :left

  defp next_turn(next_turn, _), do: next_turn

  defp parse_char(char, x, y, state = %State{grid: grid}) when char in ["/", "\\", "+"] do
    %State{state | grid: Map.put(grid, {x, y}, track_type(char))}
  end

  defp parse_char(char, x, y, state = %State{carts: carts}) when char in ["^", "v", "<", ">"] do
    cart = %Cart{position: {x, y}, direction: cart_direction(char)}
    %State{state | carts: [cart | carts]}
  end

  defp parse_char(_, _, _, state), do: state

  defp track_type("/"), do: :right_curve
  defp track_type("\\"), do: :left_curve
  defp track_type("+"), do: :intersection

  defp cart_direction("^"), do: :up
  defp cart_direction("v"), do: :down
  defp cart_direction("<"), do: :left
  defp cart_direction(">"), do: :right

  defp parse_line(line, y, state) do
    line
    |> String.split("", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(state, fn {char, x}, state -> parse_char(char, x, y, state) end)
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(%State{}, fn {line, y}, state -> parse_line(line, y, state) end)
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day13.part1()}")
IO.puts("Part 2: #{Day13.part2()}")
