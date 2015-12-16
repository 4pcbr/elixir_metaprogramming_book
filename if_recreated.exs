ExUnit.start()

defmodule ControlFlow do

  defmacro my_if( expr, do: if_block ), do: if( expr, do: if_block, else: nil )
  defmacro my_if( expr, do: if_block, else: else_block ) do
    quote do
      case unquote( expr ) do
        result when result in [ false, nil ] -> unquote( else_block )
        _ -> unquote( if_block )
      end
    end
  end
end

defmodule ControlFlowTest do
  
  use ExUnit.Case

  import ControlFlow, only: [ my_if: 2 ]

  test "no else block" do
    assert(
      "asd" == my_if(true) do
        "asd"
      end
    )
  end

  test "with regular else block" do
    assert(
      "asd" == my_if(true) do
        "asd"
      else
        "qwe"
      end
    )
  end

  test "follow the else-branch" do
    assert(
      "asd" == my_if(false) do
        "qwe"
      else
        "asd"
      end
    )
  end


end


ExUnit.run()
