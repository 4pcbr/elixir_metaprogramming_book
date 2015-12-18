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
      def run do
        { time, res } = :timer.tc(
          Assertion.Test, :run, [ @tests, __MODULE__ ]
        )

        res = res
          |> Enum.reduce(
            %{ fail: 0, ok: 0, errors: [] }, fn(test_res, acc) ->
              case test_res do
                { :ok } ->
                  { _, acc } = Map.get_and_update( acc, :ok, fn cnt -> { cnt, cnt + 1 } end )
                { :fail, reason } ->
                  { _, acc } = Map.get_and_update( acc, :fail, fn cnt -> { cnt, cnt + 1 } end )
                  { _, acc } = Map.get_and_update( acc, :errors, fn errors -> { errors, [ reason | errors ] } end )
                default ->
                  IO.puts "Unknown result: #{inspect default}"
              end
              acc
            end)
        :io.format "run time(ms): ~.2f~n", [ time / 1000.0 ]
        :io.format "ok:     ~B~nfail:   ~B~n", [ Map.get( res, :ok ), Map.get( res, :fail ) ]
        IO.puts Enum.join( Map.get( res, :errors ), "\n" )
      end
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

  def do_run_test( module, test_func, description ) do
    case apply( module, test_func, [] ) do
      :ok               -> :ok
      { :fail, reason } -> { :fail, """
      
      
      ===============================================
              FAILURE: #{description}
      ===============================================
              #{reason}
              """ }
    end
  end

  def do_run_test_worker( master ) do
    send master, { :ready, self }
    receive do
      { :test, module, test_func, description } ->
        send master, do_run_test( module, test_func, description )
        do_run_test_worker( master )
      { :terminate } -> exit( :normal )
    end
  end

  def run( tests, module ) do
    run( tests, module, length( tests ) )
  end

  def run( tests, module, num_workers ) do
    1..num_workers
      |> Enum.map( fn _ ->
        spawn_link( __MODULE__, :do_run_test_worker, [ self ] )
      end )
      |> do_test( tests, module, [] )
  end

  def do_test( workers, tests, module, results ) do
    receive do
      { :ready, pid } when length(tests) > 0 ->
        [ { test_func, description } | tail ] = tests
        send pid, { :test, module, test_func, description }
        do_test( workers, tail, module, results )
      { :ready, pid } ->
        send pid, { :terminate }
        if length( workers ) > 1 do
          do_test( List.delete( workers, pid ), tests, module, results )
        else
          IO.puts "Done testing"
          results
        end
      :ok ->
        results = [ { :ok } | results ]
        do_test( workers, tests, module, results )
      { :fail, reason } ->
        results = [ { :fail, reason } | results ]
        do_test( workers, tests, module, results )
      msg ->
        IO.puts "unknown response from worker: #{inspect msg}"
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
    assert 10 / 2 != 5
  end

  test "test bool" do
    assert true
    refute false
  end

end


