defmodule Perritos.Colores do
  @moduledoc """
  Catálogo cerrado de colores. Convierte el texto que manda el backend
  ("cafe", "negro"...) en átomos **sin crear átomos nuevos** (un texto
  desconocido nunca llena la memoria de átomos).
  """

  @catalogo ~w(negro blanco cafe marron gris dorado crema beige canela atigrado manchado rojizo)a
  @por_texto Map.new(@catalogo, fn color -> {Atom.to_string(color), color} end)

  @doc "Lista de colores válidos."
  def catalogo, do: @catalogo

  @doc """
  Texto a átomo; lo que no está en el catálogo se vuelve `:otro`.

      iex> Perritos.Colores.de_texto("cafe")
      :cafe
      iex> Perritos.Colores.de_texto("violeta")
      :otro
  """
  def de_texto(texto), do: Map.get(@por_texto, texto, :otro)

  @doc "Igual que `de_texto/1` para una lista."
  def de_textos(textos), do: Enum.map(textos, &de_texto/1)

  @doc """
  Nombre para mostrar.

      iex> Perritos.Colores.nombre(:cafe)
      "café"
      iex> Perritos.Colores.nombre(:negro)
      "negro"
  """
  def nombre(:cafe), do: "café"
  def nombre(:marron), do: "marrón"
  def nombre(color), do: Atom.to_string(color)
end
