defmodule Unit do
  defstruct [:id, :position, :species, hp: 200, attack: 3]

  def draw(%Unit{species: :elf}), do: "E"
  def draw(%Unit{species: :goblin}), do: "G"
end

defmodule State do
  defstruct [:bounds, walls: MapSet.new(), units: %{}, next_id: 0]

  def winner(%State{units: units}) do
    units
    |> Map.values()
    |> Enum.map(& &1.species)
    |> hd()
  end

  def total_hp(%State{units: units}) do
    units
    |> Map.values()
    |> IO.inspect(label: "remaining units")
    |> Enum.map(& &1.hp)
    |> Enum.sum()
  end

  def space_type(%State{walls: walls, units: units}, space) do
    cond do
      MapSet.member?(walls, space) ->
        :wall

      unit = Enum.find(Map.values(units), fn %Unit{position: pos} -> pos == space end) ->
        {:unit, unit}

      true ->
        :empty
    end
  end

  def empty_space?(state, space) do
    space_type(state, space) == :empty
  end

  def draw(state = %State{bounds: {max_x, max_y}}, label \\ "") do
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

    IO.puts(label <> "\n")
    IO.puts(str <> "\n")

    # state.units
    # |> Enum.sort_by(fn %Unit{position: {x, y}} -> {y, x} end)
    # |> Enum.each(fn unit ->
    #   IO.puts("#{inspect(unit.position)}: #{unit.hp}")
    # end)

    # IO.puts("\n")

    state
  end
end

defmodule Pathfinder do
  def bfs(root, get_neighbors, target) do
    queue = :queue.in({root, 0}, :queue.new())

    bfs(queue, get_neighbors, target, MapSet.new())
  end

  defp bfs(queue, get_neighbors, target, visited) do
    case :queue.out(queue) do
      {{:value, tuple}, queue} ->
        search(tuple, queue, get_neighbors, target, visited)

      {:empty, _queue} ->
        :no_path
    end
  end

  defp search({target, depth}, _, _, target, _) do
    {target, depth}
  end

  defp search({item, depth}, queue, get_neighbors, target, visited) do
    queue =
      get_neighbors.(item)
      |> Enum.reject(fn neighbor -> MapSet.member?(visited, neighbor) end)
      |> Enum.map(fn neighbor -> {neighbor, depth + 1} end)
      |> Enum.reject(fn tuple -> :queue.member(tuple, queue) end)
      |> Enum.reduce(queue, fn tuple, queue ->
        :queue.in(tuple, queue)
      end)

    bfs(queue, get_neighbors, target, MapSet.put(visited, item))
  end
end

