defmodule Stock do

  HTTPotion.start

  @symbols ~w(PCLN)
  @url "http://finance.yahoo.com/webservice/v1/symbols/#{Enum.join( @symbols, "" )}/quote?format=json&view=detail"

  @url
    |> HTTPotion.get([ "User-agent": "Elixir" ])
    |> Map.get( :body )
    |> Poison.decode!
    |> Map.get( "list" )
    |> Map.get( "resources" )
    |> Enum.each fn( resource ) ->
      fields = resource["resource"]["fields"]
      def unquote( String.to_atom( String.downcase( fields["symbol"] ) ) )() do
        unquote( Macro.escape( fields ) )
      end
    end

end
