defmodule Perritos.BusquedaTest do
  use ExUnit.Case, async: true
  doctest Perritos.Busqueda

  alias Perritos.{Avistamiento, Busqueda}

  defp perro(id, nombre, colores, raza, lat, lon, fecha) do
    %Avistamiento{id: id, nombre: nombre, colores: colores, raza: raza, lat: lat, lon: lon, fecha: fecha}
  end

  # 0.001° de latitud ≈ 111 m
  defp muestra do
    [
      perro(1, "Max", [:dorado, :blanco], "Labrador", 25.4400, -100.99, ~N[2026-10-20 08:00:00]),
      perro(2, "Luna", [:negro], nil, 25.4410, -100.99, ~N[2026-10-10 08:00:00]),
      perro(3, "Rocky", [:negro, :blanco], "Pastor", 25.4500, -100.99, ~N[2026-09-01 08:00:00]),
      perro(4, "Lola", [:gris], nil, 25.4600, -100.99, ~N[2026-10-25 08:00:00])
    ]
  end

  defp ids(resultados), do: Enum.map(resultados, & &1.id)

  test "con_color encuentra por color principal o adicional" do
    assert muestra() |> Busqueda.buscar(Busqueda.con_color(:blanco)) |> ids() |> Enum.sort() == [1, 3]
  end

  test "de_raza(nil) encuentra los de raza desconocida" do
    assert muestra() |> Busqueda.buscar(Busqueda.de_raza(nil)) |> ids() |> Enum.sort() == [2, 4]
  end

  test "cerca_de respeta el radio" do
    origen = {25.4400, -100.99}
    assert muestra() |> Busqueda.buscar(Busqueda.cerca_de(origen, 150), origen) |> ids() == [1, 2]
    assert muestra() |> Busqueda.buscar(Busqueda.cerca_de(origen, 50), origen) |> ids() == [1]
  end

  test "entre_fechas incluye los extremos y acepta límites nil" do
    exacta = ~N[2026-10-10 08:00:00]
    assert muestra() |> Busqueda.buscar(Busqueda.entre_fechas(exacta, exacta)) |> ids() == [2]
    assert muestra() |> Busqueda.buscar(Busqueda.entre_fechas(nil, nil)) |> length() == 4
    assert muestra() |> Busqueda.buscar(Busqueda.entre_fechas(~N[2026-10-11 00:00:00], nil)) |> ids() |> Enum.sort() == [1, 4]
  end

  test "caso borde: todos([]) deja pasar a todos y alguno([]) a nadie" do
    assert muestra() |> Busqueda.buscar(Busqueda.todos([])) |> length() == 4
    assert muestra() |> Busqueda.buscar(Busqueda.alguno([])) == []
  end

  test "los combinadores se pueden anidar: (negro O dorado) Y raza desconocida" do
    filtro =
      Busqueda.todos([
        Busqueda.alguno([Busqueda.con_color(:negro), Busqueda.con_color(:dorado)]),
        Busqueda.de_raza(nil)
      ])

    assert muestra() |> Busqueda.buscar(filtro) |> ids() == [2]
  end

  test "filtro/1 con un mapa vacío deja pasar a todos" do
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(%{})) |> length() == 4
  end

  test "filtro/1: varios colores en modo alguno (por defecto) y modo todos" do
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(%{colores: [:negro, :blanco]})) |> length() == 3
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(%{colores: [:negro, :blanco], modo: :todos})) |> ids() == [3]
  end

  test "filtro/1 ignora un radio si no hay origen (y al revés)" do
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(%{radio_m: 10})) |> length() == 4
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(%{origen: {25.44, -100.99}})) |> length() == 4
  end

  test "filtro/1 combina criterios distintos con Y" do
    criterios = %{colores: [:negro], desde: ~N[2026-10-01 00:00:00], origen: {25.44, -100.99}, radio_m: 500}
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(criterios)) |> ids() == [2]
  end

  test "con origen ordena del más cercano al más lejano y agrega la distancia" do
    resultados = Busqueda.buscar(muestra(), Busqueda.filtro(%{}), {25.4590, -100.99})
    assert ids(resultados) == [4, 3, 2, 1]
    assert hd(resultados).distancia_m < 150
    assert resultados |> Enum.map(& &1.distancia_m) == Enum.sort(Enum.map(resultados, & &1.distancia_m))
  end

  test "sin origen ordena del más reciente al más antiguo y no hay distancia" do
    resultados = Busqueda.buscar(muestra(), Busqueda.filtro(%{}))
    assert ids(resultados) == [4, 1, 2, 3]
    assert Enum.all?(resultados, &(&1.distancia_m == nil))
  end

  test "caso borde: lista vacía y límite" do
    assert Busqueda.buscar([], Busqueda.filtro(%{colores: [:negro]})) == []
    assert muestra() |> Busqueda.buscar(Busqueda.filtro(%{}), nil, 2) |> length() == 2
  end
end
