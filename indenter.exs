defmodule Indenter do

  @tab_indent "  "

  def indent( tags ) do
    do_indent( tags, nil, "", 0 ) |> String.strip
  end

  defp do_indent( [], prev_tag_type, acc, offset ), do: acc

  defp do_indent( [ tag ], prev_tag_type, acc, offset ) do
    case tag_type( tag ) do
      :opening_tag ->
        acc <> ( List.duplicate( @tab_indent, offset ) |> Enum.join ) <> tag
      :closing_tag ->
        acc <> ( List.duplicate( @tab_indent, offset - 1 ) |> Enum.join ) <> tag
      :no_tag ->
        acc <> tag
    end
  end

  defp do_indent( [ tag, next | tail ], prev_tag_type, acc, offset ) do
    current_tag_type = tag_type( tag )
    next_tag_type    = tag_type( next )
    res = case current_tag_type do
      :opening_tag ->
        [
          acc,
          ( List.duplicate( @tab_indent, offset ) |> Enum.join ),
          tag,
          ( case next_tag_type do
            :opening_tag -> "\n"
            :closing_tag -> ""
            :no_tag      -> ""
          end ),
          do_indent( [ next | tail], current_tag_type, acc, offset + 1 ),
        ] |> Enum.join
      :closing_tag ->
        [
          acc,
          ( case prev_tag_type do
            nil -> ""
            :opening_tag -> ""
            :no_tag -> ""
            _ -> ( List.duplicate( @tab_indent, offset - 1 ) |> Enum.join )
          end ),
          tag,
          ( case next_tag_type do
            :opening_tag -> "\n"
            :closing_tag -> "\n"
            :no_tag      -> ""
          end ),
          do_indent( [ next | tail ], current_tag_type, acc, offset - 1 ),
        ] |> Enum.join
      :no_tag ->
        [
          acc,
          tag,
          do_indent( [ next | tail ], current_tag_type, acc, offset )
        ] |> Enum.join
    end
  end

  defp tag_type( tag ) do
    case ( Regex.run( ~r/^<\/?/, to_string( tag ) ) || [] ) |> List.first do
      "<"  -> :opening_tag
      "</" -> :closing_tag
      _    -> :no_tag
    end
  end

end

