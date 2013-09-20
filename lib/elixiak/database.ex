defmodule Elixiak.Database do
	use GenServer.Behaviour

	defmacro __using__(opts) do
		host = Keyword.fetch!(opts, :host)
		port = Keyword.fetch!(opts, :port)

		:gen_server.call(:elixiak, {:configure, host, port})

		quote do
			alias Elixiak.Util

			defmodule Bucket do
				def list() do :gen_server.call(:elixiak, {:list_buckets}) end
				def list(timeout) do :gen_server.call(:elixiak, {:list_buckets, timeout}) end

				def keys(mod) do :gen_server.call(:elixiak, {:list_keys, mod.bucket}) end
				def keys(mod, timeout) do :gen_server.call(:elixiak, {:list_keys, mod.bucket, timeout}) end

				def get(mod) do :gen_server.call(:elixiak, {:props, mod.bucket}) end
				def put(mod, props) do :gen_server.call(:elixiak, {:set_props, mod.bucket, props}) end
				def put(mod, type, props) do :gen_server.call(:elixiak, {:set_props, mod.bucket, type, props}) end
				def reset(mod) do :gen_server.call(:elixiak, {:reset, mod.bucket}) end

				defmodule Type do
					def get(type) do :gen_server.call(:elixiak, {:get_type, type}) end
					def put(type, props) do :gen_server.call(:elixiak, {:set_type, type, props}) end
					def reset(type) do :gen_server.call(:elixiak, {:reset_type, type}) end
				end
			end

			defmodule Mapred do
				def query(inputs, query) do :gen_server.call(:elixiak, {:mapred_query, inputs, query}) end
				def query(inputs, query, timeout) do :gen_server.call(:elixiak, {:mapred_query, inputs, query, timeout}) end
				
				defmodule Bucket do
					def query(mod, query) do :gen_server.call(:elixiak, {:mapred_query_bucket, mod.bucket, query}) end
					def query(mod, query, timeout) do :gen_server.call(:elixiak, {:mapred_query_bucket, mod.bucket, query, timeout}) end
				end
			end

			defmodule Index do
				def query(mod, {type, name}, key, opts) do 
					:gen_server.call(:elixiak, {:index_eq_query, mod.bucket, {type, name}, key, opts})
				end
				def query(mod, {type, name}, startkey, endkey, opts) do 
					:gen_server.call(:elixiak, {:index_range_query, mod.bucket, {type, name}, startkey, endkey, opts})
				end
				#TODO: auto-determine index type from field types in document definition?
			end

			defmodule Search do
				def query(mod, query, options) do :gen_server.call(:elixiak, {:search_query, mod.bucket, query, options}) end
				def query(mod, query, options, timeout) do :gen_server.call(:elixiak, {:search_query, mod.bucket, query, options, timeout}) end
				
				defmodule Index do
					def list() do :gen_server.call(:elixiak, {:search_list_indexes}) end
					def put(mod) do :gen_server.call(:elixiak, {:search_create_index, mod.bucket}) end
					def get(mod) do :gen_server.call(:elixiak, {:search_get_index, mod.bucket}) end
					def delete(mod) do :gen_server.call(:elixiak, {:search_delete_index, mod.bucket}) end
					# TODO: auto-add index to bucket props here?
				end

				defmodule Schema do
					def get(mod) do :gen_server.call(:elixiak, {:search_get_schema, mod.bucket}) end
					def create(mod, content) do :gen_server.call(:elixiak, {:search_create_schema, mod.bucket, content}) end
					# TODO: auto-create schema from field types in document definition?
				end
			end

			defmodule Counter do
				def increment(mod, name, amount) do :gen_server.call(:elixiak, {:counter_incr, "#{mod.bucket}-counter", name, amount}) end
				def value(mod, name) do :gen_server.call(:elixiak, {:counter_val, "#{mod.bucket}-counter", name}) end
			end

			def ping() do
				:gen_server.call(:elixiak, {:ping})
			end

			def put(doc) do
				:gen_server.call(:elixiak, {:store, doc.model.serialize(doc)})
			end

			def update(doc) do
				:gen_server.call(:elixiak, {:update, doc.model.serialize(doc)})
			end

			def find(mod, key) do
				case :gen_server.call(:elixiak, {:fetch, mod.bucket, key}) do
					{:ok, result} -> mod.unserialize(result)
					{:siblings, results} -> results
					result -> result
				end
			end

			def resolve(mod, key, index) do
				:gen_server.call(:elixiak, {:resolve, mod.bucket, key, index})
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
	def handle_call({:store, {bucket, key, json, _metadata, _vclock} }, _from, state) do
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
	def handle_call({:update, {bucket, key, json, metadata, vclock} }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
				updated_vclock = :riakc_obj.set_vclock(object, vclock)
		    	updated_value = :riakc_obj.update_value(updated_vclock, json)
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
				if :riakc_obj.value_count(object) > 1 do
					{ :reply, {:siblings, :riakc_obj.get_contents(object)}, state }
				else
					{ :reply, {:ok, {:riakc_obj.get_value(object), key, :riakc_obj.get_metadata(object), :riakc_obj.vclock(object)}}, state }
				end
			_ -> { :reply, nil, state }
		end
	end

	# Resolve a Riak Object
	def handle_call({:resolve, bucket, key, index }, _from, state) do
		case :riakc_pb_socket.get(state.socket_pid, bucket, key) do
			{:ok, object} ->
				new_object = :riakc_obj.select_sibling(index, object)
				{ :reply, :riakc_pb_socket.put(state.socket_pid, new_object), state }
			_ -> { :reply, nil, state }
		end
	end

	# Delete a Riak Object
	def handle_call({:delete, bucket, key }, _from, state) do
		{ :reply, :riakc_pb_socket.delete(state.socket_pid, bucket, key), state }
	end

	def handle_call({:list_buckets, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.list_buckets(state.socket_pid, timeout), state}
	end
	def handle_call({:list_buckets}, _from, state) do
		{ :reply, :riakc_pb_socket.list_buckets(state.socket_pid), state}
	end

	def handle_call({:list_keys, bucket, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.list_keys(state.socket_pid, bucket, timeout), state}
	end
	def handle_call({:list_keys, bucket}, _from, state) do
		{ :reply, :riakc_pb_socket.list_keys(state.socket_pid, bucket), state}
	end

	def handle_call({:props, bucket}, _from, state) do
		{ :reply, :riakc_pb_socket.get_bucket(state.socket_pid, bucket), state}
	end

	def handle_call({:set_props, bucket, props}, _from, state) do
		{ :reply, :riakc_pb_socket.set_bucket(state.socket_pid, bucket, props), state}
	end

	def handle_call({:set_props, bucket, type, props}, _from, state) do
		{ :reply, :riakc_pb_socket.set_bucket(state.socket_pid, {type, bucket}, props), state}
	end

	def handle_call({:reset, bucket}, _from, state) do
		{ :reply, :riakc_pb_socket.reset_bucket(state.socket_pid, bucket), state}
	end

	def handle_call({:get_type, type}, _from, state) do
		{ :reply, :riakc_pb_socket.get_bucket_type(state.socket_pid, type), state}
	end

	def handle_call({:set_type, type, props}, _from, state) do
		{ :reply, :riakc_pb_socket.set_bucket_type(state.socket_pid, type, props), state}
	end
		
	def handle_call({:reset_type, type}, _from, state) do
		{ :reply, :riakc_pb_socket.reset_bucket_type(state.socket_pid, type), state}
	end

	def handle_call({:mapred_query, inputs, query}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred(state.socket_pid, inputs, query), state}
	end
	def handle_call({:mapred_query, inputs, query, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred(state.socket_pid, inputs, query, timeout), state}
	end

	def handle_call({:mapred_query_bucket, bucket, query}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred_bucket(state.socket_pid, bucket, query), state}
	end
	def handle_call({:mapred_query_bucket, bucket, query, timeout}, _from, state) do
		{ :reply, :riakc_pb_socket.mapred_bucket(state.socket_pid, bucket, query, timeout), state}
	end

	def handle_call({:index_eq_query, bucket, {type, name}, key, opts}, _from, state) do
		{ :reply, :riakc_pb_socket.get_index_eq(state.socket_pid, bucket, {type, name}, key, opts), state}
	end
	def handle_call({:index_range_query, bucket, {type, name}, startkey, endkey, opts}, _from, state) do
		{ :reply, :riakc_pb_socket.get_index_range(state.socket_pid, bucket, {type, name}, startkey, endkey, opts), state}
	end
	
	def handle_call({:search_list_indexes}, _from, state) do
		{ :reply, :riakc_pb_socket.list_search_indexes(state.socket_pid), state}
	end

	def handle_call({:search_create_index, index}, _from, state) do
		{ :reply, :riakc_pb_socket.create_search_index(state.socket_pid, index), state}
	end

	def handle_call({:search_get_index, index}, _from, state) do
		{ :reply, :riakc_pb_socket.get_search_index(state.socket_pid, index), state}
	end

	def handle_call({:search_delete_index, index}, _from, state) do
		{ :reply, :riakc_pb_socket.delete_search_index(state.socket_pid, index), state}
	end

	def handle_call({:search_get_schema, name}, _from, state) do
		{ :reply, :riakc_pb_socket.get_search_schema(state.socket_pid, name), state}
	end

	def handle_call({:search_create_schema, name, content}, _from, state) do
		{ :reply, :riakc_pb_socket.create_search_schema(state.socket_pid, name, content), state}
	end

	def handle_call({:counter_incr, bucket, key, amount}, _from, state) do
		{ :reply, :riakc_pb_socket.counter_incr(state.socket_pid, bucket, key, amount), state}
	end

	def handle_call({:counter_val, bucket, key}, _from, state) do
		{ :reply, :riakc_pb_socket.counter_val(state.socket_pid, bucket, key), state}
	end
end