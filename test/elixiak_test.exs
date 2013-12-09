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

	def delete_all([]) do
		:ok
	end
	def delete_all([key|rest]) do
		Riak.delete "user", key
		delete_all(rest)
	end
	def delete_all(bucket) do
		{:ok, keys} = Riak.Bucket.keys(bucket)
		delete_all(keys)
	end

	setup do
		#Abstract into an Elixiak Database module?
		Riak.start
		Riak.configure(host: '127.0.0.1', port: 8087)

		delete_all("user")
		:ok
	end

	test "ping" do
		assert(Riak.ping == :pong)
	end

	test "secondary indexes" do
		u1 = User.create(first_name: "Drew", last_name: "Kerrigan", age: 10).save!
		u2 = User.create(first_name: "Drew", last_name: "Kerrigan", age: 20).save!
		u3 = User.create(first_name: "Drew", last_name: "Kerrigan", age: 30).save!
		u4 = User.create(first_name: "Drew", last_name: "Kerrigan", age: 40).save!

		drew_results = User.find(first_name: "Drew")
		assert(is_list(drew_results))
		assert(List.last(drew_results).last_name == "Kerrigan")

		age_results = User.find(age: [20, 40])
		assert(is_list(age_results))
		assert(List.last(age_results).first_name == "Drew")

		u1.delete!
		u2.delete!
		u3.delete!
		u4.delete!
	end

	test "crud operations" do

		u = User.create(key: "drew", first_name: "Drew2", last_name: "Kerrigan", age: 200)
				.save!

		assert(u.last_name == "Kerrigan")
		assert(User.find("drew").first_name == "Drew2")

		u = User.find("drew")

		u.first_name("Harry").save!

		assert(User.find("drew").first_name == "Harry")

		u = User.find("drew")

		u.delete!

		assert(User.find("drew") == nil)

		User.create(key: "drew2", first_name: "Drew2", last_name: "Kerrigan", age: 200)
			.save!

		u = User.find("drew2")

		assert(User.find("drew2").first_name == "Drew2")

		User.delete "drew2"

		assert(User.find("drew2") == nil)
	end
end