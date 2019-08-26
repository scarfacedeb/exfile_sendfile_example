defmodule ExfileSendfile.Down do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def monitor(target, path \\ nil) do
    GenServer.call(__MODULE__, {:monitor, target, path})
  end

  def handle_call({:monitor, {type, pid}, path}, _from, state) do
    ref = :erlang.monitor(:process, pid)
    {:reply, ref, Map.put(state, pid, {type, path})}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason} = msg, state) do
    {{type, path}, new_state} = Map.pop(state, pid)

    IO.inspect(msg, label: type)
    log_file(path)

    {:noreply, new_state}
  end

  def log_file(path) do
    if path do
      path |> File.exists?() |> IO.inspect(label: "Exists?")
    end
  end
end
