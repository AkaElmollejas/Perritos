defmodule Perritos.Avistamiento do
  @moduledoc """
  Un avistamiento de perrito. Solo datos, sin lógica.

    * `colores` - lista de átomos; el primero es el color principal.
    * `raza` - texto, o `nil` si es desconocida (incluye "criollo").
    * `fecha` - `NaiveDateTime`.
  """
  defstruct [:id, :nombre, :raza, :colores, :lat, :lon, :foto, :fecha]
end
