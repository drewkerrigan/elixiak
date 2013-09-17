# Elixiak

Elixir wrapper for riak-erlang-client

###Setup

Install dependencies

```
mix deps.get
```

Compile

```
mix
```

###Add functionality to your existing model module

```
defmodule User do
	use Elixiak.Document
end
```

###Save a value

```
d = User.new("Drew", "hithere")
d.save
```

###Find a value

```
data = User.find("Drew").data
assert(data == "hithere")
```

###Run tests

```
mix test
```