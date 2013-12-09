defmodule Elixiak.Model do
	defmacro __using__(_opts) do
		quote do
			import Elixiak.Model.Document
			alias Elixiak.Util
      		use Riak.Object

      		def from_keys([], results) do results end
      		def from_keys([key|t], results) do
      			from_keys(t, [find(key)|results])
      		end

      		def find([{field, [st, en]}]) do
				{keys, _terms, _continuation} = Riak.Index.query(bucket, __MODULE__.Obj.__obj__(:indexes)[field], st, en, [])
				from_keys(keys, [])
			end

      		def find([{field, value}]) do
				{keys, _terms, _continuation} = Riak.Index.query(bucket, __MODULE__.Obj.__obj__(:indexes)[field], value, [])
				from_keys(keys, [])
			end

      		def find(key) do
				from_robj(Riak.find bucket, key)
			end

			def delete(key) do
				Riak.delete bucket, key
			end

			# Utility functions
			def bucket() do
				__MODULE__.__model__(:name)
			end

			def from_json(json) do
				{:ok, decoded} = JSON.decode(json)
				__MODULE__.create(Util.list_to_args(HashDict.to_list(decoded), []))
			end

			def add_indexes([], o) do
				o
			end

			def add_indexes([{name, ind}|t], o) do
				add_indexes(t, RObj.put_index(o, ind, [o.model.Obj.__obj__(:obj_kw, o)[name]]))
			end

			def add_indexes(o) do
				add_indexes(o.model.Obj.__obj__(:indexes), o)
			end

			def from_robj(nil) do
				nil
			end
			def from_robj(robj) when is_list(robj) do
				robj
			end
			def from_robj(robj) do
				{:ok, decoded} = JSON.decode(robj.data)

				add_indexes(__MODULE__.new(Util.list_to_args(HashDict.to_list(decoded), []))
					.key(robj.key)
					.metadata(robj.metadata)
					.vclock(robj.vclock)
					.bucket(robj.bucket)
					.content_type(robj.content_type))
			end

			def create() do
				__MODULE__.new()
			end
			def create(args) do
				o = __MODULE__.new(args).bucket(bucket)
				from_robj(RObj.from_robj(o.to_robj()))
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