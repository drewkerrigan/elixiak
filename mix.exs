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
    mod: { Elixiak, [] }]
  end

  defp deps do
    [{ :riakc, github: "basho/riak-erlang-client" },
     { :json,  github: "cblage/elixir-json"}]
  end
end
