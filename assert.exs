defmodule Assertion do

  defmacro assert({ operator, _, [ lhs, rhs ] }) do
    quote bind_quoted: [ operator: operator, lhs: lhs, rhs: rhs ] do
      Assertion.Test.assert( operator, lhs, rhs )
    end
  end
  defmacro assert( expr ) do
    quote bind_quoted: [ expr: expr ] do
      Assertion.Test.assert( expr )
    end
  end
  defmacro refute({ operator, meta, [ lhs, rhs ] }) do
    inversed_operator = case operator do
      :==   -> :!=
      :>    -> :<
      :<    -> :>
      :!=   -> :==
    end
    quote bind_quoted: [ inversed_operator: inversed_operator, lhs: lhs, rhs: rhs, meta: meta ] do
      Assertion.Test.assert( inversed_operator, lhs, rhs )
    end
  end
  defmacro refute( expr ) do
    quote bind_quoted: [ expr: !expr ] do
      Assertion.Test.assert( expr )
    end
  end

  defmacro __using__( _options ) do
    quote do
      import unquote( __MODULE__ )
      Module.register_attribute __MODULE__, :tests, accumulate: true
      @before_compile unquote( __MODULE__ )
    end
  end

  defmacro __before_compile__( _env ) do
    quote do
      def run, do: Assertion.Test.run( @tests, __MODULE__ )
    end
  end

  defmacro test( description, do: test_block ) do
    test_func = String.to_atom( description )
    quote do
      @tests { unquote(test_func), unquote( description ) }
      def unquote( test_func )(), do: unquote( test_block )
    end
  end

end

defmodule Assertion.Test do

  def run( tests, module ) do
    Enum.each tests, fn { test_func, description } ->
      case apply( module, test_func, [] ) do
        :ok               -> IO.write "."
        { :fail, reason } -> IO.puts """
        
        
        ===============================================
                FAILURE: #{description}
        ===============================================
                #{reason}
                """
      end
    end

  end


  def assert( :==, lhs, rhs ) when lhs == rhs do
    :ok
  end
  def assert( :==, lhs, rhs ) do
    IO.inspect { lhs, rhs }
    { :fail, """
      Expected:       #{lhs}
      to be equal to: #{rhs}
      """
    }
  end
  def assert( :>, lhs, rhs ) when lhs > rhs do
    :ok
  end
  def assert( :>, lhs, rhs ) do
    { :fail, """
      Expected:           #{lhs}
      to be greater than: #{rhs}
      """
    }
  end
  def assert( :<, lhs, rhs ) when lhs < rhs do
    :ok
  end
  def assert( :<, lhs, rhs ) do
    { :fail, """
      Expected:           #{lhs}
      to be less than:    #{rhs}
      """
    }
  end
  def assert(:"!=", lhs, rhs) when lhs != rhs do
    :ok
  end
  def assert(:"!=", lhs, rhs) do
  {
    :fail,
    """
    Expected:             #{lhs}
    to not be equal to    #{rhs}
    """
  }
  end
  def assert( expr ) when is_boolean( expr ) and expr == true do
    :ok
  end
  def assert( expr ) when is_boolean( expr ) do
    {
      :fail,
      """
      Expected true, got false
      """
    }
  end

end

defmodule MathTest do
  use Assertion

  test "integers can be added and subtracted" do
    assert 1 + 1 == 2
    assert 2 + 3 == 5
    assert 5 - 5 != 10
    assert 2 > 1
    assert 2 < 3
    refute 3 < 2
    refute 5 != 5
    refute 1 + 1 != 2
  end

  test "integers can be multiplied and divided" do
    assert 5 * 5 == 25
    assert 10 / 2 == 5
  end

  test "test bool" do
    assert true
    refute false
  end

end


