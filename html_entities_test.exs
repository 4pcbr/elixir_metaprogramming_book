ExUnit.start()

Code.require_file( "html_entities.exs", __DIR__ )

defmodule HtmlEntitiesTest do

  use ExUnit.Case
  import HtmlEntities, only: [ encode: 1 ]

  test "encode known entities" do
    assert encode("\"") == "&quot;"
    assert encode("&")  == "&amp;"
    assert encode("'")  == "&apos;"
    assert encode("<")  == "&lt;"
    assert encode(">")  == "&gt;"
    assert encode(" ")  == "&nbsp;"
  end

end

