defmodule ExfileSendfile.Temp do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def create(%{adapter: adapter}) do
    {Plug.Cowboy.Conn, %{pid: connection_pid}} = adapter
    create(connection_pid)
  end

  def create(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:create, pid})
  end

  def init(:ok) do
    {:ok, File.cwd!}
  end

  def handle_call({:create, pid}, _, dir) do
    :erlang.monitor(:process, pid)

    path = path(dir)
    :ok = :file.write_file(path, "", [:write, :raw, :exclusive, :binary])
    IO.puts("File created")

    {:reply, {:ok, path}, dir}
  end

  def handle_call({:monitor, pid}, _, dir) do
    :erlang.monitor(:process, pid)
    {:reply, {:ok, path(dir)}, dir}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason} = msg, dir) do
    :ok = :file.delete path(dir)
    IO.puts("File deleted!")

    {:noreply, dir}
  end

  def path(dir), do: Path.join([dir, "temp.txt"])
end
