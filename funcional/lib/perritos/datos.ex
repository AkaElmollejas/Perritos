defmodule Perritos.Datos do
  @moduledoc """
  CÁSCARA (opción B): lee los avistamientos del backend del P1 por HTTP con
  `Req` y los convierte en structs para el núcleo. El núcleo nunca sabe de
  dónde vinieron.
  """

  alias Perritos.{Avistamiento, Colores}

  def avistamientos do
    case Req.get(url()) do
      {:ok, %Req.Response{status: 200, body: lista}} when is_list(lista) ->
        {:ok, Enum.map(lista, &a_avistamiento/1)}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:status, status}}

      {:error, error} ->
        {:error, error}
    end
  end

  # Dentro de Docker se usa el nombre del servicio (backend), no localhost
  defp url, do: System.get_env("BACKEND_URL", "http://backend:8000") <> "/api/avistamientos"

  # Req ya decodificó el JSON: son mapas con llaves de texto
  defp a_avistamiento(m) do
    %Avistamiento{
      id: m["id"],
      nombre: m["nombre"],
      raza: m["raza"],
      colores: Colores.de_textos(m["colores"]),
      lat: m["lat"],
      lon: m["lon"],
      foto: m["foto"],
      fecha: NaiveDateTime.from_iso8601!(m["fecha"])
    }
  end
end
