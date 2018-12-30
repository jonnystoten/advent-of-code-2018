defmodule Day12 do
  def part1 do
    input()
    |> sum_after_generation(20)
  end

  def part2 do
    input()
    |> sum_after_generation(50_000_000_000)
  end

  defp sum_state(state) do
    state
    |> Enum.filter(fn {_k, v} -> v end)
    |> Enum.map(fn {k, _v} -> k end)
    |> Enum.sum()
  end

  defp sum_after_generation(input, n), do: sum_after_generation(input, n, 0)

  defp sum_after_generation({state, _notes}, 0, _last_diff), do: sum_state(state)

  defp sum_after_generation({state, notes}, n, last_diff) do
    ns = new_state(state, notes)
    new_sum = sum_state(ns)
    diff = new_sum - sum_state(state)

    if diff == last_diff do
      sum_after_generation_short_cut(new_sum, n - 1, diff)
    else
      sum_after_generation({ns, notes}, n - 1, diff)
    end
  end

  defp sum_after_generation_short_cut(current_sum, generations, diff) do
    current_sum + generations * diff
  end

  defp new_state(state, notes) do
    state
    |> interesting_range()
    |> Enum.reduce(state, fn pot, new_state ->
      Map.put(new_state, pot, new_pot_state(pot, state, notes))
    end)
  end

  defp interesting_range(state) do
    [{first, _} | tail] =
      state
      |> Enum.filter(fn {_k, v} -> v end)
      |> Enum.sort()

    [{last, _} | _] = Enum.reverse(tail)

    (first - 2)..(last + 2)
  end

  defp new_pot_state(pot, state, notes) do
    key =
      (pot - 2)..(pot + 2)
      |> Enum.to_list()
      |> Enum.map(fn pot -> has_plant?(pot, state) end)

    Map.fetch!(notes, key)
  end

  defp has_plant?(pot, state) do
    case Map.fetch(state, pot) do
      {:ok, result} -> result
      :error -> false
    end
  end

  defp print_state(state, label \\ "state") do
    state
    |> Enum.to_list()
    |> Enum.sort()
    |> Enum.map(fn {_k, v} -> v end)
    |> Enum.map(fn
      true -> "#"
      false -> "."
    end)
    |> Enum.join()
    |> IO.inspect(label: label)

    state
  end

  # initial state: #..#.#..##......###...###
  defp parse_initial_state(input) do
    regex = ~r/initial state: (?<state>[\.#]+)/
    %{"state" => state} = Regex.named_captures(regex, input)

    state
    |> parse_plants()
    |> Enum.with_index()
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Enum.into(%{})
  end

  # ...## => #
  # ..#.. => #
  # .#... => #
  defp parse_note(input) do
    regex = ~r/(?<state>[\.#]+) => (?<outcome>[\.#])/
    %{"state" => state, "outcome" => outcome} = Regex.named_captures(regex, input)

    {parse_plants(state), parse_plant(outcome)}
  end

  defp parse_plants(input) do
    input
    |> String.split("", trim: true)
    |> Enum.map(&parse_plant/1)
  end

  defp parse_plant("#"), do: true
  defp parse_plant("."), do: false

  defp input do
    [head | tail] =
      input_path()
      |> File.read!()
      |> String.split("\n", trim: true)

    notes =
      tail
      |> Enum.map(&parse_note/1)
      |> Enum.into(%{})

    {parse_initial_state(head), notes}
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day12.part1()}")
IO.puts("Part 2: #{Day12.part2()}")
