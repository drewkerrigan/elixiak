defmodule User do
	use Elixiak.Model

	document "user" do
		field :first_name, :string, indexed: true
		field :last_name, :string, indexed: true
		field :age, :integer, default: 18, indexed: true
	end
end

defmodule ElixiakTest do
	use ExUnit.Case

	setup do
		#Abstract into an Elixiak Database module?
		Riak.start
		Riak.configure(host: '127.0.0.1', port: 10017)
		:ok
	end

	test "ping" do
		assert(Riak.ping == :pong)
	end

	test "secondary indexes" do
		User.create(first_name: "Drew", last_name: "Kerrigan", age: 10).save!
		User.create(first_name: "Drew", last_name: "Kerrigan", age: 20).save!
		User.create(first_name: "Drew", last_name: "Kerrigan", age: 30).save!
		User.create(first_name: "Drew", last_name: "Kerrigan", age: 40).save!

		drew_results = User.find(first_name: "Drew")
		assert(is_list(drew_results))
		assert(List.last(drew_results).last_name == "Kerrigan")

		age_results = User.find(age: [20, 40])
		assert(is_list(age_results))
		assert(List.last(age_results).first_name == "Drew")
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

		User.create(key: "drew", first_name: "Drew", last_name: "Kerrigan", age: 200)
			.save!

		assert(User.find("drew").first_name == "Drew")

		User.delete "drew"

		assert(User.find("drew") == nil)
	end
end