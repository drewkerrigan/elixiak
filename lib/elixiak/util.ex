defmodule Elixiak.Util do
	def document_bucket(doc) do
		model_bucket(doc.model)
	end

	def model_bucket(mod) do
		mod.__model__(:name)
	end

	def serialize_document(doc) do
		module      = elem(doc, 0)
		pk_value    = doc.primary_key
		zipped = module.__obj__(:obj_kw, doc, primary_key: !!pk_value)
		{:ok, json} = JSON.encode(zipped)
		json
	end

	def unserialize_document(mod, json) do
		{:ok, decoded} = JSON.decode(json)
		mod.new(list_to_args(HashDict.to_list(decoded), []))
	end

	def unserialize_document(mod, key, json) do
		{:ok, decoded} = JSON.decode(json)
		mod.new([{:key, key} | list_to_args(HashDict.to_list(decoded), [])])
	end

	def list_to_args([], accum) do
		accum
	end

	def list_to_args([{key, val}|rest], accum) do
		list_to_args(rest, [{binary_to_atom(key), val}| accum])
	end
end