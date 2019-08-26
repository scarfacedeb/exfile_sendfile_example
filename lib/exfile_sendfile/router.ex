defmodule ExfileSendfile.Router do
  use Plug.Router
  import ExfileSendfile.Debug

  plug Plug.Logger
  plug :match
  plug :dispatch

  # Inspect when request and connection processes are going down
  get "/static" do
    monitor_all(conn)
    conn |> send_file(200, "data.txt") |> log_request_end()
  end

  # Test exfile random implementation
  get "/exfile" do
    path = Exfile.Tempfile.random_file!("send")
    File.write!(path, gen_data())

    monitor_all(conn, path)
    log_file(path)

    conn |> send_file(200, path) |> log_request_end()
  end

  # Test briefly implementation
  get "/briefly" do
    {:ok, path} = Briefly.create
    File.write!(path, gen_data())

    monitor_all(conn, path)
    log_file(path)

    conn |> send_file(200, path) |> log_request_end()
  end
end