defmodule Day15 do
  def part1 do
    {state, last_round} =
      input()
      |> State.draw("initial state")
      |> play()

    State.total_hp(state) * last_round
  end

  defp play(state, bail_on_elf_death \\ false), do: play(state, 1, bail_on_elf_death)

  defp play(state = %State{units: units}, round, bail_on_elf_death) do
    elves =
      units
      |> Map.values()
      |> Enum.count(&(&1.species == :elf))

    result =
      units
      |> Map.values()
      |> Enum.sort_by(fn %Unit{position: {x, y}} -> {y, x} end)
      |> Enum.map(& &1.id)
      |> Enum.reduce_while(state, fn id, state ->
        case Map.fetch(state.units, id) do
          {:ok, unit} ->
            case turn(unit, state) do
              {:done, state} -> {:halt, {:done, state}}
              state -> {:cont, state}
            end

          # this means the unit has died this turn
          :error ->
            {:cont, state}
        end
      end)

    case result do
      {:done, state} ->
        State.draw(state, "THAT'S IT")
        {state, round - 1}

      state ->
        elves_after =
          state.units
          |> Map.values()
          |> Enum.count(&(&1.species == :elf))

        if bail_on_elf_death and elves > elves_after do
          State.draw(state, "ELF DIED")
          {state, round - 1}
        else
          state
          |> State.draw("After #{round} rounds")
          |> play(round + 1, bail_on_elf_death)
        end
    end
  end

  defp turn(unit, state = %State{units: units}) do
    case targets(unit, units) do
      [] -> {:done, state}
      targets -> turn(unit, targets, state)
    end
  end

  defp turn(unit, targets, state) do
    if in_range?(unit, targets) do
      combat(unit, targets, state)
    else
      move(unit, state)
    end
  end

  defp in_range_targets(%Unit{position: {x, y}} = unit, targets) do
    [
      {x - 1, y},
      {x + 1, y},
      {x, y - 1},
      {x, y + 1}
    ]
    |> Enum.map(fn space -> Enum.find(targets, fn unit -> unit.position == space end) end)
    |> Enum.reject(&(&1 == nil))
  end

  defp in_range?(unit, targets) do
    Enum.any?(in_range_targets(unit, targets))
  end

  defp move(unit, state = %State{units: units}) do
    all_targets = targets(unit, units)

    possible_targets =
      all_targets
      |> in_range(state)
      |> Enum.map(fn target -> nearest_neighbors(unit.position, target, state) end)
      |> Enum.reject(&(&1 == :no_path))
      |> Enum.sort_by(fn {{x, y}, distance} -> {distance, {y, x}} end)

    case possible_targets do
      [{target, _} | _] -> move_along_path(unit, target, state)
      [] -> combat(unit, all_targets, state)
    end
  end

  defp combat(unit, targets, state) do
    in_range_targets(unit, targets)
    |> Enum.sort_by(fn %Unit{hp: hp, position: {x, y}} -> {hp, y, x} end)
    |> fight_targets(unit, state)
  end

  defp fight_targets([], _, state), do: state

  defp fight_targets([target | _], unit, %State{units: units} = state) do
    hp = target.hp - unit.attack

    units =
      if hp > 0 do
        Map.put(units, target.id, %Unit{target | hp: hp})
      else
        Map.drop(units, [target.id])
      end

    %State{state | units: units}
  end

  defp move_along_path(unit, target, %State{units: units} = state) do
    [{first_step, _} | _] =
      unit.position
      |> empty_neighbors(state)
      |> Enum.map(fn neighbor ->
        {neighbor,
         Pathfinder.bfs(neighbor, fn space -> empty_neighbors(space, state) end, target)}
      end)
      |> Enum.reject(fn {_, path} -> path == :no_path end)
      |> Enum.map(fn {neighbor, {_, distance}} -> {neighbor, distance} end)
      |> Enum.sort_by(fn {{x, y}, distance} -> {distance, y, x} end)

    unit = %Unit{unit | position: first_step}
    units = Map.put(units, unit.id, unit)

    combat(unit, targets(unit, units), %State{state | units: units})
  end

  defp nearest_neighbors(from, target, state) do
    Pathfinder.bfs(from, fn space -> empty_neighbors(space, state) end, target)
  end

  defp targets(%Unit{species: species}, all_units) do
    all_units
    |> Map.values()
    |> Enum.reject(&(&1.species == species))
  end

  defp in_range(targets, state) do
    targets
    |> Enum.map(fn %Unit{position: position} -> position end)
    |> Enum.flat_map(&empty_neighbors(&1, state))
    |> Enum.dedup()
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
    until_elves_win()
  end

  def until_elves_win, do: until_elves_win(30)

  def until_elves_win(elf_attack) do
    state = input(elf_attack)

    elves =
      state.units
      |> Map.values()
      |> Enum.count(&(&1.species == :elf))

    {state, last_round} =
      state
      |> State.draw("initial state")
      |> play(true)

    elves_after =
      state.units
      |> Map.values()
      |> Enum.count(&(&1.species == :elf))

    if elves == elves_after do
      State.total_hp(state) * last_round
    else
      until_elves_win(elf_attack + 1)
    end
  end

  defp parse_char("#", x, y, state = %State{walls: walls}, _) do
    %State{state | walls: MapSet.put(walls, {x, y})}
  end

  defp parse_char(char, x, y, state = %State{units: units, next_id: id}, elf_attack)
       when char in ["E", "G"] do
    unit = parse_unit(char, id, {x, y}, elf_attack)
    %State{state | units: Map.put(units, id, unit), next_id: id + 1}
  end

  defp parse_char(_, _, _, state, _), do: state

  defp parse_unit("E", id, position, elf_attack),
    do: %Unit{id: id, position: position, species: :elf, attack: elf_attack}

  defp parse_unit("G", id, position, _), do: %Unit{id: id, position: position, species: :goblin}

  defp parse_line(line, y, state, elf_attack) do
    line
    |> String.split("", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(state, fn {char, x}, state -> parse_char(char, x, y, state, elf_attack) end)
  end

  defp input(elf_attack \\ 3) do
    lines =
      input_path()
      |> File.read!()
      |> String.split("\n", trim: true)

    state =
      lines
      |> Enum.with_index()
      |> Enum.reduce(%State{}, fn {line, y}, state -> parse_line(line, y, state, elf_attack) end)

    bounds = {String.length(hd(lines)) - 1, Enum.count(lines) - 1}

    %State{state | bounds: bounds}
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

# IO.puts("Part 1: #{Day15.part1()}")
IO.puts("Part 2: #{Day15.part2()}")
