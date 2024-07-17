defmodule Ton.MixProject do
  use Mix.Project

  def project do
    [
      app: :ton,
      version: "0.4.8",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "TON (The Open Network) SDK",
      package: [
        maintainers: ["Ayrat Badykov"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/ayrat555/ton"},
        files: [
          "mix.exs",
          "lib",
          "LICENSE",
          "README.md",
          "CHANGELOG.md"
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_pbkdf2, "~> 0.8.2"},
      {:cafezinho, "~> 0.4.2"},
      {:mnemoniac, "~> 0.1.2"},
      {:evil_crc32c, "~> 0.2.7"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
