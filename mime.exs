defmodule Mime do

  defmacro __using__( opts ) do
    mimes_path = Path.join([ __DIR__, "mimes.txt" ])

    meta_definitions = Enum.map( File.stream!( mimes_path, [], :line ), fn line ->
      [ type, rest ] = line |> String.split( "\t" ) |> Enum.map( &String.strip(&1) )
      extensions = String.split( rest, ~r/,\s?/ )
      { type, extensions }
    end )

    meta_definitions = Enum.map( opts, fn { mime_type, extensions } ->
      { to_string( mime_type ), extensions }
    end ) ++ meta_definitions

    for { type, extensions } <- meta_definitions do
      quote do
        def exts_from_type( unquote( type ) ), do: unquote( extensions )
        def type_from_ext( ext ) when ext in unquote( extensions ), do: unquote( type )
      end
    end

    quote do
      def exts_from_type( _type ), do: []
      def valid_type?( type ), do: exts_from_type( type ) |> Enum.any?
      def type_from_ext( _ext ), do: nil
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
