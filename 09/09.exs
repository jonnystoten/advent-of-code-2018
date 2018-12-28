defmodule Circle do
  def new(enum) do
    {[], Enum.to_list(enum)}
  end

  def next(circle, n \\ 1)
  def next(circle, 0), do: circle

  def next({previous, [current]}, n) do
    next({[], Enum.reverse([current | previous])}, n - 1)
  end

  def next({previous, [current | next]}, n) do
    next({[current | previous], next}, n - 1)
  end

  def previous(circle, n \\ 1)
  def previous(circle, 0), do: circle

  def previous({[], next}, n) do
    previous({Enum.reverse(next), []}, n)
  end

  def previous({[last | previous], next}, n) do
    previous({previous, [last | next]}, n - 1)
  end

  def push({previous, next}, element) do
    {previous, [element | next]}
  end

  def pop({previous, [current | next]}) do
    {current, {previous, next}}
  end
end

defmodule Day09 do
  def part1 do
    {players, last_marble} = input()
    play(players, last_marble)
  end

  defp play(players, last_marble),
    do: play(1, Circle.new([0]), Circle.new(1..players), %{}, last_marble + 1)

  defp play(stop_marble, _, _, scores, stop_marble) do
    scores
    |> Enum.map(fn {_k, v} -> v end)
    |> Enum.max()
  end

  defp play(next_marble, circle, {_, [current_player | _]} = players, scores, stop_marble)
       when rem(next_marble, 23) == 0 do
    {scored_marble, new_circle} =
      circle
      |> Circle.previous(7)
      |> Circle.pop()

    score_this_turn = next_marble + scored_marble
    scores = Map.update(scores, current_player, score_this_turn, &(&1 + score_this_turn))

    play(next_marble + 1, new_circle, Circle.next(players), scores, stop_marble)
  end

  defp play(next_marble, circle, players, scores, stop_marble) do
    new_circle =
      circle
      |> Circle.next(2)
      |> Circle.push(next_marble)

    play(next_marble + 1, new_circle, Circle.next(players), scores, stop_marble)
  end

  def part2 do
    {players, last_marble} = input()
    play(players, last_marble * 100)
  end

  # 10 players; last marble is worth 1618 points
  defp parse_input(input) do
    regex = ~r/(?<players>\d+) players; last marble is worth (?<last_marble>\d+) points/
    %{"players" => players, "last_marble" => last_marble} = Regex.named_captures(regex, input)

    {String.to_integer(players), String.to_integer(last_marble)}
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.trim()
    |> parse_input()
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day09.part1()}")
IO.puts("Part 2: #{Day09.part2()}")
