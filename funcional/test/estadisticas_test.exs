defmodule Perritos.EstadisticasTest do
  use ExUnit.Case, async: true
  doctest Perritos.Estadisticas

  alias Perritos.{Avistamiento, Estadisticas}

  defp perro(id, colores, raza, fecha) do
    %Avistamiento{id: id, nombre: "P#{id}", colores: colores, raza: raza, fecha: fecha}
  end

  defp muestra do
    [
      perro(1, [:negro, :blanco], nil, ~N[2026-10-01 08:00:00]),
      perro(2, [:negro], "Beagle", ~N[2026-10-01 20:00:00]),
      perro(3, [:gris, :blanco], "Beagle", ~N[2026-10-03 09:00:00])
    ]
  end

  test "por_color cuenta cada color de cada perro" do
    assert Estadisticas.por_color(muestra()) == %{negro: 2, blanco: 2, gris: 1}
  end

  test "por_raza agrupa nil como desconocida" do
    assert Estadisticas.por_raza(muestra()) == %{"desconocida" => 1, "Beagle" => 2}
  end

  test "por_dia cuenta por día de calendario" do
    assert Estadisticas.por_dia(muestra()) == %{"2026-10-01" => 2, "2026-10-03" => 1}
  end

  test "lista vacía: todos los conteos son vacíos" do
    assert Estadisticas.por_color([]) == %{}
    assert Estadisticas.por_raza([]) == %{}
    assert Estadisticas.serie_diaria([]) == []
  end

  test "las mismas funciones funcionan sobre un Stream" do
    flujo = Stream.map(muestra(), & &1)
    assert Estadisticas.por_color(flujo) == Estadisticas.por_color(muestra())
    assert Estadisticas.por_dia(flujo) == Estadisticas.por_dia(muestra())
  end

  test "top desempata alfabéticamente y respeta n" do
    assert Estadisticas.top(%{b: 2, a: 2, c: 1}, 2) == [%{clave: :a, total: 2}, %{clave: :b, total: 2}]
    assert Estadisticas.top(%{a: 1}, 10) == [%{clave: :a, total: 1}]
  end

  test "serie_diaria rellena con ceros los días sin avistamientos" do
    assert Estadisticas.serie_diaria(muestra()) == [
             %{dia: "2026-10-01", total: 2},
             %{dia: "2026-10-02", total: 0},
             %{dia: "2026-10-03", total: 1}
           ]
  end

  test "caso borde: un solo día produce una sola entrada" do
    un_dia = [perro(1, [:negro], nil, ~N[2026-12-31 23:59:59])]
    assert Estadisticas.serie_diaria(un_dia) == [%{dia: "2026-12-31", total: 1}]
  end

  test "serie_diaria cruza el cambio de mes y de año" do
    conteos = %{"2026-12-31" => 1, "2027-01-01" => 2}
    serie = Estadisticas.serie_diaria(conteos, ~D[2026-12-30], ~D[2027-01-01])
    assert Enum.map(serie, & &1.total) == [0, 1, 2]
  end

  test "resumen junta todo" do
    r = Estadisticas.resumen(muestra(), 1)
    assert r.total == 3
    assert r.por_color == [%{clave: :blanco, total: 2}]
    assert length(r.por_dia) == 3
  end
end
