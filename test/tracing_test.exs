defmodule TracingTest do
  use ExUnit.Case
  doctest Tracing

  test "greets the world" do
    assert Tracing.hello() == :world
  end
end
