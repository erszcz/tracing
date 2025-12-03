# Tracing on the BEAM

## `printf()` debugging

Trivial, but for an example see `m:Tracing.Factorial.Simple`.

Pros:
- easy

Cons:
- requires recompiling code
- required redeployment to apply in non-local environments
- impossible to instrument every function


## Printouts enabled dynamically with `:trace`

[Erlang `trace` module docs](https://www.erlang.org/doc/apps/kernel/trace.html).
See `m:Tracing.ErlangTrace` for an example in Elixir.

Pros:
- multiple independent trace sessions (new feature of the BEAM exposed by `:trace`)
- more human-readable than the tracing functions from the  `:erlang` module

Cons:
- `:trace` can't do remote tracing

Before the introduction of `:trace`, the main interface to tracing were `:erlang.trace/3` and
`:erlang.trace_pattern/2,3` functions.
Since neither `:trace` nor `:erlang.trace/3` are super handy for interactive tracing,
`:dbg` (the Erlang module, not the Elixir macro) was introduced.


## Tracing and scripting with `:dbg`

### Minimal example

```elixir
iex> :dbg.tracer()
iex> :dbg.p(:all, :call)
iex> :dbg.tpl(:lists, :seq, :x)
iex> :lists.seq(1,3)
(<0.200.0>) call lists:seq(1,3)
(<0.200.0>) returned from lists:seq/2 -> [1,2,3]
iex> :dbg.stop()
```

Nice, but `lists:seq(1,3)` is in Erlang syntax.
We can fix that, though:

```elixir
iex> :dbg.tracer(:process, {fn trace, _acc -> dbg(trace, limit: :infinity); :ok end, :ok})
iex> :dbg.p(:all, :call)
iex> :dbg.tpl(:lists, :seq, :x)
iex> :lists.seq(1,3)
[iex:11: (file)]
trace #=> {:trace, #PID<0.200.0>, :call, {:lists, :seq, [1, 3]}}

[iex:11: (file)]
trace #=> {:trace, #PID<0.200.0>, :return_from, {:lists, :seq, 2}, [1, 2, 3]}

[1, 2, 3]
iex> :dbg.stop()
```

### Tracing a single process

```elixir
iex> {:ok, echo1} = Tracing.EchoServer.start_link(%{register: false})
iex> {:ok, echo2} = Tracing.EchoServer.start_link(%{register: false})
iex> Tracing.EchoServer.echo(echo1, "aaa")
{:echoing, ~T[10:56:41.778769], "aaa"}
iex> Tracing.EchoServer.echo(echo2, "aaa")
{:echoing, ~T[10:56:44.817804], "aaa"}
iex> :dbg.tracer(:process, {fn trace, _acc -> dbg(trace, limit: :infinity); :ok end, :ok})
iex> :dbg.p(echo1, :call)
iex> :dbg.tpl(Tracing.EchoServer, :_, :x)
iex> Tracing.EchoServer.echo(echo2, "aaa")   # no trace printed
{:echoing, ~T[10:57:30.998867], "aaa"}
iex> Tracing.EchoServer.echo(echo1, "aaa")   # trace printed
{:echoing, ~T[10:57:34.893326], "aaa"}

[iex:11: (file)]
trace #=> {:trace, #PID<0.241.0>, :call,
 {Tracing.EchoServer, :handle_call,
  [
    {:echo, "aaa"},
    {#PID<0.214.0>,
     [:alias | #Reference<0.0.27395.2334650839.3829202945.194945>]},
    %{}
  ]}}


[iex:11: (file)]
trace #=> {:trace, #PID<0.241.0>, :return_from, {Tracing.EchoServer, :handle_call, 3},
 {:noreply, %{}}}
iex> :dbg.stop()
```

### Tracing a process and its children with `sos` - Set On Spawn

```elixir
iex> :dbg.tracer(:process, {fn trace, _acc -> dbg(trace, limit: :infinity); :ok end, :ok})
iex> {:ok, echo1} = Tracing.EchoServer.start_link(%{register: false})
iex> :dbg.p(echo1, [:call, :sos])  # sos - Set On Spawn
iex> :dbg.tpl(Tracing.EchoServer, :_, :x)
iex> Tracing.EchoServer.echo(echo1, "asd")
[iex:1: (file)]
trace #=> {:trace, #PID<0.208.0>, :call,
 {Tracing.EchoServer, :handle_call,
  [
    {:echo, "asd"},
    {#PID<0.200.0>, [:alias | #Reference<0.0.25603.1727269253.1415905286.1022>]},
    %{}
  ]}}

[iex:1: (file)]
trace #=> {:trace, #PID<0.208.0>, :return_from, {Tracing.EchoServer, :handle_call, 3},
 {:noreply, %{}}}

[iex:1: (file)]
trace #=> {:trace, #PID<0.209.0>, :call,
 {Tracing.EchoServer, :"-handle_call/3-fun-0-",
  [
    {#PID<0.200.0>, [:alias | #Reference<0.0.25603.1727269253.1415905286.1022>]},
    "asd"
  ]}}

[iex:1: (file)]
trace #=> {:trace, #PID<0.209.0>, :call,
 {Tracing.EchoServer, :do_reply,
  [
    {#PID<0.200.0>, [:alias | #Reference<0.0.25603.1727269253.1415905286.1022>]},
    "asd"
  ]}}

[iex:1: (file)]
trace #=> {:trace, #PID<0.209.0>, :return_from, {Tracing.EchoServer, :do_reply, 2}, :ok}

[iex:1: (file)]
trace #=> {:trace, #PID<0.209.0>, :return_from,
 {Tracing.EchoServer, :"-handle_call/3-fun-0-", 2}, :ok}

{:echoing, ~T[11:11:01.821091], "asd"}
iex> Tracing.EchoServer.echo(echo1, "asd")  # similar log, but note the pid of the child process
```

There's also `sofs` available - Set On First Spawn - to single out the
first spawned child process and start tracing it.


### Remote tracing

Remote tracing - let's run two terminals side by side, one `iex` session in each:

```elixir
$ iex --sname a@localhost
iex(a@localhost)1> Node.connect(:b@localhost)
iex(a@localhost)2> :dbg.tracer(:process, {fn trace, _acc -> dbg(trace, limit: :infinity); :ok end, :ok})
iex(a@localhost)3> for node <- Node.list(), do: :dbg.n(node)
[ok: :b@localhost]
iex(a@localhost)4> :dbg.p(:all, :call)
{:ok, [{:matched, :a@localhost, 78}, {:matched, :b@localhost, 77}]}
iex(a@localhost)5> :dbg.tpl(:lists, :seq, :x)

# here we call :lists.seq(1, 3) in the other iex session, that's on the other BEAM node

[iex:2: (file)]
trace #=> {:trace, #PID<14232.121.0>, :call, {:lists, :seq, [1, 3]}}

[iex:2: (file)]
trace #=> {:trace, #PID<14232.121.0>, :return_from, {:lists, :seq, 2}, [1, 2, 3]}

iex(a@localhost)6>
```

```elixir
$ iex --sname b@localhost
iex(b@localhost)1> :lists.seq(1, 3)  # see the trace log in the first iex session
[1, 2, 3]
```


### Pros and cons

Pros:
- tracing selected processes, only exported functions or exported and
  internal, tracing returns or not
- tracing points to which we return - handy to figure out which call
  site we were called from
- trace scripts - custom functions to run on traces:
    * simple profilers / call stats
    * precise filters on arguments per call
    * tracing on more/fewer events enabled dynamically

Cons:
- repetitive, tedious, and flooding with information
    * manually cleaned up and edited trace log: https://github.com/oban-bg/oban/issues/1314#issuecomment-3436499440
    * raw logs and tracer script from debugging Oban: https://gist.github.com/erszcz/f98d3ac13e25696ce2924c0c1835912a
- it's compelling to print out less info or trace fewer modules or processes,
  but then during investigation we might lose the track of execution / miss the most important details


## Snippets

It's handy to have snippets file for refining the trace patterns and script - see `examples/tracer.ex` for an example.

It might be convenient to start tracing automatically on iex startup or import some utilities.
See example IEX configs:
- `.iex.exdoctor.exs`
- `.iex.extrace.exs`


## Recording traces with ExDoctor

- [ExDoctor home](https://github.com/chrzaszcz/ex_doctor)
- [Guess Less with Erlang Doctor](https://docs.google.com/presentation/d/e/2PACX-1vRvoAs2C2Ba_bMypAM5KDLR4qdlh_sbhe3A7jmcYLPFcfHY8U0NeMC-gzXm4kYj5GPJRM_r_6-q8PWb/pub?start=false&loop=false&delayms=3000&slide=id.g797385e2b6_0_0)
- [Making your system debuggable](https://docs.google.com/presentation/d/e/2PACX-1vSDYzM28lxV4n89E9FzdgTxGJg13G2R_I2-ypBwxMRt3SG6ryPl5wl_ofSqecGB4nmX5bi5wLbTBMm3/pub?start=false&loop=false&delayms=3000&slide=id.g797385e2b6_0_0)

Let's use `.iex.exdoctor.exs` as our `.iex.exs`:

```
cp .iex.exdoctor.exs .iex.exs
```

Let's get the traces:

```elixir
iex> Tr.trace_app(:tracing)
:ok
iex> Tracing.Factorial.FunFact.check(Tracing.Factorial.Simple)
true
iex> Tracing.Factorial.FunFact.check(Tracing.Factorial.TailRec)  # why false?
false
iex> Tr.stop_tracing()
iex> Tr.dump("traces.ets")
:ok
```

The traces are now safe on disk, so we can analyse them on a different machine,
resume the next day, etc.

We'll use `traces.ets` saved in the repo, so that trace numbers between
the file and this document match.

```elixir
iex> Tr.load("traces.ets")
iex> import ExDoctor  # to get the `tr` record in the shell
iex> Tr.select(fn tr(data: false) = t -> t end)         # uses record pattern matching with :ets.select
iex> Tr.filter(fn t -> Tr.contains_data(false, t) end)  # uses any boolean predicate
iex> Tr.traceback(736)  # all calls leading up to trace 736, latest call/trace first
iex> Tr.traceback(736, %{order: :bottom_up})  # as above, but in order of calling
iex> Tr.range(507)  # all calls leading to trace 511 and their return values
iex> Tr.range(507) |> length
iex> Tr.range(507) |> print  # analyse bottom-up to see that at some point remainder(fac(n), 10) = 1
iex> Tr.range(507) |> Enum.drop(210) |> print  # print just the tail
```

Please note that `~c"\r"` in

```elixir
  {:tr, 718, #PID<0.200.0>, :call, {Tracing.Factorial.TailRec, :of, 1}, ~c"\r",
   1764769309092601, :no_info}
```

Actually stands for 13 - it's a quirk of how Erlang/Elixir handle printing
strings (lists of small integers):

```elixir
iex> [n] = ~c"\r"
~c"\r"
iex> n
13
```


### Copying traces from remote environments for local analysis

Tracing in an ECS container:

```
$ myapp_iex.sh staging backend-worker
No IP address provided. Using random task: arn:aws:ecs:eu-west-1:723258730172:task/myapp-staging/eee223583ec741f68dce6486e5fa1ecc
...
iex> :ssl.start; :inets.start; \
  for p <- ["erlang_doctor/master/src/tr.erl", "ex_doctor/main/lib/ex_doctor.ex"] do \
    {:ok, {{_, 200, _}, _, src}} = :httpc.request("https://raw.githubusercontent.com/chrzaszcz/" <> p); \
    tp = "/tmp/" <> Path.basename(p); File.write!(tp, src); c tp \
  end; \
  import ExDoctor; :tr.start
iex> alias :tr, as: Tr
iex> Tr.start()
     # tracing whatever we want to trace, for example:
iex> modules = :application.get_all_key(:myapp) |> then(fn {:ok, env} -> env[:modules] end)
iex> Tr.trace(modules)
     # or
iex> Tr.trace_app(:myapp)
     # when done
iex> Tr.stop_tracing()
iex> Tr.dump("/tmp/traces.ets")
```

Copying small files directly from an ECS container:

```
$ myapp_iex.sh staging backend-worker
No IP address provided. Using random task: arn:aws:ecs:eu-west-1:723258730172:task/myapp-staging/eee223583ec741f68dce6486e5fa1ecc
...
iex(myapp@172.19.0.188)1> File.write!("/tmp/staging-testfile", "Ala ma kota")
:ok
```

```
$ export TASK_ARN=arn:aws:ecs:eu-west-1:723258730172:task/myapp-staging/eee223583ec741f68dce6486e5fa1ecc
$ aws ecs execute-command \
    --region eu-west-1 --cluster myapp-staging --task "$TASK_ARN" --container backend  --interactive \
    --command "sh -c 'echo START; gzip --stdout /tmp/staging-testfile | base64; echo END'" \
    | awk '/START/{include=1; next} /END/{include=0} include' - | base64 -d | gunzip ; echo
```

Uploading traces to S3 and generating a presigned URL for quick download:

```elixir
workspace_id = "0196afeb-2919-7dc4-bbdc-bb5a44ca3564"
key = "radek.szymczyszyn/traces.ets"
file_content = File.read!("/tmp/traces.ets")

{:ok, _headers} = MyApp.Storage.upload_bytes(workspace_id, key, file_content)
{:ok, _download_url} = MyApp.Storage.sign_download_url(workspace_id, key)
```


<!--
**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tracing` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tracing, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/tracing>.
-->
