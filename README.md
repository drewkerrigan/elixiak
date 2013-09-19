# Elixiak

Elixir wrapper for riak-erlang-client

###Setup

Add this project as a depency in your mix.exs

```
defp deps do
	[{ :elixiak, github: "drewkerrigan/elixiak" }]
end
```

Install dependencies

```
mix deps.get
```

Compile

```
mix
```

###Create a reference to your Riak instance

```
defmodule Db do
	use Elixiak.Database, host: '127.0.0.1', port: 8087
end
```

###Create a model with an embedded document

This functionality is inspired by and derived from [Ecto](https://github.com/elixir-lang/ecto) by [Elixir Lang](http://elixir-lang.org/). For more information about the embedded document specifics, it is currently derived from Ecto's queryable macro and entity module.

```
defmodule User do
	use Elixiak.Model

	document "user" do
		field :first_name, :string
		field :last_name, :string
		field :age, :integer, default: 18
	end
end
```

###Save a value

With a key

```
user = User.new(key: "drew", first_name: "Drew", last_name: "Kerrigan", age: 200)
Db.put user
```

Without a key

```
user = User.new(first_name: "Drew", last_name: "Kerrigan", age: 200)
key = Db.put user
```

From JSON

```
user = User.unserialize(json_string)
Db.put user
```

###Find an object

```
user = Db.find User, key
assert(u2.last_name == "Kerrigan")
```

###Update an object

```
user = user.first_name("Harry")
Db.update user
```

###Delete an object

Using key

```
Db.delete User, key
```

Or object

```
Db.delete user
```

###Run tests

```
mix test
```

### License

Copyright 2012-2013 Drew Kerrigan.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.