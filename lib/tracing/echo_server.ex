defmodule Tracing.EchoServer do
  use GenServer

  # API

  def start_link(opts) do
    opts = Enum.into(opts, %{})

    if Map.get(opts, :register, true) do
      GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    else
      GenServer.start_link(__MODULE__, %{})
    end
  end

  def echo(ref, msg), do: GenServer.call(ref, {:echo, msg})

  # Callbacks

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:echo, msg}, from, state) do
    # We don't want to block the server due to our "heavy computation",
    # so let's reply from a child process.
    spawn(fn -> do_reply(from, msg) end)

    {:noreply, state}
  end

  # Internal

  def do_reply(from, msg) do
    GenServer.reply(from, {:echoing, Time.utc_now(), msg})
  end
end
