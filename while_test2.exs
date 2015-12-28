Code.require_file( "while.exs", __DIR__ )
Code.require_file( "assert.exs", __DIR__ )

defmodule WhileTest do
  use Assertion
  import Loop

  test "while/2 loops as long as the expression is truthy" do
    pid = spawn( fn -> :timer.sleep( :infinity ) end )

    send self, :one

    while Process.alive?( pid ) do
      receive do
        :one -> send self, :two
        :two -> send self, :three
        :three ->
          Process.exit( pid, :kill )
          send self, :done
      end
    end
    assert Process.info(self)[:messages] == [:done]
  end

end

WhileTest.run()
