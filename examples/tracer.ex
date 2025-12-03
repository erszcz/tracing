dbg_opts = [limit: :infinity]

tf = fn
  {:trace, _pid, :call,
   {Oban.Notifiers.Phoenix, :notify, [_server, :signal = _channel, _ = _payload]}} = _trace,
  acc ->
    # {:trace, _pid, :call, {Oban.Notifiers.Phoenix, :notify, _args}} = _trace, acc ->
    dbg(_trace, dbg_opts)
    :ok

  {:trace, _pid, :call, {Oban.Queue.Producer, :handle_info, _args}} =
      _trace,
  acc ->
    if match?(
         [
           {:notification, :signal, %{"action" => "pause"}},
           %{meta: %{queue: "amazon_textract_reply"}}
         ],
         _args
       ) do
      dbg(_trace, dbg_opts)
    end

    :ok

  {:trace, _pid, :call, {Oban.Notifier, :relay, [_, _, :signal, _] = _args}} = _trace, acc ->
    # if match?(
    #     [_oban_config, _, :signal, _],
    #     _args
    #   ) do
    #  dbg(_trace, dbg_opts)
    # end
    dbg(_trace, dbg_opts)

    :ok

  {:trace, _pid, :call, {Oban, :pause_queue, _args}} = _trace, acc ->
    dbg(_trace, dbg_opts)
    :ok

  {:trace, _pid, :call, {engine, :put_meta, [_, _, :paused, _]}} = _trace, acc
  when engine in [Oban.Engine, Oban.Pro.Engines.Smart] ->
    dbg(_trace, dbg_opts)
    :ok

  {:trace, _pid, :call, {_mod, _fun, _args}} = _trace, acc ->
    # dbg(_trace, dbg_opts)
    :ok

  {:trace, _, :return_to, {:gen_server, :try_handle_info, 3}}, acc ->
    :ok

  _trace, acc ->
    # dbg(_trace, dbg_opts)
    :ok
end

:dbg.stop()
:dbg.tracer(:process, {tf, :ok})
for n <- Node.list(), do: :dbg.n(n)
:dbg.p(:all, [:call, :return_to])
:dbg.tpl(Oban, :pause_queue, [])
# :dbg.tpl(Oban, :pause_all_queues, :x)
# :dbg.tpl(Oban, :resume_queue, :x)
# :dbg.tpl(Oban, :resume_all_queues, :x)
# :dbg.tpl(Oban.Notifier, :apply_callback, :x)
:dbg.tpl(Oban.Notifiers.Phoenix, :notify, [])
:dbg.tpl(Oban.Engine, :put_meta, [])
:dbg.tpl(Oban.Pro.Engines.Smart, :put_meta, [])
:dbg.tpl(Registry, :put_meta, [])
:dbg.tpl(Oban.Queue.Producer, :handle_info, [])
:dbg.tpl(Oban.Notifier, :relay, [])
:dbg.tpl(Oban.Config, :match_ident?, :x)
Process.sleep(100)

# on the other node
Oban.pause_queue(queue: "amazon_textract_reply", node: node(), local_only: true)

# back on the first node
Process.sleep(100)
:dbg.stop()