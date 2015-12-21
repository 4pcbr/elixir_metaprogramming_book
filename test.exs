ExUnit.start()

defmodule MyModule do
  def func_a do
    "func a"
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [ func_a: 0 ]
    end
  end

end

defmodule MySubModule do
  use MyModule
end

defmodule MySubModuleTest do
  use ExUnit.Case
  import MySubModule, only: [ func_a: 0 ]

  test "test func a" do
    assert func_a == "func a"
  end

end


ExUnit.run()
