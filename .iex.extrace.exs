# Konrad's tracing snippet
alias Tracing.ClayPigeon

trace = [
  {ClayPigeon, :_, :return_trace}
]

Code.ensure_all_loaded!(for {module, _, _} <- trace, do: module)
Extrace.calls(trace, {100, to_timeout(second: 1)})
