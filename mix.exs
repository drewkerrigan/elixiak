defmodule Elixiak.Mixfile do
  use Mix.Project

  def project do
    [ app: :elixiak,
      version: "0.0.1",
      elixir: "~> 0.10.2",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [:elixiak],
    mod: { Elixiak, [] },
    env: [host: '127.0.0.1', port: 8087] ]
  end

  defp deps do
    [{ :riakc, git: "https://github.com/basho/riak-erlang-client.git" }]
  end
end
