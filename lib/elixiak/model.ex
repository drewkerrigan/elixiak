defmodule Elixiak.Model do

	defmacro __using__(_opts) do
		quote do
			import Elixiak.Model.Document

			def from_json(json) do
				Elixiak.Util.unserialize_document(__MODULE__, json)
			end

			def from_json(key, json) do
				doc = Elixiak.Util.unserialize_document(__MODULE__, key, json)
			end

			def to_json(doc) do
				Elixiak.Util.serialize_document(doc)
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