defmodule Googlesheets.Mixfile do
  use Mix.Project

  def project do
    [
      app: :google_sheets,
      version: "0.1.0",
      elixir: "~> 1.0.0",
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [ applications: [:logger, :httpoison, :erlsom], mod: { GoogleSheets, [] } ]
  end

  defp description do
    """
    Elixir library for fetching and polling Google spreadsheet data in CSV format.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Janne Kaistinen"],
      licenses: "MIT",
      links: %{"GitHub" => "https://github.com/GrandCru/GoogleSheets"}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.5"},
      {:erlsom, github: "willemdj/erlsom"},
      {:uuid, "~> 0.1.5" },
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev}
    ]
  end
end
