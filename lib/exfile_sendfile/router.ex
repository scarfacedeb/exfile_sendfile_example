defmodule ExfileSendfile.Router do
  use Plug.Router
  import ExfileSendfile.Debug
  alias ExfileSendfile.Temp

  plug Plug.Logger
  plug :match
  plug :dispatch

  # Inspect when request and connection processes are going down
  get "/monitor" do
    monitor_all(conn)
    conn |> send_resp(200, "BODY") |> log_request_end()
  end

  # Test exfile random implementation
  get "/exfile/:bytes" do
    path = Exfile.Tempfile.random_file!("send")
    File.write!(path, gen_data(bytes))

    monitor_all(conn, path)
    log_file(path)

    conn |> send_file(200, path) |> log_request_end()
  end

  # Test briefly implementation
  get "/briefly/:bytes" do
    {:ok, path} = Briefly.create
    File.write!(path, gen_data(bytes))

    monitor_all(conn, path)
    log_file(path)

    conn |> send_file(200, path) |> log_request_end()
  end

  # Test stripped down version
  get "/custom/:bytes" do
    {:ok, path} = Temp.create(conn)
    File.write!(path, gen_data(bytes))

    monitor_all(conn, path)
    log_file(path)

    conn |> send_file(200, path) |> log_request_end()
  end

  # Fixed version
  get "/fixed/:bytes" do
    {:ok, path} = Temp.create(self())
    File.write!(path, gen_data(bytes))

    monitor_all(conn, path)
    log_file(path)

    conn |> send_file(200, path) |> log_request_end()
  end
end
