defmodule Hypermedia.Mixfile do
  use Mix.Project

  def project do
    [app: :hypermedia,
     version: "0.0.1",
     elixir: "~> 1.2-rc",
     description: "A Elixir library for creating HAL/JSON Hypermedia APIs",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.11", only: :dev}]
  end

  defp package do
    [
      maintainers: ["Jurriaan Pruis"],
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/jurriaan/hypermedia",
        "Docs" => "https://hexdocs.pm/hypermedia/"
      }
    ]
  end
end
