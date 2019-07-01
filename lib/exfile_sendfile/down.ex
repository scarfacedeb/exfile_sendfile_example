defmodule ExfileSendfile.Down do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(_) do
    IO.inspect "init"
    {:ok, %{}}
  end

  def monitor(pid) do
    GenServer.call(__MODULE__, {:monitor, pid})
  end

  def monitor(pid, path) do
    GenServer.call(__MODULE__, {:monitor, pid, path})
  end

  def handle_call({:monitor, pid}, _from, state) do
    ref = :erlang.monitor(:process, pid)
    {:reply, ref, state}
  end

  def handle_call({:monitor, pid, path}, _from, state) do
    ref = :erlang.monitor(:process, pid)
    {:reply, ref, Map.put(state, pid, path)}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason} = msg, state) do
    IO.inspect(msg, label: "DOWN")
    {path, new_state} = Map.pop(state, pid)
    IO.inspect({path, File.exists?(path)}, label: "Exists?")
    {:noreply, new_state}
  end
end
