defmodule Elixiak.Database do
	defmacro __using__(opts) do
		host = Keyword.fetch!(opts, :host)
		port = Keyword.fetch!(opts, :port)

		:gen_server.call(:elixiak, { :configure, host, port })

		quote do
			def put(doc) do
				bucket = Elixiak.Util.document_bucket(doc)
				json = doc.model.to_json(doc)

				key = case doc.primary_key do
					nil -> :undefined
					value -> value
				end
				
				:gen_server.call(:elixiak, { :store, bucket, key, json })
			end

			def find(mod, key) do
				bucket = Elixiak.Util.model_bucket(mod)
				result = :gen_server.call(:elixiak, { :fetch, bucket, key })

				case result do
					nil -> nil
					value -> 
						mod.from_json(key, value)
				end
			end

			def delete(doc) do delete(doc.model, doc.primary_key) end
			def delete(mod, key) do
				bucket = Elixiak.Util.model_bucket(mod)

				:gen_server.call(:elixiak, { :delete, bucket, key })
			end
		end
	end
end