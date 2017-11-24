defmodule GoogleSheets.Mixfile do
  use Mix.Project

  def project do
    [
      app: :google_sheets,
      version: "2.0.11",
      elixir: "~> 1.2",
      description: description(),
      package: package(),
      deps: deps(),
      name: "GoogleSheets",
      source_url: "https://github.com/GrandCru/GoogleSheets",
      homepage_url: "https://github.com/GrandCru/GoogleSheets",
      docs: [ main: "GoogleSheets", extras: ["README.md"]],
      dialyzer: dialyzer()
    ]
  end

  def application do
    [ applications: [:logger, :httpoison, :sweet_xml], mod: { GoogleSheets, [] } ]
  end

  defp description do
    """
    OTP application for fetching and polling Google spreadsheet data in CSV format.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Janne Kaistinen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/GrandCru/GoogleSheets"}
    ]
  end

  defp deps do
    [
      {:hackney, "~> 1.4"},
      {:httpoison, "~> 0.8"},
      {:sweet_xml, "~> 0.6"},
      {:ex_doc, "~> 0.10", only: [:dev]},
      {:dialyxir, "~> 0.3", only: [:dev]}
    ]
  end

  defp dialyzer do
    [
      flags: ["-Werror_handling", "-Wrace_conditions", "-Wunderspecs", "-Wunknown"]
    ]
  end

end
