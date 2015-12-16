defmodule ControlFlow do

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

