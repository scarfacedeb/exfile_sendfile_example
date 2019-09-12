defmodule ExfileSendfile.Application do
  use Application
  use Tracer

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: ExfileSendfile.Router, options: [port: 4422, timeout: 100]),
      ExfileSendfile.Down,
      ExfileSendfile.Temp
    ]
    opts = [strategy: :one_for_one, name: ExfileSendfile.Supervisor]

    start_trace()
    Supervisor.start_link(children, opts)
  end

  def start_trace do
    run Display, process: :all,  max_tracing_time: :timer.minutes(10), match: global :erlang.port_control(port, 66167597, args)
  end
end
