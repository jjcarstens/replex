defmodule Replex.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :replex,
      build_embedded: true,
      # TODO: Support compiling sendiq
      # compilers: [:elixir_make | Mix.compilers()],
      elixir: "~> 1.9",
      deps: deps(),
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
      {:ex_doc, "~> 0.21", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/jjcarstens/replex"
    ]
  end

  defp package do
    [
      links: %{"Github" => "https://github.com/jjcarstens/replex"}
    ]
  end
end
