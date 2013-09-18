defmodule Elixiak.Server do
	use GenServer.Behaviour

	def start_link(state) do
		:gen_server.start_link({ :local, :elixiak }, __MODULE__, state, [])
	end

	def init(state) do
		{ :ok, state }
	end

	def handle_call({ :ping }, _from, state) do
  		{ :reply, :riakc_pb_socket.ping(state.socket_pid), state }
	end

	def handle_call({:store, bucket, key, data }, _from, state) do
		object = :riakc_obj.new(bucket, key, data)
		{ :reply, :riakc_pb_socket.put(state.socket_pid, object), state }
	end

	def handle_call({:fetch, bucket, key }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
		    	{ :reply, :riakc_obj.get_value(object), state }
			_ ->
				{ :reply, nil, state }
		end
	end

	def handle_call({:delete, bucket, key }, _from, state) do
		{ :reply, :riakc_pb_socket.delete(state.socket_pid, bucket, key), state }
	end
end