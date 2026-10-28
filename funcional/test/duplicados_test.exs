defmodule Perritos.DuplicadosTest do
  use ExUnit.Case, async: true
  doctest Perritos.Duplicados

  alias Perritos.{Avistamiento, Duplicados}

  defp perro(id, nombre, colores, raza, lat, lon) do
    %Avistamiento{id: id, nombre: nombre, colores: colores, raza: raza, lat: lat, lon: lon}
  end

  # Ejemplo del enunciado: Firulais y Chato, a ~94 m
  defp firulais, do: perro(1, "Firulais", [:negro, :blanco], nil, 25.4400, -100.9900)
  defp chato, do: perro(2, "Chato", [:blanco, :negro], nil, 25.440845, -100.9900)

  test "ejemplo del enunciado: similitud ≈ 0.825, es posible duplicado" do
    assert_in_delta Duplicados.similitud(firulais(), chato()), 0.825, 0.002
  end

  test "un perro idéntico en el mismo lugar da similitud 0.9 con razas desconocidas" do
    # colores 1.0*0.4 + raza 0.5*0.2 + cercanía 1.0*0.4
    assert_in_delta Duplicados.similitud(firulais(), %{chato() | lat: 25.44, lon: -100.99}), 0.9, 1.0e-9
  end

  test "colores distintos y lejos: solo aporta la raza desconocida (0.5 * 0.2)" do
    lejano = perro(3, "Rex", [:gris], "Pug", 25.50, -101.05)
    assert_in_delta Duplicados.similitud(firulais(), lejano), 0.1, 1.0e-9
  end

  test "caso borde: a más de 500 m la cercanía es 0, no negativa" do
    assert Duplicados.cercania(5_000) == 0.0
  end

  test "caso borde: razas distintas conocidas valen 0.0 y desconocida vale 0.5" do
    assert Duplicados.similitud_raza("Beagle", "Pug") == 0.0
    assert Duplicados.similitud_raza(nil, nil) == 0.5
  end

  test "parecidos ordena del más al menos parecido y no incluye a la referencia" do
    lejos = perro(3, "Lejano", [:negro, :blanco], nil, 25.4440, -100.9900)
    resultado = Duplicados.parecidos(firulais(), [firulais(), lejos, chato()], 0.0)
    assert Enum.map(resultado, & &1.id) == [2, 3]
  end

  test "parecidos con lista vacía regresa lista vacía" do
    assert Duplicados.parecidos(firulais(), []) == []
  end

  test "parecidos respeta el umbral y el límite" do
    iguales = for i <- 10..20, do: perro(i, "Copia#{i}", [:negro, :blanco], nil, 25.44, -100.99)
    assert Duplicados.parecidos(firulais(), iguales, 0.8, 3) |> length() == 3
    assert Duplicados.parecidos(firulais(), iguales, 0.99) == []
  end

  test "parejas genera n(n-1)/2 combinaciones" do
    assert length(Duplicados.parejas(Enum.to_list(1..10))) == 45
  end

  test "entre_si acepta una función de medida propia" do
    siempre_uno = fn _a, _b -> 1.0 end
    [primera] = Duplicados.entre_si([firulais(), chato()], 0.9, siempre_uno)
    assert %{a: 1, b: 2, similitud: 1.0} = primera
  end

  test "entre_si con un solo perro no tiene parejas" do
    assert Duplicados.entre_si([firulais()]) == []
  end
end
