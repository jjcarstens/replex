defmodule Replex.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/jjcarstens/replex"

  def project do
    [
      app: :replex,
      build_embedded: true,
      compilers: [:elixir_make | Mix.compilers()],
      elixir: "~> 1.9",
      deps: deps(),
      description: "Use Elixir to replay radio signals on a Raspberry Pi on GPIO 4",
      docs: docs(),
      make_clean: ["clean"],
      make_targets: ["all"],
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSE",
        "Makefile",
        "mix.exs",
        "README.md",
        "src/.keep"
      ],
      links: %{"Github" => @source_url},
      licenses: ["Apache-2.0"]
    ]
  end
end
