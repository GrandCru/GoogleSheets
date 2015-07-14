defmodule Example.Mixfile do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.0.1",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def application do
    [applications: [:logger, :google_sheets], mod: {Example, []}]
  end

  defp deps do
    # In real application you would use the following to declare dependency:
    # {:google_sheets, "~> 1.0"}
    [
      {:google_sheets, path: "../"},
      {:ex_csv, "~> 0.1.3"}
    ]
  end
end
