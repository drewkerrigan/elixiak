defmodule User do
	use Elixiak.Document
end

defmodule ElixiakTest do
  use ExUnit.Case

  test "save_find_delete" do
  	u1 = User.new("Drew", "hithere")
  	u1.save!
  	
  	u2 = User.find("Drew")
  	assert(u2.data == "hithere")

	User.delete("Drew")

	u3 = User.find("Drew")
  	assert(u3 == nil)
  end
end