defmodule SmartJoin do
  defp do_join([ el ]), do: el
  defp do_join([ el2, el1 ]), do: "#{el1} and #{el2}"
  defp do_join([ el2, el1 | tail ]), do: "#{Enum.join( Enum.reverse(tail), ", " )}, #{do_join([el2, el1])}" 
  def join(list), do: do_join Enum.reverse(list)
end

Enum.each([
  ["foo"],
  ["foo", "bar"],
  ["foo", "bar", "baz"],
  ["foo", "bar", "baz", "etc"],
], &IO.inspect(SmartJoin.join(&1)))
