defmodule Elixiak.Util do
	def list_to_args([], accum) do
		accum
	end

	def list_to_args([{key, val}|rest], accum) do
		list_to_args(rest, [{binary_to_atom(key), val}| accum])
	end
end