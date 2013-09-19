defmodule Db do
	use Elixiak.Database, host: '127.0.0.1', port: 8087
end

defmodule User do
	use Elixiak.Model

	document "user" do
		field :first_name, :string
		field :last_name, :string
		field :age, :integer, default: 18
	end
end

defmodule ElixiakTest do
	use ExUnit.Case

	test "save_find_delete" do
		u = User.new(key: "drew", first_name: "Drew", last_name: "Kerrigan", age: 200)
		Db.put u

		u2 = Db.find User, "drew"
		assert(u2.last_name == "Kerrigan")

		Db.delete User, "drew"

		u3 = Db.find User, "drew"
		assert(u3 == nil)
	end

	test "save_find_delete_nokey" do
		u = User.new(first_name: "Drew", last_name: "Kerrigan", age: 200)
		key = Db.put u

		u2 = Db.find User, key
		assert(u2.last_name == "Kerrigan")

		Db.delete User, key

		u3 = Db.find User, key
		assert(u3 == nil)
	end

	test "alternate_delete" do
		u = User.new(first_name: "Drew", last_name: "Kerrigan", age: 200)
		key = Db.put u

		u2 = Db.find User, key
		assert(u2.last_name == "Kerrigan")

		Db.delete u2

		u3 = Db.find User, key
		assert(u3 == nil)
	end
end