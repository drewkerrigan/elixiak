defmodule Elixiak do
	use Application.Behaviour
	defrecord State, socket_pid: nil

	def start(_type, _state) do
    	state = State.new(socket_pid: nil)

		Elixiak.Supervisor.start_link(state)
	end
end