iex(mynode-a@127.0.0.1)16> Oban.check_queue(queue: "amazon_textract_reply")iex(mynode-a@127.
%{
  name: "Oban",
  node: "mynode-a@127.0.0.1",
  running: [],
  queue: "amazon_textract_reply",
  started_at: ~U[2025-10-23 10:55:30.382229Z],
  global_limit: nil,
  local_limit: 100,
  uuid: "019a10b5-a24e-7a23-9216-825da58bda50",
  rate_limit: nil,
  paused: false,
  updated_at: ~U[2025-10-23 10:58:21.729649Z],
  shutdown_started_at: nil
}


... set dbg up ...


{:trace, #PID<70631.21103.0>, :call,
 {Oban, :pause_queue, [[queue: "amazon_textract_reply", local_only: true]]}}

{:trace, #PID<70631.21103.0>, :call,
 {Oban, :pause_queue,
  [Oban, [queue: "amazon_textract_reply", local_only: true]]}}

[iex:29: (file)]
{:trace, #PID<70631.21103.0>, :call,
 {Oban.Notifiers.Phoenix, :notify,
  [
    #PID<70631.10874.0>,
    :signal,
    ["H4sIAAAAAAAAE6tWKixNLU1VslJKzE2sys+LL0mtKClKTC6JL0otyKlU0lECsjPz84AKChJLi1OBApkpqXklQL5/UmKeXm5lXn5Kqm6Sg6GRuZ4BEBoq1QIA4XMo9lQAAAA="]
  ]}}

[iex:36: (file)]
{:trace, #PID<0.5877.0>, :call,
 {Oban.Notifiers.Phoenix, :dispatch,
  [
    [..., {#PID<0.6504.0>, Oban.Notifiers.Phoenix}, ...],
    :none,
    {Oban, "mynode-b@127.0.0.1", :signal,
     ["H4sIAAAAAAAAE6tWKixNLU1VslJKzE2sys+LL0mtKClKTC6JL0otyKlU0lECsjPz84AKChJLi1OBApkpqXklQL5/UmKeXm5lXn5Kqm6Sg6GRuZ4BEBoq1QIA4XMo9lQAAAA="]}
  ]}}

{:trace, #PID<0.5877.0>, :call,
 {Oban.Notifier, :relay,
  [
    %Oban.Config{
      name: Oban,
      node: "mynode-b@127.0.0.1",
      ...
    },
    [..., #PID<0.6504.0>, ...],
    :signal,
    "H4sIAAAAAAAAE6tWKixNLU1VslJKzE2sys+LL0mtKClKTC6JL0otyKlU0lECsjPz84AKChJLi1OBApkpqXklQL5/UmKeXm5lXn5Kqm6Sg6GRuZ4BEBoq1QIA4XMo9lQAAAA="
  ]}}

{:trace, #PID<0.5877.0>, :call,
 {Oban.Config, :match_ident?,
  [
    %Oban.Config{
      name: Oban,
      node: "mynode-b@127.0.0.1",
      ...
    },
    "Oban.mynode-b@127.0.0.1"
  ]}}

{:trace, #PID<0.5877.0>, :return_from, {Oban.Config, :match_ident?, 2}, true}

{:trace, #PID<0.6504.0>, :call,
 {Oban.Queue.Producer, :handle_info,
  [
    {:notification, :signal,
     %{
       "action" => "pause",
       "ident" => "Oban.mynode-b@127.0.0.1",
       "queue" => "amazon_textract_reply"
     }},
    %Oban.Queue.Producer{
      conf: %Oban.Config{
        name: Oban,
        node: "mynode-a@127.0.0.1",
        ...
      },
      ...
    }
  ]}}


iex(mynode-a@127.0.0.1)46> notifier_pid = GenServer.whereis({:via, Registry, {Oban.Registry, {Oban, Oban.Notifier}}})
#PID<0.6255.0>
iex(mynode-a@127.0.0.1)47> :sys.get_state(notifier_pid)
%Oban.Notifiers.Phoenix{
  conf: %Oban.Config{
    name: Oban,
    node: "mynode-a@127.0.0.1",
    ...
  },
  pubsub: MyApp.PubSub.Redis
}


iex(mynode-a@127.0.0.1)51> Oban.check_queue(queue: "amazon_textract_reply")
%{
  name: "Oban",
  node: "mynode-a@127.0.0.1",
  running: [],
  queue: "amazon_textract_reply",
  started_at: ~U[2025-10-23 10:55:30.382229Z],
  global_limit: nil,
  local_limit: 100,
  uuid: "019a10b5-a24e-7a23-9216-825da58bda50",
  rate_limit: nil,
  paused: true,
  updated_at: ~U[2025-10-23 11:18:28.249878Z],
  shutdown_started_at: nil
}
