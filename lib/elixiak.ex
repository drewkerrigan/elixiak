defmodule Elixiak do
	def start_link(host, port) do
		{:ok, pid} = :riakc_pb_socket.start_link(host, port)
		pid
	end

	def ping(host, port) do
		{:ok, pid} = :riakc_pb_socket.start_link(host, port)
		IO.inspect :riakc_pb_socket.ping(pid)
	end

	def store(bucket, key, data) do
		object = :riakc_obj.new(bucket, key, data)
		pid = Elixiak.start_link('127.0.0.1', 8087)
		:riakc_pb_socket.put(pid, object)
	end

	def fetch(bucket, key) do
		pid = Elixiak.start_link('127.0.0.1', 8087)
		{:ok, object} = :riakc_pb_socket.get(pid, bucket, key)
		:riakc_obj.get_value(object)
	end

	defmodule Document do
		def bucket_from_module(mod) do
			[_|[bucket|_]] = String.split(String.downcase(atom_to_binary(mod)), ".")
			bucket
		end

		defmacro __using__(_) do
		definitions = 
		quote location: :keep do

		# Embeded functionality
		defrecord Object, [ key: nil, data: <<>> ] do
			def save(doc) do
				bucket = Document.bucket_from_module(__MODULE__)
				Elixiak.store(bucket, doc.key, doc.data)
			end
		end

		def new(key, data) do
			__MODULE__.Object.new(key: key, data: data)
		end

		def find(key) do
			bucket = Document.bucket_from_module(__MODULE__)
			__MODULE__.Object.new(key: key, data: Elixiak.fetch(bucket, key))
		end

		end 
	quote do 
	unquote(definitions) 
	end 
	end 
	end
end