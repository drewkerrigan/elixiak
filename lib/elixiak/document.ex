defmodule Elixiak.Document do

		def bucket_from_module(mod) do
			[_|[bucket|_]] = String.split(String.downcase(atom_to_binary(mod)), ".")
			bucket
		end

		defmacro __using__(_) do
		definitions = 
		quote location: :keep do

		# Embeded functionality
		defrecord Object, [ key: nil, data: <<>> ] do
			def save!(doc) do
				bucket = Elixiak.Document.bucket_from_module(__MODULE__)
				:gen_server.call(:elixiak, { :store, bucket, doc.key, doc.data })
			end
		end

		def new(key, data) do
			__MODULE__.Object.new(key: key, data: data)
		end

		def find(key) do
			bucket = Elixiak.Document.bucket_from_module(__MODULE__)
			result = :gen_server.call(:elixiak, { :fetch, bucket, key })
			case result do
				nil -> nil
				value -> __MODULE__.Object.new(key: key, data: value)
			end
		end

		def delete(key) do
			bucket = Elixiak.Document.bucket_from_module(__MODULE__)
			:gen_server.call(:elixiak, { :delete, bucket, key })
		end

		end 
	quote do 
	unquote(definitions) 
	end 
	end 

end