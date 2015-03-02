defmodule Googlesheets.Mixfile do
  use Mix.Project

  def project do
    [
      app: :google_sheets,
      version: "1.0.0",
      elixir: "~> 1.0",
      deps: deps
    ]
  end

  def application do
    [ applications: [:logger, :httpoison, :erlsom], mod: { GoogleSheets, [] } ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.5"},
      {:erlsom, github: "willemdj/erlsom"}
    ]
  end
end
