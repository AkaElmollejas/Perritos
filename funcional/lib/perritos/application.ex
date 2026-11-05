defmodule Perritos.Application do
  @moduledoc "Arranca el servidor HTTP (Bandit) que ejecuta el router."
  use Application

  def start(_tipo, _args) do
    hijos = [{Bandit, plug: Perritos.Router, port: puerto()}]
    Supervisor.start_link(hijos, strategy: :one_for_one, name: Perritos.Supervisor)
  end

  defp puerto, do: "PORT" |> System.get_env("4000") |> String.to_integer()
end
