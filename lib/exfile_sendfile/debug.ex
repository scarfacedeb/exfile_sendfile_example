defmodule ExfileSendfile.Debug do
  alias ExfileSendfile.Down

  def gen_data(bytes) do
    size = bytes |> String.to_integer()
    data =  size |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, size)
    data <> "\n\n<<END>>"
  end

  def monitor_all(%{adapter: adapter}, path \\ nil) do
    {Plug.Cowboy.Conn, %{pid: connection_pid}} = adapter

    IO.inspect(self(), label: "self")
    IO.inspect(connection_pid, label: "connection_pid")

    Down.monitor({:request, self()}, path)
    Down.monitor({:connection, connection_pid}, path)
  end

  def filesize(path) do
    %{size: size} = File.stat!(path)
    size
  end

  def log_file(path) do
    IO.inspect(path, label: "path")
    IO.inspect(filesize(path), label: "size")
  end

  def log_request_end(conn) do
    IO.puts(">> End request")
    conn
  end
end
