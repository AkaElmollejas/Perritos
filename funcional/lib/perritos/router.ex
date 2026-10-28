defmodule Perritos.Router do
  @moduledoc """
  CÁSCARA HTTP. Cada ruta hace siempre lo mismo:
  leer la petición -> traer los datos -> llamar al núcleo -> responder JSON.
  No hay cálculo aquí.
  """
  use Plug.Router

  alias Perritos.{Avistamiento, Colores, Datos, Duplicados, Estadisticas, Zonas}

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

  # --- Funcionalidad 2: posibles duplicados ---
  # /f/duplicados?id=7            -> parecidos a un avistamiento existente
  # /f/duplicados?lat=..&lon=..&colores=negro,blanco&raza=Beagle -> perro aún no registrado
  get "/f/duplicados" do
    conn = fetch_query_params(conn)
    p = conn.query_params

    con_avistamientos(conn, fn avs ->
      case referencia(p, avs) do
        {:ok, ref} ->
          {200, %{parecidos: Duplicados.parecidos(ref, avs, a_numero(p["umbral"], 0.8))}}

        {:error, mensaje} ->
          {400, %{error: mensaje}}
      end
    end)
  end

  get "/f/duplicados/pares" do
    conn = fetch_query_params(conn)
    umbral = a_numero(conn.query_params["umbral"], 0.85)
    con_avistamientos(conn, fn avs -> {200, %{pares: Duplicados.entre_si(avs, umbral)}} end)
  end

  # --- Funcionalidad 3: estadísticas ---
  get "/f/estadisticas" do
    conn = fetch_query_params(conn)
    n = conn.query_params["n"] |> a_numero(5.0) |> trunc() |> max(1)
    con_avistamientos(conn, fn avs -> {200, Estadisticas.resumen(avs, n)} end)
  end

  # --- Funcionalidad 4: zonas de concentración ---
  get "/f/zonas" do
    conn = fetch_query_params(conn)
    tam = conn.query_params["tam"] |> a_numero(500.0) |> trunc() |> max(50) |> min(5_000)
    con_avistamientos(conn, fn avs -> {200, Zonas.resumen(avs, tam)} end)
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

  defp referencia(%{"id" => id}, avs) do
    with {n, ""} <- Integer.parse(id),
         %Avistamiento{} = a <- Enum.find(avs, &(&1.id == n)) do
      {:ok, a}
    else
      _ -> {:error, "No existe un avistamiento con ese id"}
    end
  end

  defp referencia(%{"lat" => lat, "lon" => lon} = p, _avs) do
    {:ok,
     %Avistamiento{
       lat: a_numero(lat, 0.0),
       lon: a_numero(lon, 0.0),
       colores: p |> Map.get("colores", "") |> a_colores(),
       raza: vacio_a_nil(p["raza"])
     }}
  end

  defp referencia(_p, _avs), do: {:error, "Indique id, o lat y lon (con colores y raza)"}

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
