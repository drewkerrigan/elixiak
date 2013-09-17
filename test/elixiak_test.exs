defmodule User do
	use Elixiak.Document
end

defmodule ElixiakTest do
  use ExUnit.Case

  test "save_and_find" do
  	d = User.new("Drew", "hithere")
  	d.save
  	
  	data = User.find("Drew").data
  	assert(data == "hithere")
  end
end