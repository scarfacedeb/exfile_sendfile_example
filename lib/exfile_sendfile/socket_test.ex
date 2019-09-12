defmodule ExfileSendfile.SocketTest do
  @moduledoc """
  Low-level code from :gen_tcp, to test out async sendfile TCP socket calls.
  """

  import ExfileSendfile.Debug

  @filename "socket_test.txt"
  @tcp_sendfile_req 66_167_597

  def run do
    File.write!(@filename, gen_data(10000))
    {:ok, file} = :file.open(@filename, [:raw, :read, :binary])

    {:ok, socket} = :gen_tcp.listen(0, port: 4433)
    {:ok, lsocket} = :gen_tcp.accept(socket)

    fd = :prim_file.get_handle(file)
    args = [fd, [0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 39, 16]]
    [1] = :erlang.port_control(lsocket, @tcp_sendfile_req, args)
  end

  def run_and_exit do
    run()
    System.stop(0)
  end
end
