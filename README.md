# Elixiak

An OO-dispatch style active-record-like wrapper for riak-elixir-client. If you prefer pure functional style usage, please use riak-elixir-client.

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

###Connect to Riak

```
Riak.start
Db.configure(host: '127.0.0.1', port: 10017)
```

###Create a model with an embedded document

This functionality is inspired by and derived from [Ecto](https://github.com/elixir-lang/ecto) by [Elixir Lang](http://elixir-lang.org/). For more information about the embedded document specifics, it is currently derived from Ecto's queryable macro and entity module.

Specifying the "indexed: true" will automatically add that field and it's value as a secondary index in Riak

```
defmodule User do
  use Elixiak.Model

  document "user" do
    field :first_name, :string, indexed: true
    field :last_name, :string
    field :age, :integer, default: 18, indexed: true
  end
end
```

###Save a value

With a key

```
User.create(key: "drew", first_name: "Drew", last_name: "Kerrigan", age: 200).save!
```

Without a key

```
user = User.create(first_name: "Drew", last_name: "Kerrigan", age: 200).save!
user.key
```

From JSON

```
User.from_json(json_string).save!
```

###Find an object

```
User.find(key)
```

###Using Secondary Index (Equality Query)

```
User.find(first_name: "Drew")
```
###Using Secondary Index (Range Query)

```
User.find(age: [20, 40])
```

###Delete an object

Using key

```
User.delete key
```

Or object

```
user.delete!
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