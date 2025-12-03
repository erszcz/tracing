defmodule Tracing.Factorial.FunFact do
  @moduledoc """
  Check that the last digit of a factorial
  of every number greater than 4 is zero - check it yourself!
  """

  # 20 is close enough to infinity in our case ;)
  def check(factorial_impl, max_n \\ 20) do
    check(factorial_impl, 5, max_n)
  end

  def check(_factorial_impl, n, max_n) when n > max_n, do: true

  def check(factorial_impl, n, max_n) do
    0 == remainder(factorial_impl.of(n), 10) and check(factorial_impl, n + 1, max_n)
  end

  def remainder(n, m), do: rem(n, m)
end
