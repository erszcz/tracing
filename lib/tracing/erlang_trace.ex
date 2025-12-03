defmodule Tracing.Tracer do
  def loop do
    receive do
      m -> IO.inspect(m)
    end

    loop()
  end
end

defmodule Tracing.ErlangTrace do
  @moduledoc """
  Showing an example of the Erlang `:trace` module in action.
  """

  @doc """
  The example `trace` session translated to Elixir:
  https://www.erlang.org/doc/apps/kernel/trace.html#module-trace-sessions
  """
  def example do
    tracer = spawn(&Tracing.Tracer.loop/0)

    session = :trace.session_create(:my_session, tracer, [])

    :trace.process(session, self(), true, [:call])
    :trace.function(session, {:lists, :seq, 2}, [], [])

    :lists.seq(1, 10)

    :trace.session_destroy(session)
  end
end
