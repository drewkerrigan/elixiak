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

	setup do
		#Abstract into an Elixiak Database type deal?
		Riak.Supervisor.start_link
		Db.configure(host: '127.0.0.1', port: 10017)
		:ok
	end

	test "ping" do
		assert(Db.ping == :pong)
	end

	test "crud operations" do
		u = User.create(key: "drew", first_name: "Drew", last_name: "Kerrigan", age: 200)
				.save!

		assert(u.last_name == "Kerrigan")
		assert(User.find("drew").first_name == "Drew")

		u.first_name("Harry").save!

		assert(User.find("drew").first_name == "Harry")

		u.delete!

		assert(User.find("drew") == nil)

		u = User.create(key: "drew", first_name: "Drew", last_name: "Kerrigan", age: 200)
			.save!

		assert(User.find("drew").first_name == "Drew")

		User.delete "drew"

		assert(User.find("drew") == nil)
	end
end