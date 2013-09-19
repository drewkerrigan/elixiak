defmodule Elixiak do
	use Application.Behaviour
	defrecord State, socket_pid: nil

	def start(_type, _state) do
		Elixiak.Supervisor.start_link()
	end
end