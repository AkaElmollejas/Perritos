defmodule Perritos.Router do
  @moduledoc """
  CÁSCARA HTTP. Cada ruta hace siempre lo mismo:
  leer la petición -> traer los datos -> llamar al núcleo -> responder JSON.
  No hay cálculo aquí.
  """
  use Plug.Router

  alias Perritos.{Avistamiento, Busqueda, Colores, Datos, Estadisticas, Zonas}

  plug :match
  plug :dispatch

  get "/f/salud" do
    send_resp(conn, 200, "ok")
  end

  # Para comprobar que el servicio ya lee los avistamientos del backend
  get "/f/avistamientos" do
    con_avistamientos(conn, fn avs ->
      {200, %{total: length(avs), avistamientos: Enum.map(avs, &a_mapa/1)}}
    end)
  end

  # --- Funcionalidad 1: búsqueda combinada ---
  # /f/busqueda?colores=negro,blanco&modo=todos&raza=Beagle&lat=25.4&lon=-100.9&radio=1000&desde=2026-09-01&hasta=2026-10-30&limite=20
  # Todos los parámetros son opcionales. Con lat y lon ordena del más cercano al más lejano.
  get "/f/busqueda" do
    conn = fetch_query_params(conn)
    p = conn.query_params
    limite = p["limite"] |> a_numero(50.0) |> trunc() |> max(1) |> min(200)

    con_avistamientos(conn, fn avs ->
      filtro = Busqueda.filtro(criterios(p))
      {200, %{total: Enum.count(avs, filtro), resultados: Busqueda.buscar(avs, filtro, a_origen(p), limite)}}
    end)
  end

  # --- Funcionalidad 3: estadísticas (acepta los mismos filtros que la búsqueda: colores, raza, desde, hasta...) ---
  get "/f/estadisticas" do
    conn = fetch_query_params(conn)
    n = conn.query_params["n"] |> a_numero(5.0) |> trunc() |> max(1)
    con_avistamientos(conn, fn avs -> {200, avs |> filtrar(conn.query_params) |> Estadisticas.resumen(n)} end)
  end

  # --- Funcionalidad 4: zonas de concentración (mismos filtros; con lat y lon dice qué zona queda cerca) ---
  get "/f/zonas" do
    conn = fetch_query_params(conn)
    tam = conn.query_params["tam"] |> a_numero(500.0) |> trunc() |> max(50) |> min(5_000)
    p = conn.query_params
    con_avistamientos(conn, fn avs -> {200, avs |> filtrar(p) |> Zonas.resumen(tam, a_origen(p))} end)
  end

  match _ do
    json(conn, 404, %{error: "no encontrado"})
  end

  # ---------- Ayudantes de la cáscara ----------

  # Orden superior: recibe qué calcular, trae los datos y responde
  defp con_avistamientos(conn, calcular) do
    case Datos.avistamientos() do
      {:ok, avs} ->
        {estado, cuerpo} = calcular.(avs)
        json(conn, estado, cuerpo)

      {:error, _} ->
        json(conn, 503, %{error: "No se pudieron leer los avistamientos del backend"})
    end
  end

  defp json(conn, estado, cuerpo) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(estado, Jason.encode!(cuerpo))
  end

  # Los structs no se convierten solos a JSON: se pasa a mapa justo antes de responder
  defp a_mapa(%Avistamiento{} = a) do
    a |> Map.from_struct() |> Map.update!(:fecha, &NaiveDateTime.to_iso8601/1)
  end

  # Convierte los parámetros de texto en un mapa de criterios con tipos reales para el núcleo
  defp criterios(p) do
    [
      colores: a_colores(p["colores"]),
      modo: if(p["modo"] == "todos", do: :todos, else: :alguno),
      raza: vacio_a_nil(p["raza"]),
      origen: a_origen(p),
      radio_m: a_radio(p["radio"]),
      desde: a_fecha(p["desde"], ~T[00:00:00]),
      hasta: a_fecha(p["hasta"], ~T[23:59:59])
    ]
    |> Enum.reject(fn {_clave, valor} -> valor in [nil, []] end)
    |> Map.new()
  end

  defp filtrar(avs, p), do: Enum.filter(avs, Busqueda.filtro(criterios(p)))

  defp a_origen(%{"lat" => lat, "lon" => lon}), do: origen(a_numero(lat, nil), a_numero(lon, nil))
  defp a_origen(_), do: nil

  defp origen(lat, lon) when is_number(lat) and is_number(lon), do: {lat, lon}
  defp origen(_, _), do: nil

  defp a_radio(texto) do
    case a_numero(texto, nil) do
      radio when is_number(radio) and radio > 0 -> radio
      _ -> nil
    end
  end

  defp a_fecha(nil, _hora), do: nil

  defp a_fecha(texto, hora) do
    with {:ok, fecha} <- Date.from_iso8601(texto),
         {:ok, fecha_hora} <- NaiveDateTime.new(fecha, hora) do
      fecha_hora
    else
      _ -> nil
    end
  end

  defp a_colores(nil), do: []

  defp a_colores(texto) do
    texto |> String.split(",", trim: true) |> Enum.map(&String.trim/1) |> Colores.de_textos()
  end

  defp vacio_a_nil(nil), do: nil
  defp vacio_a_nil(""), do: nil
  defp vacio_a_nil(texto), do: texto

  defp a_numero(nil, defecto), do: defecto

  defp a_numero(texto, defecto) do
    case Float.parse(texto) do
      {numero, ""} -> numero
      _ -> defecto
    end
  end
end
