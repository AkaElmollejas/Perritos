defmodule Perritos.Estadisticas do
  @moduledoc """
  Núcleo de *estadísticas*: conteos por color, raza y día, los `n` más
  comunes y la serie diaria para la gráfica.

  Los conteos aceptan **cualquier enumerable** (lista o `Stream`), y usan
  `Stream` en el camino para no crear listas intermedias.
  """

  # ---------- Conteo genérico ----------

  @doc """
  Cuenta cuántas veces aparece cada clave. Sin contadores mutables: un `reduce`.

      iex> Perritos.Estadisticas.contar([:a, :b, :a])
      %{a: 2, b: 1}
      iex> Perritos.Estadisticas.contar([])
      %{}
  """
  def contar(claves) do
    Enum.reduce(claves, %{}, fn clave, acc -> Map.update(acc, clave, 1, &(&1 + 1)) end)
  end

  @doc """
  **Regresa una función**: dado cómo sacar la clave de un avistamiento,
  devuelve una función que cuenta una colección de avistamientos.

      iex> por_inicial = Perritos.Estadisticas.contador_por(&String.first(&1.nombre))
      iex> por_inicial.([%{nombre: "Max"}, %{nombre: "Milo"}, %{nombre: "Luna"}])
      %{"L" => 1, "M" => 2}
  """
  def contador_por(clave_de) do
    fn avistamientos -> avistamientos |> Stream.map(clave_de) |> contar() end
  end

  # ---------- Conteos concretos ----------

  @doc "Cuántos avistamientos tiene cada color (cada perro cuenta en todos sus colores)."
  def por_color(avistamientos) do
    avistamientos |> Stream.flat_map(& &1.colores) |> contar()
  end

  @doc "Cuántos avistamientos hay por raza; `nil` se agrupa como \"desconocida\"."
  def por_raza(avistamientos), do: contador_por(&etiqueta_raza/1).(avistamientos)

  @doc "Cuántos avistamientos hay por día (`\"2026-10-19\"`)."
  def por_dia(avistamientos), do: contador_por(&dia/1).(avistamientos)

  defp etiqueta_raza(%{raza: nil}), do: "desconocida"
  defp etiqueta_raza(%{raza: raza}), do: raza

  defp dia(%{fecha: fecha}), do: fecha |> NaiveDateTime.to_date() |> Date.to_iso8601()

  # ---------- Los n más comunes ----------

  @doc """
  Los `n` más comunes. Los empates se resuelven por orden alfabético
  para que el resultado siempre sea el mismo.

      iex> Perritos.Estadisticas.top(%{negro: 5, blanco: 5, gris: 1}, 2)
      [%{clave: :blanco, total: 5}, %{clave: :negro, total: 5}]
      iex> Perritos.Estadisticas.top(%{}, 3)
      []
  """
  def top(conteos, n) do
    conteos
    |> Enum.sort_by(fn {clave, total} -> {-total, to_string(clave)} end)
    |> Enum.take(n)
    |> Enum.map(fn {clave, total} -> %{clave: clave, total: total} end)
  end

  # ---------- Serie diaria (recursión explícita) ----------

  @doc """
  Una entrada por cada día de `desde` a `hasta`, con 0 donde no hubo
  avistamientos. Recursión explícita sobre fechas (para que la gráfica no
  tenga huecos).

      iex> conteos = %{"2026-10-01" => 2, "2026-10-03" => 1}
      iex> Perritos.Estadisticas.serie_diaria(conteos, ~D[2026-10-01], ~D[2026-10-03])
      [%{dia: "2026-10-01", total: 2}, %{dia: "2026-10-02", total: 0}, %{dia: "2026-10-03", total: 1}]
  """
  def serie_diaria(conteos, desde, hasta), do: serie_diaria(conteos, desde, hasta, Date.compare(desde, hasta))

  defp serie_diaria(_conteos, _desde, _hasta, :gt), do: []

  defp serie_diaria(conteos, desde, hasta, _) do
    clave = Date.to_iso8601(desde)
    [%{dia: clave, total: Map.get(conteos, clave, 0)} | serie_diaria(conteos, Date.add(desde, 1), hasta)]
  end

  @doc "Serie diaria desde el primer hasta el último avistamiento."
  def serie_diaria([]), do: []

  def serie_diaria(avistamientos) do
    dias = Enum.map(avistamientos, &(&1.fecha |> NaiveDateTime.to_date()))
    serie_diaria(por_dia(avistamientos), Enum.min(dias, Date), Enum.max(dias, Date))
  end

  # ---------- Resumen para el frontend ----------

  @doc "Todo junto, listo para convertir a JSON."
  def resumen(avistamientos, n \\ 5) do
    %{
      total: Enum.count(avistamientos),
      por_color: avistamientos |> por_color() |> top(n),
      por_raza: avistamientos |> por_raza() |> top(n),
      por_dia: serie_diaria(avistamientos)
    }
  end
end
