defmodule Event do
  defstruct [:type, :id, :minutes]
end

defmodule State do
  defstruct [:current_guard, :asleep_since, sleep_map: %{}]
end

defmodule Day04 do
  def part1 do
    final_state =
      input()
      |> Enum.sort()
      |> Enum.map(&parse_input/1)
      |> Enum.reduce(%State{}, &reduce_state/2)

    guard = sleepiest_guard(final_state)
    minute = sleepiest_minute_for_guard(guard, final_state)

    guard * minute
  end

  defp reduce_state(%Event{type: :new_shift, id: id}, state) do
    %{state | current_guard: id, asleep_since: nil}
  end

  defp reduce_state(%Event{type: :sleep, minutes: minutes}, state) do
    %{state | asleep_since: minutes}
  end

  defp reduce_state(
         %Event{type: :wake, minutes: minutes},
         state = %State{current_guard: id, asleep_since: asleep_since, sleep_map: sleep_map}
       ) do
    sleep_map =
      Enum.reduce(asleep_since..(minutes - 1), sleep_map, fn min, sleep_map ->
        Map.update(sleep_map, {id, min}, 1, &(&1 + 1))
      end)

    %{state | asleep_since: nil, sleep_map: sleep_map}
  end

  defp sleepiest_guard(%State{sleep_map: sleep_map}) do
    {id, _} =
      sleep_map
      |> Enum.reduce(%{}, fn {{id, _}, count}, result ->
        Map.update(result, id, count, &(&1 + count))
      end)
      |> Enum.max_by(fn {_, v} -> v end)

    id
  end

  defp sleepiest_minute_for_guard(guard_id, %State{sleep_map: sleep_map}) do
    {{_, min}, _} =
      sleep_map
      |> Enum.filter(fn {{id, _}, _} -> id == guard_id end)
      |> Enum.max_by(fn {{_, _}, count} -> count end)

    min
  end

  def part2 do
    %State{sleep_map: sleep_map} =
      input()
      |> Enum.sort()
      |> Enum.map(&parse_input/1)
      |> Enum.reduce(%State{}, &reduce_state/2)

    {{guard, min}, _} = Enum.max_by(sleep_map, fn {_, count} -> count end)
    guard * min
  end

  # [1518-11-01 00:00] Guard #10 begins shift
  # [1518-11-01 00:05] falls asleep
  # [1518-11-01 00:25] wakes up
  defp parse_input(input) do
    regex = ~r/\[\d{4}-\d{2}-\d{2} \d{2}:(?<minutes>\d{2})\] (?<content>.+)/

    Regex.named_captures(regex, input)
    |> to_event()
  end

  defp to_event(%{"content" => "falls asleep", "minutes" => minutes}),
    do: %Event{type: :sleep, minutes: String.to_integer(minutes)}

  defp to_event(%{"content" => "wakes up", "minutes" => minutes}),
    do: %Event{type: :wake, minutes: String.to_integer(minutes)}

  defp to_event(%{"content" => content}) do
    %{"id" => id} = Regex.named_captures(~r/Guard #(?<id>\d+) begins shift/, content)

    %Event{type: :new_shift, id: String.to_integer(id)}
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

IO.puts("Part 1: #{Day04.part1()}")
IO.puts("Part 2: #{Day04.part2()}")
