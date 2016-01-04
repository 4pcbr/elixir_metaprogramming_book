defmodule Indenter do

  @tab_indent "  "

  defp do_indent( [ tag, next | tail ], acc, offset \\ 0 ) do
    res = case tag_type( tag ) do
      :opening_tag ->
        acc <> ( List.duplicate( @tab_indent, offset ) |> Enum.join ) <> tag
      :closing_tag ->
        acc <> ( List.duplicate( @tab_indent, offset ) |> Enum.join ) <> tag
      :no_tag ->

    end

  end

  defp tag_type( tag ) do
    case Regex.run( ~r/^<\/?/, to_string( tag ) ) do
      "<"  -> :opening_tag
      "</" -> :closing_tag
      _    -> :no_tag
    end
  end

end

