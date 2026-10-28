defmodule Perritos.MixProject do
  use Mix.Project

  def project do
    [
      app: :funcional,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Las pruebas solo tocan el núcleo: no arrancan servidor ni piden el backend
      aliases: [test: "test --no-start"]
    ]
  end

  def application do
    [extra_applications: [:logger], mod: {Perritos.Application, []}]
  end

  defp deps do
    [
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      # Opción B: los datos se leen a través del backend del P1
      {:req, "~> 0.5"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
