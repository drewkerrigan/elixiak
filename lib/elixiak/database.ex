defmodule Elixiak.Database do
	use GenServer.Behaviour

	defmacro __using__(opts) do
		host = Keyword.fetch!(opts, :host)
		port = Keyword.fetch!(opts, :port)

		:gen_server.call(:elixiak, {:configure, host, port})

		quote do
			alias Elixiak.Util

			def put(doc) do
				:gen_server.call(:elixiak, {:store, doc.model.serialize(doc)})
			end

			def update(doc) do
				:gen_server.call(:elixiak, {:update, doc.model.serialize(doc)})
			end

			def find(mod, key) do
				mod.unserialize(:gen_server.call(:elixiak, {:fetch, mod.bucket, key}))
			end

			def delete(doc) do delete(doc.model, doc.key) end
			def delete(mod, key) do
				:gen_server.call(:elixiak, {:delete, mod.bucket, key})
			end
		end
	end

	def start_link() do
		:gen_server.start_link({ :local, :elixiak }, __MODULE__, nil, [])
	end

	def init() do
		{ :ok, nil }
	end

	# Start Link to Riak
	def handle_call({ :configure, host, port }, _from, _state) do
    	{:ok, pid} = :riakc_pb_socket.start_link(host, port)
		new_state = Elixiak.State.new(socket_pid: pid)
		{ :reply, {:ok, pid}, new_state }
  	end

	# Ping Riak
	def handle_call({ :ping }, _from, state) do
  		{ :reply, :riakc_pb_socket.ping(state.socket_pid), state }
	end

	# Store a Riak Object
	# TODO, you'll need to use the metadata to store 2i stuff, need to rethink this a bit because an object is needed earlier than thought
	def handle_call({:store, {bucket, key, json, _metadata} }, _from, state) do
		object = :riakc_obj.new(bucket, key, json, "application/json")

		case :riakc_pb_socket.put(state.socket_pid, object) do
			{:ok, new_object} ->
				key = :riakc_obj.key(new_object)
				{ :reply, key, state }
			result ->
				{ :reply, result, state }
		end
	end

	# Update a Riak Object
	def handle_call({:update, {bucket, key, json, metadata} }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
		    	updated_value = :riakc_obj.update_value(object, json)
				updated_md = :riakc_obj.update_metadata(updated_value, metadata)

				case :riakc_pb_socket.put(state.socket_pid, updated_md) do
					{:ok, new_object} ->
						key = :riakc_obj.key(new_object)
						{ :reply, key, state }
					result ->
						{ :reply, result, state }
				end
			_ -> { :reply, nil, state }
		end
	end

	# Fetch a Riak Object
	def handle_call({:fetch, bucket, key }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
				{ :reply, {:riakc_obj.get_value(object), key, :riakc_obj.get_metadata(object)}, state }
			_ -> { :reply, nil, state }
		end
	end

	# Delete a Riak Object
	def handle_call({:delete, bucket, key }, _from, state) do
		{ :reply, :riakc_pb_socket.delete(state.socket_pid, bucket, key), state }
	end
end

# new(Bucket, Key) ->
# new(Bucket, Key, Value) ->
# new(Bucket, Key, Value, ContentType) ->
# vclock(O) ->
# value_count(#riakc_obj{contents=Contents}) -> 
# select_sibling(Index, O) ->
# get_contents(O) ->
# get_metadata(O=#riakc_obj{}) ->
# get_metadatas(#riakc_obj{contents=Contents}) ->
# get_content_type(Object=#riakc_obj{}) ->
# get_content_types(Object=#riakc_obj{}) ->
# get_value(#riakc_obj{}=O) ->
# get_values(#riakc_obj{contents=Contents}) ->
# update_metadata(Object=#riakc_obj{}, M) ->
# update_content_type(Object=#riakc_obj{}, CT) when is_binary(CT) ->
# update_value(Object=#riakc_obj{}, V) -> Object#riakc_obj{updatevalue=V}.
# set_vclock(Object=#riakc_obj{}, Vclock) ->
# get_user_metadata_entry(MD, Key) ->
# get_user_metadata_entries(MD) ->
# clear_user_metadata_entries(MD) ->
# delete_user_metadata_entry(MD, Key) ->
# set_user_metadata_entry(MD, {Key, Value}) ->
# get_secondary_index(MD, {Type, Name}) ->
# get_secondary_indexes(MD) ->
# clear_secondary_indexes(MD) ->
# delete_secondary_index(MD, IndexId) ->

# set_secondary_index(MD, []) ->
# set_secondary_index(MD, {{binary_index, Name}, BinList}) ->
# set_secondary_index(MD, {{integer_index, Name}, IntList}) ->
# set_secondary_index(MD, [{{binary_index, Name}, BinList} | Rest]) ->
# set_secondary_index(MD, [{{integer_index, Name}, IntList} | Rest]) ->
# set_secondary_index(MD, [{Id, BinList} | Rest]) when is_binary(Id) ->

# add_secondary_index(MD, []) ->
# add_secondary_index(MD, {{binary_index, Name}, BinList}) ->
# add_secondary_index(MD, {{integer_index, Name}, IntList}) ->
# add_secondary_index(MD, [{{binary_index, Name}, BinList} | Rest]) ->
# add_secondary_index(MD, [{{integer_index, Name}, IntList} | Rest]) ->
# add_secondary_index(MD, [{Id, BinList} | Rest]) when is_binary(Id) ->

# get_links(MD, Tag) ->
# get_all_links(MD) ->
# clear_links(MD) ->
# delete_links(MD, Tag) ->
# set_link(MD, []) ->
# set_link(MD, Link) when is_tuple(Link) ->
# set_link(MD, [{T, IdList} | Rest]) ->
# add_link(MD, []) ->
# add_link(MD, Link) when is_tuple(Link) ->
# add_link(MD, [{T, IdList} | Rest]) ->