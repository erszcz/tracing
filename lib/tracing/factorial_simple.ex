defmodule Tracing.Factorial.Simple do
  @moduledoc """
  Simple factorial implementation.

  Fun fact: the last digit of a factorial
  of every number greater than 4 is zero.
  See `m:Tracing.Factorial.FunFact` and check it yourself!
  """

  def of(0) do
    1
  end

  def of(n) when n > 0 do
    # dbg(n)
    _r = n * of(n - 1)
    # dbg(_r)
  end
end
