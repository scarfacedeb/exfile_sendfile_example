defmodule ExfileSendfile.Router do
  use Plug.Router

  alias ExfileSendfile.Down

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/exfile" do
    file = Exfile.Tempfile.random_file!("send")
    data = :crypto.strong_rand_bytes(100000)
    File.write!(file, data, [:write])

    IO.inspect(file)
    IO.inspect(File.stat!(file))

    conn |> send_file(200, file)
  end

  get "/file" do
    {Plug.Cowboy.Conn, %{pid: connection_pid}} = conn.adapter

    Down.monitor(self())
    Down.monitor(connection_pid)

    IO.inspect(self(), label: "self")
    IO.inspect(connection_pid, label: "connection pid")

    conn2 = conn |> send_file(200, "buf")
    IO.inspect("File sent?")
    conn2
  end

  get "/briefly" do
    {:ok, path} = Briefly.create
    data = :crypto.strong_rand_bytes(20000000)  |> Base.encode32
    data = data <> "\n\n<<END>>"
    File.write!(path, data)

    {Plug.Cowboy.Conn, %{pid: connection_pid}} = conn.adapter

    Down.monitor(self(), path)
    Down.monitor(connection_pid, path)

    IO.inspect(path)
    IO.inspect(File.stat!(path) |> Map.get(:size), label: "size")

    IO.inspect(self(), label: "self")
    IO.inspect(connection_pid, label: "connection_pid")

    conn2 = conn |> send_file(200, path)
    IO.inspect(">> End request")
    conn2
  end
end
