defmodule ExfileSendfile.Application do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, ExfileSendfile.Router, [], [port: 4422])
    ]
    opts = [strategy: :one_for_one, name: ExfileSendfile.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
