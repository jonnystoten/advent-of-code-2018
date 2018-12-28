defmodule Parser do
  defstruct [:tokens, :tree]
end

defmodule Tree do
  defstruct children: [], metadata: []
end

defmodule Day08 do
  def part1 do
    %Parser{tree: tree} =
      %Parser{tokens: input(), tree: %Tree{}}
      |> parse()

    count_metadata(tree)
  end

  defp parse(%Parser{tokens: [child_q, meta_q | tail], tree: tree}) do
    %Parser{tokens: tail, tree: tree}
    |> parse_children(child_q)
    |> parse_metadata(meta_q)
  end

  defp parse_children(parser = %Parser{tree: tree = %Tree{children: children}}, 0),
    do: %Parser{parser | tree: %Tree{tree | children: Enum.reverse(children)}}

  defp parse_children(
         %Parser{tree: %Tree{children: children}} = parser,
         child_q
       ) do
    child_parser = parse(%Parser{parser | tree: %Tree{}})

    parse_children(
      %Parser{
        tokens: child_parser.tokens,
        tree: %Tree{children: [child_parser.tree | children]}
      },
      child_q - 1
    )
  end

  defp parse_metadata(parser, 0), do: parser

  defp parse_metadata(
         %Parser{tokens: [head | tail], tree: tree = %Tree{metadata: metadata}},
         meta_q
       ) do
    parse_metadata(
      %Parser{tokens: tail, tree: %Tree{tree | metadata: [head | metadata]}},
      meta_q - 1
    )
  end

  defp count_metadata(%Tree{children: children, metadata: metadata}) do
    Enum.reduce(children, Enum.sum(metadata), fn child, total ->
      total + count_metadata(child)
    end)
  end

  def part2 do
    %Parser{tree: tree} =
      %Parser{tokens: input(), tree: %Tree{}}
      |> parse()

    value(tree)
  end

  defp value(%Tree{children: [], metadata: metadata}), do: Enum.sum(metadata)

  defp value(%Tree{children: children, metadata: metadata}) do
    Enum.reduce(metadata, 0, fn meta, total ->
      case Enum.fetch(children, meta - 1) do
        {:ok, child} -> total + value(child)
        :error -> total
      end
    end)
  end

  defp input do
    input_path()
    |> File.read!()
    |> String.split()
    |> Enum.map(&String.to_integer/1)
  end

  defp input_path do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("input.txt")
  end
end

IO.puts("Part 1: #{Day08.part1()}")
IO.puts("Part 2: #{Day08.part2()}")
