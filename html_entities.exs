defmodule HtmlEntities do

  @external_resource html_entities_path = Path.join([ __DIR__, "html_entities.txt" ])
  @html_entities ( for line <- File.stream!( html_entities_path, [], :line ) do
    line |> String.strip |> String.split(",")
  end)

  def encode( string ) do
    #TODO
  end

  def decode( string ) do
    #TODO
  end

end

