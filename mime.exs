defmodule Mime do

  @mimes Enum.map( File.stream!( Path.join( [ __DIR__, "mimes.txt"] ), [], :line ), fn( line ) ->
    [ type, rest ] = line |> String.split( "\t" ) |> Enum.map( &String.strip( &1 ) )
    extensions = String.split( rest, ~r/,\s?/ )
    { type, extensions }
  end ) 

  defmacro __using__( opts ) do
    quote bind_quoted: [ mimes: @mimes, opts: Enum.map( opts, fn { k, v } -> { to_string(k), v } end ) ] do
      Enum.each ( mimes ++ opts ), fn { type, extensions } ->
        def exts_from_type( unquote( type ) ), do: unquote( extensions )
        def type_from_ext( ext ) when ext in unquote( extensions ), do: unquote( type )
      end

      def exts_from_type( _type ), do: []
      def type_from_ext( _ext ), do: nil 
      def valid_type?( type ), do: exts_from_type( type ) |> Enum.any?
    end
  end

end

defmodule MimeMapper do
  use Mime, "text/emoji":  [ ".emj" ],
            "text/elixir": [ ".exs" ]
end

ExUnit.start()

defmodule MimeMapperTest do

  use ExUnit.Case

  test "an extension loaded from file" do
    assert MimeMapper.exts_from_type( "text/html" ) == [ ".html" ]
  end


  test "custom mimes" do
    assert MimeMapper.exts_from_type( "text/elixir" ) == [ ".exs" ]
  end

end


ExUnit.run()
