ExUnit.start()

defmodule Mime do

  @external_resource mimes_path = Path.join([ __DIR__, "mimes.txt" ])

  for line <- File.stream!( mimes_path, [], :line ) do
    [ type, rest ] = line |> String.split( "\t" ) |> Enum.map( &String.strip(&1) )
    extensions = String.split( rest, ~r/,\s?/ )
    def exts_for_type( unquote( type ) ), do: unquote( extensions )
    def type_from_ext( ext ) when ext in unquote( extensions ), do: unquote( type )
  end

  def exts_for_type( _type ), do: []
  def valid_type?( type ), do: exts_for_type( type ) |> Enum.any?
  def type_from_ext( _ext ), do: nil

  defmacro __using__( opts ) do
    IO.inspect opts
    quote do
      import unquote( __MODULE__ ), only: [ exts_for_type: 1, type_from_ext: 1 ]
    end
  end

end

defmodule MimeMapper do
  use Mime, "text/emoji":  [ ".emj" ],
            "text/elixir": [ ".exs" ]
end

defmodule MimeMapperTest do

  use ExUnit.Case

  test "custom mimes" do
    assert MimeMapper.exts_for_type( "text/elixir" ) == [ ".exs" ]
  end

end


ExUnit.run()
