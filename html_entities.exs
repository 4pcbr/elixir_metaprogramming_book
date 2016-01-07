defmodule HtmlEntities do

  @external_resource html_entities_path = Path.join([ __DIR__, "html_entities.txt" ])
  for line <- File.stream!( html_entities_path, [], :line ) do
    [ encoded, decoded, _ ] = line |> String.strip |> String.split(",")
    defp do_encode_char( unquote( decoded ) ), do: "&#{unquote( encoded )};"
  end

  defp do_encode_char( ch ), do: ch

  def encode( string ) do
    string
      |> String.split("")
      |> Enum.map( &do_encode_char/1 )
      |> Enum.join
  end

end

