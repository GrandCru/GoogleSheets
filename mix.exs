defmodule Googlesheets.Mixfile do
  use Mix.Project

  def project do
    [
      app: :google_sheets,
      version: "0.1.2",
      elixir: "~> 1.0.0",
      description: description,
      package: package,
      deps: deps
    ]
  end

  def application do
    [ applications: [:logger, :httpoison, :sweet_xml], mod: { GoogleSheets, [] } ]
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
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/GrandCru/GoogleSheets"}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.7.0"},
      {:uuid, "~> 1.0.1" },
      {:sweet_xml, "~> 0.2.1"},
      {:earmark, "~> 0.1.17", only: :dev},
      {:ex_doc, "~> 0.7.3", only: :dev},
      {:hackney, "~> 1.1.0"}
    ]
  end
end
