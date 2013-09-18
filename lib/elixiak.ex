defmodule Elixiak do
	use Application.Behaviour
	defrecord State, socket_pid: nil

	def start(_type, _state) do
		{:ok, host} = :application.get_env(:elixiak, :host)
		{:ok, port} = :application.get_env(:elixiak, :port)

		{:ok, pid} = :riakc_pb_socket.start_link(host, port)
    	state = State.new(socket_pid: pid)

		Elixiak.Supervisor.start_link(state)
	end
end