defmodule Perritos.Busqueda do
  @moduledoc """
  Núcleo de la *búsqueda combinada*: encontrar perritos por color, raza,
  cercanía a un punto y rango de fechas, en cualquier combinación.

  La idea: **cada criterio es una función** (`avistamiento -> true/false`) y
  los criterios se **combinan** con `todos/1` (Y) y `alguno/1` (O), que también
  son funciones que regresan funciones. Todo es puro: recibe datos, regresa datos.
  """

  alias Perritos.Geo

  # ---------- Criterios: cada uno REGRESA una función ----------

  @doc """
  Perritos que tienen ese color (principal o adicional).

      iex> perro = %{colores: [:negro, :blanco]}
      iex> Perritos.Busqueda.con_color(:negro).(perro)
      true
      iex> Perritos.Busqueda.con_color(:gris).(perro)
      false
  """
  def con_color(color), do: fn %{colores: colores} -> color in colores end

  @doc """
  Perritos de esa raza. `nil` busca los de raza desconocida.

      iex> Perritos.Busqueda.de_raza("Beagle").(%{raza: "Beagle"})
      true
      iex> Perritos.Busqueda.de_raza(nil).(%{raza: nil})
      true
  """
  def de_raza(raza), do: fn %{raza: r} -> r == raza end

  @doc """
  Perritos a `radio_m` metros o menos de `origen` (`{lat, lon}`).

      iex> cerca = Perritos.Busqueda.cerca_de({25.44, -100.99}, 500)
      iex> cerca.(%{lat: 25.44, lon: -100.99})
      true
      iex> cerca.(%{lat: 25.50, lon: -100.99})
      false
  """
  def cerca_de({_lat, _lon} = origen, radio_m) do
    fn %{lat: lat, lon: lon} -> Geo.distancia_m(origen, {lat, lon}) <= radio_m end
  end

  @doc """
  Perritos vistos entre `desde` y `hasta` (ambos inclusive). `nil` = sin límite.

      iex> en_octubre = Perritos.Busqueda.entre_fechas(~N[2026-10-01 00:00:00], ~N[2026-10-31 23:59:59])
      iex> en_octubre.(%{fecha: ~N[2026-10-15 12:00:00]})
      true
      iex> en_octubre.(%{fecha: ~N[2026-09-30 23:00:00]})
      false
  """
  def entre_fechas(desde, hasta) do
    fn %{fecha: fecha} -> no_antes?(fecha, desde) and no_despues?(fecha, hasta) end
  end

  defp no_antes?(_fecha, nil), do: true
  defp no_antes?(fecha, desde), do: NaiveDateTime.compare(fecha, desde) != :lt

  defp no_despues?(_fecha, nil), do: true
  defp no_despues?(fecha, hasta), do: NaiveDateTime.compare(fecha, hasta) != :gt

  # ---------- Combinadores: reciben funciones y regresan una función (recursión explícita) ----------

  @doc """
  Y: un perrito pasa solo si cumple **todos** los filtros. Sin filtros, pasan todos.

      iex> es_par = fn n -> rem(n, 2) == 0 end
      iex> mayor_5 = fn n -> n > 5 end
      iex> Perritos.Busqueda.todos([es_par, mayor_5]).(8)
      true
      iex> Perritos.Busqueda.todos([es_par, mayor_5]).(4)
      false
      iex> Perritos.Busqueda.todos([]).(4)
      true
  """
  def todos([]), do: fn _ -> true end

  def todos([filtro | resto]) do
    filtro_resto = todos(resto)
    fn elemento -> filtro.(elemento) and filtro_resto.(elemento) end
  end

  @doc """
  O: pasa si cumple **alguno**. Sin filtros, no pasa nadie.

      iex> es_par = fn n -> rem(n, 2) == 0 end
      iex> mayor_5 = fn n -> n > 5 end
      iex> Perritos.Busqueda.alguno([es_par, mayor_5]).(7)
      true
      iex> Perritos.Busqueda.alguno([es_par, mayor_5]).(3)
      false
      iex> Perritos.Busqueda.alguno([]).(3)
      false
  """
  def alguno([]), do: fn _ -> false end

  def alguno([filtro | resto]) do
    filtro_resto = alguno(resto)
    fn elemento -> filtro.(elemento) or filtro_resto.(elemento) end
  end

  # ---------- De un mapa de criterios a UN solo filtro ----------

  @doc """
  Arma el filtro completo desde un mapa de criterios (todos opcionales):

    * `:colores` - lista de átomos; con `modo: :todos` debe tener todos, si no, alguno
    * `:raza` - texto
    * `:origen` + `:radio_m` - cercanía (se necesitan los dos)
    * `:desde` / `:hasta` - `NaiveDateTime`

  Los criterios distintos se combinan con Y. Un mapa vacío deja pasar a todos.

      iex> filtro = Perritos.Busqueda.filtro(%{colores: [:negro, :gris], raza: "Pug"})
      iex> filtro.(%{colores: [:gris], raza: "Pug"})
      true
      iex> filtro.(%{colores: [:gris], raza: "Beagle"})
      false
  """
  def filtro(criterios) do
    [
      filtro_colores(criterios),
      filtro_raza(criterios),
      filtro_cerca(criterios),
      filtro_fechas(criterios)
    ]
    |> Enum.reject(&is_nil/1)
    |> todos()
  end

  defp filtro_colores(%{colores: [_ | _] = colores} = criterios) do
    combinar = if criterios[:modo] == :todos, do: &todos/1, else: &alguno/1
    colores |> Enum.map(&con_color/1) |> combinar.()
  end

  defp filtro_colores(_), do: nil

  defp filtro_raza(%{raza: raza}), do: de_raza(raza)
  defp filtro_raza(_), do: nil

  defp filtro_cerca(%{origen: origen, radio_m: radio_m}), do: cerca_de(origen, radio_m)
  defp filtro_cerca(_), do: nil

  defp filtro_fechas(%{desde: desde, hasta: hasta}), do: entre_fechas(desde, hasta)
  defp filtro_fechas(%{desde: desde}), do: entre_fechas(desde, nil)
  defp filtro_fechas(%{hasta: hasta}), do: entre_fechas(nil, hasta)
  defp filtro_fechas(_), do: nil

  # ---------- Buscar ----------

  @doc """
  Aplica el filtro. Con `origen` agrega `distancia_m` a cada resultado y los
  ordena **del más cercano al más lejano**; sin `origen`, del más reciente al
  más antiguo. `limite` recorta la lista.
  """
  def buscar(avistamientos, filtro, origen \\ nil, limite \\ 50) do
    avistamientos
    |> Enum.filter(filtro)
    |> Enum.map(&a_resultado(&1, origen))
    |> ordenar(origen)
    |> Enum.take(limite)
  end

  defp a_resultado(a, origen) do
    %{
      id: a.id,
      nombre: a.nombre,
      raza: a.raza,
      colores: a.colores,
      lat: a.lat,
      lon: a.lon,
      foto: a.foto,
      fecha: a.fecha,
      distancia_m: distancia(a, origen)
    }
  end

  defp distancia(_a, nil), do: nil
  defp distancia(a, origen), do: origen |> Geo.distancia_m({a.lat, a.lon}) |> round()

  defp ordenar(resultados, nil), do: Enum.sort_by(resultados, & &1.fecha, {:desc, NaiveDateTime})
  defp ordenar(resultados, _origen), do: Enum.sort_by(resultados, & &1.distancia_m)
end
