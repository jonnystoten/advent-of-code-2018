defmodule Day07 do
  def part1 do
    graph =
      input()
      |> Enum.reduce(%{}, fn {first, second}, map ->
        map
        |> Map.put_new(first, [])
        |> Map.update(second, [first], fn deps -> [first | deps] end)
      end)

    topological_sort(graph)
  end

  defp topological_sort(graph), do: topological_sort(graph, [])

  defp topological_sort(graph, result) when graph == %{}, do: Enum.reverse(result)

  defp topological_sort(graph, result) do
    next =
      graph
      |> Enum.filter(fn {_k, deps} -> Enum.count(deps) == 0 end)
      |> Enum.map(fn {k, _deps} -> k end)
      |> Enum.sort()
      |> hd()

    graph =
      graph
      |> Map.drop([next])
      |> Enum.map(fn {k, deps} -> {k, List.delete(deps, next)} end)
      |> Enum.into(%{})

    topological_sort(graph, [next | result])
  end

  def part2 do
    graph =
      input()
      |> Enum.reduce(%{}, fn {first, second}, map ->
        map
        |> Map.put_new(first, [])
        |> Map.update(second, [first], fn deps -> [first | deps] end)
      end)

    timings =
      graph
      |> Enum.map(fn {k, _deps} ->
        char =
          k
          |> String.to_charlist()
          |> hd()

        {k, char - ?A + 1 + 60}
      end)
      |> Enum.into(%{})

    do_work(graph, timings)
  end

  defp do_work(graph, timings), do: do_work(graph, timings, [], 0)

  defp do_work(graph, _timings, [], t) when graph == %{}, do: t

  defp do_work(graph, timings, workers, t) when length(workers) == 5 do
    tick(graph, timings, workers, t)
  end

  defp do_work(graph, timings, workers, t) do
    candidates =
      graph
      |> Enum.filter(fn {_k, deps} -> Enum.count(deps) == 0 end)
      |> Enum.map(fn {k, _deps} -> k end)
      |> Enum.sort()

    case candidates do
      [next | _tail] ->
        do_work(Map.drop(graph, [next]), timings, [next | workers], t)

      [] ->
        tick(graph, timings, workers, t)
    end
  end

  defp tick(graph, timings, workers, t) do
    timings =
      workers
      |> Enum.reduce(timings, fn task, timings ->
        Map.update!(timings, task, &(&1 - 1))
      end)

    {dead, workers} = Enum.split_with(workers, fn task -> Map.get(timings, task) == 0 end)

    graph =
      dead
      |> Enum.reduce(graph, fn dead_task, graph ->
        graph
        |> Map.drop([dead_task])
        |> Enum.map(fn {k, deps} -> {k, List.delete(deps, dead_task)} end)
        |> Enum.into(%{})
      end)

    do_work(graph, timings, workers, t + 1)
  end

  # Step X must be finished before step C can begin.
  defp parse_input(input) do
    regex = ~r/Step (?<first>\w) must be finished before step (?<second>\w) can begin./
    %{"first" => first, "second" => second} = Regex.named_captures(regex, input)
    {first, second}
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

IO.puts("Part 1: #{Day07.part1()}")
IO.puts("Part 2: #{Day07.part2()}")
