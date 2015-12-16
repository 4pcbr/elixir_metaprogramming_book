defmodule Loop do
  defmacro while( expression, do: block ) do
    quote do
      try do
        for _ <- Stream.cycle([ :ok ]) do
          if unquote( expression ) do
            unquote( block )
          else
            Loop.break
          end
        end
      catch
        :break -> :ok
      end
    end
  end

  def break, do: throw :break

end

defmodule LoopTest do

  import Loop

  def test1 do
    run_loop = fn ->
      pid = spawn( fn -> :timer.sleep( 4000 ) end )
      while Process.alive?( pid ) do
        IO.puts "#{inspect :erlang.time} Stayin' alive!"
        :timer.sleep 1000
      end
    end
  end

  def test2 do
    pid = spawn fn ->
      while true do
        receive do
          :stop ->
            IO.puts "Stopping..."
            break
          message -> 
            IO.puts "Got #{inspect message}"
        end
      end
    end
  end

end

