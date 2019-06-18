defmodule ExfileSendfile.Router do
  use Plug.Router

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
end
