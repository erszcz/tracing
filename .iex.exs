defmodule IExExtras do
  def page(enumerable, n, size \\ 20) do
    enumerable
    |> Enum.drop(n * size)
    |> Enum.take(size)
  end

  def print(term) do
    opts = [limit: :infinity]
    dbg(term, opts)
    :ok
  end
end

import IExExtras
import ExDoctor

alias :tr, as: Tr
