defmodule Day14 do
  def part1 do
    recipes = <<3, 7>>
    elves = [0, 1]

    n_scores_after_target(10, input(), {recipes, elves})
    |> Enum.join()
  end

  defp n_scores_after_target(n, target, {recipes, _}) when byte_size(recipes) >= target + n do
    recipes
    |> :binary.bin_to_list()
    |> Enum.drop(target)
    |> Enum.take(10)
  end

  defp n_scores_after_target(n, target, state) do
    n_scores_after_target(n, target, next_tick(state))
  end

  defp next_tick({recipes, elves}) do
    sum =
      elves
      |> Enum.map(&:binary.at(recipes, &1))
      |> Enum.sum()

    recipes = recipes <> digits(sum)

    elves =
      Enum.map(elves, fn elf ->
        rem(elf + :binary.at(recipes, elf) + 1, byte_size(recipes))
      end)

    {recipes, elves}
  end

  defp digits(0), do: <<0>>
  defp digits(n), do: digits(n, <<>>)

  defp digits(0, result), do: result

  defp digits(n, result) do
    digits(div(n, 10), <<rem(n, 10), result::binary>>)
  end

  def part2 do
    recipes = <<3, 7>>
    elves = [0, 1]

    recipes_before_target(input_binary(), {recipes, elves})
  end

  defp recipes_before_target(target, {recipes, _} = state),
    do: recipes_before_target(target, state, recipes, 0)

  defp recipes_before_target(target, {recipes, _} = state, search_string, already_checked) do
    case :binary.match(search_string, target) do
      {pos, _} ->
        pos + already_checked

      :nomatch ->
        {new_recipes, _} = new_state = next_tick(state)
        recipes_size = byte_size(recipes)
        new_recipes_size = byte_size(new_recipes)
        diff = new_recipes_size - recipes_size

        new_part = :binary.part(new_recipes, byte_size(recipes), diff)
        search_string = <<search_string::binary, new_part::binary>>

        overage = byte_size(search_string) - (byte_size(target) + 2)

        {search_string, already_checked} =
          if overage > 0 do
            bits = overage * 8
            <<_::size(bits), search_string::binary>> = search_string
            {search_string, already_checked + overage}
          else
            {search_string, already_checked}
          end

        recipes_before_target(
          target,
          new_state,
          search_string,
          already_checked
        )
    end
  end

  defp input do
    765_071
  end

  defp input_binary do
    input()
    |> to_string()
    |> String.split("", trim: true)
    |> Enum.map(&String.to_integer/1)
    |> Enum.reduce(<<>>, fn char, result -> <<result::binary, char>> end)
  end
end

IO.puts("Part 1: #{Day14.part1()}")
IO.puts("Part 2: #{Day14.part2()}")
