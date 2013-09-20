defmodule Elixiak.Model do

	defmacro __using__(_opts) do
		quote do
			import Elixiak.Model.Document
			alias Elixiak.Util

			# Object Data Manipulation modules
			defmodule Metadata do
				def get(doc, key) do
					doc.metadata(:riakc_obj.get_user_metadata_entry(doc.metadata, key))
				end

				def get_all(doc) do
					doc.metadata(:riakc_obj.get_user_metadata_entries(doc.metadata))
				end
				
				def delete_all(doc) do
					doc.metadata(:riakc_obj.clear_user_metadata_entries(doc.metadata))
				end
				
				def delete(doc, key) do
					doc.metadata(:riakc_obj.delete_user_metadata_entry(doc.metadata, key))
				end
				
				def put(doc, {key, value}) do
					doc.metadata(:riakc_obj.set_user_metadata_entry(doc.metadata, {key, value}))
				end
			end
			
			defmodule Index do
				def index_id({:binary_index, name}) do
					"#{name}_bin"
				end

				def index_id({:integer_index, name}) do
					"#{name}_int"
				end

				def get_bin(doc, {type, name}) do
					doc.metadata(:riakc_obj.get_secondary_index(doc.metadata, {type, name}))
				end

				def get_all(doc) do
					doc.metadata(:riakc_obj.get_secondary_indexes(doc.metadata))
				end

				def delete_all(doc) do
					doc.metadata(:riakc_obj.clear_secondary_indexes(doc.metadata))
				end
				
				def delete(doc, {type, name}) do
					doc.metadata(:riakc_obj.delete_secondary_index(doc.metadata, index_id({type, name})))
				end

				def delete(doc, id) do
					doc.metadata(:riakc_obj.delete_secondary_index(doc.metadata, id))
				end

				def put(doc, {type, name}, values) do
					doc.metadata(:riakc_obj.set_secondary_index(doc.metadata, {{type, name}, values}))
				end
			end

			defmodule Link do
				def get(doc, tag) do
					doc.metadata(:riakc_obj.get_links(doc.metadata, tag))
				end

				def get_all(doc) do
					doc.metadata(:riakc_obj.get_all_links(doc.metadata))
				end

				def delete_all(doc) do
					doc.metadata(:riakc_obj.clear_links(doc.metadata))
				end

				def delete(doc, tag) do
					doc.metadata(:riakc_obj.delete_links(doc.metadata, tag))
				end

				def put(doc, mod, key) do
					doc.metadata(:riakc_obj.set_link(doc.metadata, [{mod.bucket, key}]))
				end
			end

			# Utility functions
			def bucket() do
				__MODULE__.__model__(:name)
			end

			def serialize(doc) do
				{:ok, json} = JSON.encode(__MODULE__.Obj.__obj__(:obj_kw, doc))

				key = case doc.key do
					nil -> :undefined
					value -> value
				end

				{bucket(), key, json, doc.metadata, doc.vclock}
			end

			def unserialize(nil) do nil end
			def unserialize({json, key, metadata, vclock}) do
				{:ok, decoded} = JSON.decode(json)
				candidate = __MODULE__.new(Util.list_to_args(HashDict.to_list(decoded), []))
				candidate = candidate.key(key)
				candidate = candidate.metadata(metadata)
				candidate = candidate.vclock(vclock)
			end

			def unserialize(json) do
				{:ok, decoded} = JSON.decode(json)
				__MODULE__.new(Util.list_to_args(HashDict.to_list(decoded), []))
			end
		end
	end
end

defmodule Elixiak.Model.Document do

  defmacro document(name, { :__aliases__, _, _ } = obj) do
    quote bind_quoted: [name: name, obj: obj] do
      def new(), do: unquote(obj).new()
      def new(params), do: unquote(obj).new(params)
      def __model__(:name), do: unquote(name)
      def __model__(:obj), do: unquote(obj)
    end
  end

  defmacro document(name, opts // [], [do: block]) do
    quote do
      name = unquote(name)
      opts = unquote(opts)

      defmodule Obj do
        use Elixiak.Obj, Keyword.put(opts, :model, unquote(__CALLER__.module))
        unquote(block)
      end

      document(name, Obj)
    end
  end
end