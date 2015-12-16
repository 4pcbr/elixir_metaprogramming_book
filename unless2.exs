ExUnit.start()

defmodule ControlFlow do

  import Kernel, except: [ unless: 2 ]

  defmacro unless( expr, [ do: do_block ] ) do
    unquote(__MODULE__).unless( expr, do: do_block, else: nil )
  end

  defmacro unless( expr, [ do: do_block, else: else_block ] ) do
    quote do
      case unquote( expr ) do
        v when v in [ nil, false ] -> unquote( do_block )
        _else                      -> unquote( else_block )
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [ unless: 2 ]
      import unquote( __MODULE__ ), only: [ unless: 2 ]
    end
  end

end

defmodule ControlFlowTest do
  use ExUnit.Case

  use ControlFlow

  test "unless with no else" do
    "asd" == unless( false ) do
      "asd"
    end
  end

  test "unless with else" do
    "asd" == unless ( false ) do
      "asd"
    else
      "qwe"
    end
  end

  test "Else block returns value" do
    "asd" == unless ( true ) do
      "qwe"
    else
      "asd"
    end
  end



end


ExUnit.run()
