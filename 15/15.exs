defmodule Unit do
  defstruct [:position, :species, hp: 200, attack: 3]

  def draw(%Unit{species: :elf}), do: "E"
  def draw(%Unit{species: :goblin}), do: "G"
end

defmodule State do
  defstruct [:bounds, walls: MapSet.new(), units: []]

  def space_type(%State{walls: walls, units: units}, space) do
    cond do
      MapSet.member?(walls, space) ->
        :wall

      unit = Enum.find(units, fn %Unit{position: pos} -> pos == space end) ->
        {:unit, unit}

      true ->
        :empty
    end
  end

  def empty_space?(state, space) do
    space_type(state, space) == :empty
  end

  def draw(state = %State{walls: walls, units: units, bounds: {max_x, max_y}}, label \\ "") do
    str =
      for y <- 0..max_y do
        for x <- 0..max_x do
          case space_type(state, {x, y}) do
            :empty -> "."
            :wall -> "#"
            {:unit, unit} -> Unit.draw(unit)
          end
        end
        |> Enum.join()
      end
      |> Enum.join("\n")

    IO.puts(label)
    IO.puts(str <> "\n")

    state
  end
end

defmodule Pathfinder do
  def bfs(root, get_neighbors, target) do
    IO.inspect(target, label: "trying to find")

    queue = :queue.in({root, nil, 0}, :queue.new())

    bfs(queue, get_neighbors, target, [], MapSet.new(), :infinity)
  end

  defp bfs(queue, get_neighbors, target, paths, visited, actual_depth) do
    # require IEx
    # IEx.pry()

    case :queue.out(queue) do
      {{:value, tuple = {item, parent, depth}}, queue} ->
        search(
          tuple,
          queue,
          get_neighbors,
          target,
          paths,
          MapSet.put(visited, item),
          actual_depth
        )

      {:empty, _queue} ->
        {target, actual_depth, paths}
    end
  end

  defp search({_, _, depth}, _, _, target, paths, _, actual_depth)
       when depth > actual_depth do
    {target, actual_depth, paths}
  end

  defp search(
         tuple = {target, parent, depth},
         queue,
         get_neighbors,
         target,
         paths,
         visited,
         actual_depth
       ) do
    bfs(queue, get_neighbors, target, [path_back(tuple) | paths], visited, depth)
  end

  defp search(
         tuple = {item, parent, depth},
         queue,
         get_neighbors,
         target,
         paths,
         visited,
         actual_depth
       ) do
    queue =
      get_neighbors.(item)
      |> Enum.map(fn neighbor -> {neighbor, tuple, depth + 1} end)
      |> Enum.reduce(queue, fn tuple = {item, _, _}, queue ->
        if MapSet.member?(visited, item) do
          queue
        else
          :queue.in(tuple, queue)
        end
      end)

    bfs(queue, get_neighbors, target, paths, visited, actual_depth)
  end

  defp path_back(tuple), do: path_back(tuple, [])

  defp path_back({_, nil, _}, result), do: result

  defp path_back({item, parent, _}, result) do
    path_back(parent, [item | result])
  end
end

defmodule Day15 do
  def part1 do
    input()
    |> State.draw()
    |> after_rounds(4)
  end

  defp after_rounds(state, 0), do: state

  defp after_rounds(state = %State{units: units}, round) do
    units
    |> Enum.sort_by(fn %Unit{position: {x, y}} -> {y, x} end)
    |> Enum.reduce(state, &turn/2)
    |> State.draw("#{round} rounds to go")
    |> after_rounds(round - 1)
  end

  defp turn(unit, state = %State{units: units}) do
    if in_range?(unit, targets(unit, units)) do
      combat(unit, state)
    else
      move(unit, state)
    end
  end

  defp in_range?(%Unit{position: {x, y}}, units) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.any?(fn space -> Enum.any?(units, fn unit -> unit.position == space end) end)
  end

  defp move(unit, state = %State{units: units}) do
    possible_targets =
      unit
      |> targets(units)
      |> IO.inspect(label: "targets")
      |> in_range(state)
      |> Enum.map(fn target -> shortest_paths_to(unit.position, target, state) end)
      |> IO.inspect(label: "paths")
      |> Enum.reject(fn {_, distance, _} -> distance == :infinity end)
      |> Enum.sort_by(fn {{x, y}, distance, _} -> {distance, {y, x}} end)
      |> IO.inspect(label: "sorted paths")

    case possible_targets do
      [{_, _, paths} | _] -> move_along_path(unit, paths, state)
      [] -> combat(unit, state)
    end
  end

  defp combat(unit, state) do
    state
  end

  defp move_along_path(unit, paths, %State{units: units} = state) do
    [[first_step | _] | _] =
      paths
      |> IO.inspect(label: "paths to move")
      |> Enum.sort_by(fn [{x, y} | _] -> {y, x} end)

    IO.inspect(first_step, label: "first step")

    %State{state | units: [%Unit{unit | position: first_step} | List.delete(units, unit)]}
  end

  defp shortest_paths_to(from, target, state) do
    Pathfinder.bfs(from, fn space -> empty_neighbors(space, state) end, target)
  end

  defp targets(%Unit{species: species}, all_units) do
    Enum.reject(all_units, &(&1.species == species))
  end

  defp in_range(targets, state) do
    targets
    |> Enum.map(fn %Unit{position: position} -> position end)
    |> Enum.flat_map(&empty_neighbors(&1, state))
    |> Enum.dedup()
    |> IO.inspect(label: "in-range spaces")
  end

  defp empty_neighbors({x, y}, state) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.filter(fn space -> State.empty_space?(state, space) end)
  end

  def part2 do
  end

  defp parse_char("#", x, y, state = %State{walls: walls}) do
    %State{state | walls: MapSet.put(walls, {x, y})}
  end

  defp parse_char(char, x, y, state = %State{units: units}) when char in ["E", "G"] do
    unit = %Unit{position: {x, y}, species: unit_species(char)}
    %State{state | units: [unit | units]}
  end

  defp parse_char(_, _, _, state), do: state

  defp unit_species("E"), do: :elf
  defp unit_species("G"), do: :goblin

  defp parse_line(line, y, state) do
    line
    |> String.split("", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(state, fn {char, x}, state -> parse_char(char, x, y, state) end)
  end

  defp input do
    lines =
      input_path()
      |> File.read!()
      |> String.split("\n", trim: true)

    state =
      lines
      |> Enum.with_index()
      |> Enum.reduce(%State{}, fn {line, y}, state -> parse_line(line, y, state) end)

    bounds = {String.length(hd(lines)) - 1, Enum.count(lines) - 1}

    %State{state | bounds: bounds}
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day15.part1()}")
IO.puts("Part 2: #{Day15.part2()}")
