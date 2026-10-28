defmodule Perritos.Duplicados do
  @moduledoc """
  Núcleo de *posibles duplicados*: ¿este perro ya lo reportó alguien más?

      similitud = 0.4 · colores + 0.2 · raza + 0.4 · cercanía

  Todo son funciones puras: reciben structs y regresan números, mapas o listas.
  """

  alias Perritos.{Avistamiento, Geo}

  @peso_colores 0.4
  @peso_raza 0.2
  @peso_cercania 0.4
  @radio_cercania_m 500

  # ---------- Piezas de la fórmula (pattern matching, una cláusula por caso) ----------

  @doc """
  Índice de Jaccard: |A ∩ B| / |A ∪ B|.

      iex> Perritos.Duplicados.similitud_colores([:negro, :blanco], [:blanco, :negro])
      1.0
      iex> Perritos.Duplicados.similitud_colores([:negro], [:negro, :blanco])
      0.5
      iex> Perritos.Duplicados.similitud_colores([], [])
      0.0
  """
  def similitud_colores([], []), do: 0.0

  def similitud_colores(a, b) do
    {a, b} = {MapSet.new(a), MapSet.new(b)}
    MapSet.size(MapSet.intersection(a, b)) / MapSet.size(MapSet.union(a, b))
  end

  @doc """
  1.0 si coinciden, 0.5 si alguna es desconocida (`nil`), 0.0 si son distintas.

      iex> Perritos.Duplicados.similitud_raza("Beagle", "Beagle")
      1.0
      iex> Perritos.Duplicados.similitud_raza(nil, "Beagle")
      0.5
      iex> Perritos.Duplicados.similitud_raza("Beagle", "Pug")
      0.0
  """
  def similitud_raza(nil, _), do: 0.5
  def similitud_raza(_, nil), do: 0.5
  def similitud_raza(raza, raza), do: 1.0
  def similitud_raza(_, _), do: 0.0

  @doc """
  `max(0, 1 - d / 500)` con `d` en metros.

      iex> Perritos.Duplicados.cercania(0)
      1.0
      iex> Perritos.Duplicados.cercania(250)
      0.5
      iex> Perritos.Duplicados.cercania(900)
      0.0
  """
  def cercania(distancia_m), do: max(0.0, 1 - distancia_m / @radio_cercania_m)

  @doc "Similitud total entre dos avistamientos, de 0.0 a 1.0."
  def similitud(%Avistamiento{} = a, %Avistamiento{} = b) do
    distancia = Geo.distancia_m({a.lat, a.lon}, {b.lat, b.lon})

    @peso_colores * similitud_colores(a.colores, b.colores) +
      @peso_raza * similitud_raza(a.raza, b.raza) +
      @peso_cercania * cercania(distancia)
  end

  # ---------- Orden superior ----------

  @doc """
  **Regresa una función**: un predicado que acepta las parejas puntuadas
  con similitud mayor o igual al umbral.

      iex> acepta = Perritos.Duplicados.filtro_umbral(0.8)
      iex> acepta.(%{similitud: 0.9})
      true
      iex> acepta.(%{similitud: 0.5})
      false
  """
  def filtro_umbral(umbral), do: fn %{similitud: s} -> s >= umbral end

  @doc """
  Avistamientos de `existentes` parecidos a `referencia`, del más al menos
  parecido. `referencia` puede ser un perro que aún no se guarda (`id: nil`).
  """
  def parecidos(%Avistamiento{} = referencia, existentes, umbral \\ 0.8, limite \\ 5) do
    existentes
    |> Enum.reject(&(&1.id == referencia.id))
    |> Enum.map(fn candidato ->
      %{
        id: candidato.id,
        nombre: candidato.nombre,
        similitud: Float.round(similitud(referencia, candidato), 3)
      }
    end)
    |> Enum.filter(filtro_umbral(umbral))
    |> Enum.sort_by(& &1.similitud, :desc)
    |> Enum.take(limite)
  end

  # ---------- Recursión explícita ----------

  @doc """
  Todas las parejas posibles de una lista, sin repetir ni emparejar un
  elemento consigo mismo. Recursión explícita.

      iex> Perritos.Duplicados.parejas([1, 2, 3])
      [{1, 2}, {1, 3}, {2, 3}]
      iex> Perritos.Duplicados.parejas([])
      []
  """
  def parejas([]), do: []
  def parejas([cabeza | resto]), do: Enum.map(resto, &{cabeza, &1}) ++ parejas(resto)

  @doc """
  Busca duplicados **entre todos** los avistamientos. **Recibe una función**
  (`medida`, de dos avistamientos a número), por defecto `similitud/2`.
  """
  def entre_si(avistamientos, umbral \\ 0.85, medida \\ &similitud/2) do
    avistamientos
    |> parejas()
    |> Enum.map(fn {a, b} ->
      %{
        a: a.id,
        nombre_a: a.nombre,
        b: b.id,
        nombre_b: b.nombre,
        similitud: Float.round(medida.(a, b), 3)
      }
    end)
    |> Enum.filter(filtro_umbral(umbral))
    |> Enum.sort_by(& &1.similitud, :desc)
  end
end
