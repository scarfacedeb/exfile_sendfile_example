defmodule ExfileSendfile.Debug do
  alias ExfileSendfile.Down
  require Logger

  def gen_data(bytes) when is_binary(bytes) do
    bytes |> String.to_integer() |> gen_data()
  end

  def gen_data(bytes) do
    bytes |> :crypto.strong_rand_bytes() |> Base.encode64() |> binary_part(0, bytes)
  end

  def monitor_all(%{adapter: adapter}, path \\ nil) do
    connection_pid =
      case adapter do
        {Plug.Cowboy.Conn, %{pid: pid}} -> pid
        _ -> self()
      end

    Logger.info(inspect(self()), label: "self")
    # Logger.info(inspect(connection_pid), label: "connection_pid")

    Down.monitor({:request, self()}, path)
    # Down.monitor({:connection, connection_pid}, path)
  end

  def filesize(path) do
    %{size: size} = File.stat!(path)
    size
  end

  def log_request_end(conn) do
    Logger.info(">> End request")
    conn
  end
end
