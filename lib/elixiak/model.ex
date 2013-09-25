defmodule Db do
	use Riak.Client
end

defmodule Elixiak.Model do
	defmacro __using__(_opts) do
		quote do
			import Elixiak.Model.Document
			alias Elixiak.Util
      		use Riak.Object

      		def find(key) do
				from_robj(Db.find bucket, key)
			end

			def delete(key) do
				Db.delete bucket, key
			end

			# Utility functions
			def bucket() do
				__MODULE__.__model__(:name)
			end

			def from_json(json) do
				{:ok, decoded} = JSON.decode(robj.data)
				__MODULE__.create(Util.list_to_args(HashDict.to_list(decoded), []))
			end

			def from_robj(robj) do
				case robj do
					nil -> nil
					robj -> 
						{:ok, decoded} = JSON.decode(robj.data)

						__MODULE__.new(Util.list_to_args(HashDict.to_list(decoded), []))
							.key(robj.key)
							.metadata(robj.metadata)
							.vclock(robj.vclock)
							.bucket(robj.bucket)
							.content_type(robj.content_type)
				end
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