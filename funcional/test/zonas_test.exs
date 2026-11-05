defmodule Perritos.ZonasTest do
  use ExUnit.Case, async: true
  doctest Perritos.Zonas

  alias Perritos.{Geo, Zonas}

  # Centro de una celda de 500 m: sirve para armar puntos que seguro caen dentro
  defp centro(celda) do
    l = Zonas.limites(celda, 500)
    {(l.sur + l.norte) / 2, (l.oeste + l.este) / 2}
  end

  test "dos puntos muy cercanos caen en la misma celda de 500 m" do
    {lat, lon} = centro({5663, -20305})
    assert Zonas.celda({lat, lon}, 500) == {5663, -20305}
    assert Zonas.celda({lat + 0.0005, lon - 0.0005}, 500) == {5663, -20305}
  end

  test "dos puntos a ~2 km caen en celdas distintas" do
    refute Zonas.celda({25.44, -100.99}, 500) == Zonas.celda({25.46, -100.99}, 500)
  end

  test "longitudes negativas se redondean hacia abajo (no hacia cero)" do
    {_fila, columna} = Zonas.celda({25.44, -0.0001}, 500)
    assert columna == -1
  end

  test "caso borde: un punto en el borde sur de una celda pertenece a esa celda" do
    %{sur: sur, oeste: oeste} = Zonas.limites({228_000, -950_000}, 500)
    assert Zonas.celda({sur + 1.0e-9, oeste + 1.0e-9}, 500) == {228_000, -950_000}
  end

  test "caso borde: lista vacía no produce zonas" do
    assert Zonas.zonas([], 500) == []
    assert Zonas.resumen([], 500) ==
             %{tam_m: 500, total: 0, zonas: [], mas_concentrada: nil, mas_cercana: nil}
  end

  test "los límites de una celda miden aproximadamente el tamaño pedido" do
    l = Zonas.limites(Zonas.celda({25.44, -100.99}, 500), 500)
    alto = Geo.distancia_m({l.sur, l.oeste}, {l.norte, l.oeste})
    ancho = Geo.distancia_m({l.sur, l.oeste}, {l.sur, l.este})
    assert_in_delta alto, 500, 5
    assert_in_delta ancho, 500, 5
  end

  test "zonas agrupa, cuenta y ordena de la más a la menos concentrada" do
    {lat, lon} = centro({5663, -20305})

    perros = [
      %{lat: lat, lon: lon},
      %{lat: lat + 0.0005, lon: lon},
      %{lat: lat, lon: lon + 0.0005},
      %{lat: 25.5000, lon: -101.0500}
    ]

    assert [%{total: 3}, %{total: 1}] = Zonas.zonas(perros, 500)
    assert Zonas.resumen(perros, 500).total == 4
  end

  test "un tamaño mayor junta más perros en menos celdas" do
    perros = for i <- 0..9, do: %{lat: 25.44 + i * 0.001, lon: -100.99}
    assert length(Zonas.zonas(perros, 5_000)) < length(Zonas.zonas(perros, 100))
  end

  test "contar_celdas acepta cualquier función clasificadora" do
    assert Zonas.contar_celdas([%{x: 1}, %{x: 5}, %{x: 7}], &rem(&1.x, 2)) == %{1 => 3}
  end

  describe "resumen con la ubicación del usuario" do
    setup do
      {lat, lon} = centro({5663, -20305})
      # 3 perros en la celda de arriba; 1 perro a unos 2.5 km, en otra celda
      lejano = %{lat: lat + 0.0225, lon: lon}
      cercanos = for d <- [0.0, 0.0003, 0.0006], do: %{lat: lat + d, lon: lon}
      {:ok, origen: {lat, lon}, perros: [lejano | cercanos]}
    end

    test "sin origen no calcula distancias", %{perros: perros} do
      r = Zonas.resumen(perros, 500)
      assert r.mas_cercana == nil
      assert r.mas_concentrada.distancia_m == nil
    end

    test "con origen, la zona más concentrada y la más cercana", %{perros: perros, origen: origen} do
      r = Zonas.resumen(perros, 500, origen)
      assert r.mas_concentrada.total == 3
      assert r.mas_concentrada.distancia_m < 300
      assert r.mas_cercana.distancia_m <= r.mas_concentrada.distancia_m
    end

    test "la zona más cercana puede ser distinta de la más concentrada", %{perros: perros} do
      # estoy parado en la celda del perro solitario
      solitario = hd(perros)
      r = Zonas.resumen(perros, 500, {solitario.lat, solitario.lon})
      assert r.mas_concentrada.total == 3
      assert r.mas_cercana.total == 1
      assert r.mas_cercana.distancia_m < r.mas_concentrada.distancia_m
    end
  end
end
