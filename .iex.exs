defmodule IExExtras do
  def print(term) do
    opts = [limit: :infinity]
    dbg(term, opts)
    :ok
  end
end

import IExExtras, only: [print: 1]

alias :tr, as: Tr
