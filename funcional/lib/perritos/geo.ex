defmodule Perritos.Geo do
  @moduledoc "Geometría pura sobre coordenadas `{lat, lon}` en grados."

  @radio_tierra_m 6_371_000

  @doc """
  Distancia en metros entre dos puntos (fórmula de haversine).

      iex> Perritos.Geo.distancia_m({25.4, -100.9}, {25.4, -100.9})
      0.0
  """
  def distancia_m({lat1, lon1}, {lat2, lon2}) do
    a =
      :math.pow(:math.sin(radianes(lat2 - lat1) / 2), 2) +
        :math.cos(radianes(lat1)) * :math.cos(radianes(lat2)) *
          :math.pow(:math.sin(radianes(lon2 - lon1) / 2), 2)

    # min/2 evita que un error de redondeo (a = 1.0000000002) rompa asin
    2 * @radio_tierra_m * :math.asin(:math.sqrt(min(1.0, a)))
  end

  @doc "Grados a radianes."
  def radianes(grados), do: grados * :math.pi() / 180
end
