Code.require_file( "indenter.exs", __DIR__ )

ExUnit.start()

defmodule IndenterTest do

  use ExUnit.Case
  import Indenter, only: [ indent: 1 ]

  test "Indents an empty tag as a single line" do
    tags = ~w(<tag> </tag>)
    assert indent( tags ) == "<tag></tag>" 
  end

  test "Indents a tag with no-tag content as a single line" do
    tags = ~w(<tag> content </tag>)
    assert indent( tags ) == "<tag>content</tag>"
  end

  test "Indents a tag with a nested tag with newlines and a padding" do
    tags = ~w(<parent> <child> </child> </parent>)
    assert indent( tags ) == """
    <parent>
      <child></child>
    </parent>
    """ |> String.strip
  end

  test "Increments the padding for nested tags" do
    tags = ~w(<t1> <t2> <t3> <t4> asd </t4> </t3> </t2> </t1>)
    assert indent( tags ) == """
    <t1>
      <t2>
        <t3>
          <t4>asd</t4>
        </t3>
      </t2>
    </t1>
    """ |> String.strip
  end

end

