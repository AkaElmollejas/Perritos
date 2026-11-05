defmodule Perritos.Zonas do
  @moduledoc """
  Núcleo de *zonas de concentración*: divide el mapa en una cuadrícula de
  celdas de `tam_m` metros y cuenta cuántos perros hay en cada una.
  El frontend solo pinta los rectángulos que regresa `resumen/2`.

  La cuadrícula es **global** (se calcula con una latitud de referencia fija)
  para que una misma coordenada siempre caiga en la misma celda.
  """

  alias Perritos.Geo

  @metros_por_grado 111_320.0
  @latitud_referencia 25.44

  # ---------- Coordenada -> celda (pura) ----------

  @doc """
  Celda `{fila, columna}` que contiene el punto `{lat, lon}`.

      iex> Perritos.Zonas.celda({25.44, -100.99}, 500) == Perritos.Zonas.celda({25.4401, -100.9901}, 500)
      true
  """
  def celda({lat, lon}, tam_m) when tam_m > 0 do
    {entero(lat / paso_lat(tam_m)), entero(lon / paso_lon(tam_m))}
  end

  @doc """
  Rectángulo (en grados) de una celda, para dibujarlo en el mapa.
  """
  def limites({fila, columna}, tam_m) do
    %{
      sur: fila * paso_lat(tam_m),
      norte: (fila + 1) * paso_lat(tam_m),
      oeste: columna * paso_lon(tam_m),
      este: (columna + 1) * paso_lon(tam_m)
    }
  end

  defp paso_lat(tam_m), do: tam_m / @metros_por_grado
  defp paso_lon(tam_m), do: tam_m / (@metros_por_grado * :math.cos(Geo.radianes(@latitud_referencia)))
  defp entero(x), do: x |> Float.floor() |> trunc()

  # ---------- Orden superior ----------

  @doc """
  **Regresa una función** que convierte un avistamiento en su celda.

      iex> a_celda = Perritos.Zonas.celdador(500)
      iex> a_celda.(%{lat: 25.44, lon: -100.99}) == Perritos.Zonas.celda({25.44, -100.99}, 500)
      true
  """
  def celdador(tam_m), do: fn %{lat: lat, lon: lon} -> celda({lat, lon}, tam_m) end

  # ---------- Recursión explícita ----------

  @doc """
  **Recibe una función** (`clasificar`, avistamiento -> clave) y cuenta
  cuántos avistamientos caen en cada clave. Recursión explícita con acumulador.

      iex> Perritos.Zonas.contar_celdas([%{n: 1}, %{n: 2}, %{n: 1}], & &1.n)
      %{1 => 2, 2 => 1}
      iex> Perritos.Zonas.contar_celdas([], & &1.n)
      %{}
  """
  def contar_celdas(avistamientos, clasificar), do: contar_celdas(avistamientos, clasificar, %{})

  defp contar_celdas([], _clasificar, acc), do: acc

  defp contar_celdas([a | resto], clasificar, acc) do
    contar_celdas(resto, clasificar, Map.update(acc, clasificar.(a), 1, &(&1 + 1)))
  end

  # ---------- Zonas y resumen ----------

  @doc "Lista de zonas con su total, de la más a la menos concentrada."
  def zonas(avistamientos, tam_m) do
    avistamientos
    |> contar_celdas(celdador(tam_m))
    |> Enum.map(fn {{fila, columna} = celda, total} ->
      Map.merge(%{fila: fila, columna: columna, total: total}, limites(celda, tam_m))
    end)
    |> Enum.sort_by(&{-&1.total, &1.fila, &1.columna})
  end

  @doc """
  Zonas más el total de perros contados (con `reduce`). Con `origen`
  (`{lat, lon}`, tu ubicación) indica también a qué distancia queda la zona
  **más concentrada** y la zona con perros **más cercana**.
  """
  def resumen(avistamientos, tam_m, origen \\ nil) do
    zonas = zonas(avistamientos, tam_m)

    %{
      tam_m: tam_m,
      total: Enum.reduce(zonas, 0, fn zona, suma -> suma + zona.total end),
      zonas: zonas,
      mas_concentrada: mas_concentrada(zonas, origen),
      mas_cercana: mas_cercana(zonas, origen)
    }
  end

  # `zonas/2` ya viene ordenada: la primera es la más concentrada
  defp mas_concentrada([], _origen), do: nil
  defp mas_concentrada([zona | _], origen), do: con_distancia(zona, origen)

  defp mas_cercana(_zonas, nil), do: nil
  defp mas_cercana([], _origen), do: nil

  defp mas_cercana(zonas, origen) do
    zonas |> Enum.map(&con_distancia(&1, origen)) |> Enum.min_by(& &1.distancia_m)
  end

  defp con_distancia(zona, origen), do: Map.put(zona, :distancia_m, distancia_a(zona, origen))

  defp distancia_a(_zona, nil), do: nil
  defp distancia_a(zona, origen), do: origen |> Geo.distancia_m(centro(zona)) |> round()

  defp centro(%{sur: sur, norte: norte, oeste: oeste, este: este}), do: {(sur + norte) / 2, (oeste + este) / 2}
end
