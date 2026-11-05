defmodule Perritos.GeoTest do
  use ExUnit.Case, async: true
  doctest Perritos.Geo
  doctest Perritos.Colores

  alias Perritos.Geo

  test "un grado de latitud mide ≈ 111.19 km" do
    assert_in_delta Geo.distancia_m({25.0, -100.0}, {26.0, -100.0}), 111_194.9, 1.0
  end

  test "la distancia es simétrica" do
    a = {25.44, -100.99}
    b = {25.50, -101.05}
    assert Geo.distancia_m(a, b) == Geo.distancia_m(b, a)
  end

  test "caso borde: puntos antípodas no truenan por redondeo" do
    assert_in_delta Geo.distancia_m({0.0, 0.0}, {0.0, 180.0}), 20_015_086.8, 10.0
  end
end
