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
    []
  end

  defp deps do
    [{ :riakc, git: "https://github.com/basho/riak-erlang-client.git" }]
  end
end
