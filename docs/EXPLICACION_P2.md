# Explicación del Proyecto 2: Elixir, Docker y el túnel de Cloudflare

## 1. Qué hay en el sistema

```
celular ──https──▶ Cloudflare ──▶ contenedor "tunel" ──▶ contenedor "proxy" (nginx)
                                                          ├─ /      ▶ frontend  (HTML/JS)
                                                          ├─ /api/  ▶ backend   (Python + SQLite)   ← P1
                                                          └─ /f/    ▶ funcional (Elixir)            ← P2
                                                                         │ pide GET /api/avistamientos
                                                                         ▼
                                                                      backend
```

* **Backend (P1):** guarda y entrega los perritos. Es el único que toca la base de datos.
* **Servicio Elixir (P2):** no guarda nada. Pide los avistamientos al backend, hace **cálculos** y responde JSON.
* **Frontend:** muestra los resultados (búsqueda "cerca de mí", gráficas, mapa de zonas).
* **Proxy:** la única puerta de entrada; decide a qué servicio va cada ruta.
* **Túnel:** abre una URL pública `https://….trycloudflare.com` que llega al proxy.

Son **5 contenedores**: `frontend`, `backend`, `funcional`, `proxy`, `tunel`. (`herramientas` solo sirve para correr `mix test` y no arranca con `up`.)

---

## 2. ¿Por qué Elixir tiene que correr en Docker?

Dicho con honestidad: **Elixir no necesita Docker para funcionar**; con Elixir instalado bastaría `mix run`. Se usa Docker porque:

1. **El enunciado lo pide.** El Proyecto 2 exige un `Dockerfile` en dos etapas para el servicio Elixir, un `docker-compose.yml` que levante todo, y que desde un clon limpio, *"con sólo Docker instalado"*, baste `docker compose up --build`. (El P1 prohibía Docker; el P2 lo exige.)
2. **Nadie tiene que instalar Elixir.** Elixir necesita Erlang/OTP, Elixir, Hex y Rebar, con versiones que deben ser compatibles entre sí; instalarlos en Windows/Mac es la parte más frágil. Dentro de la imagen `elixir:1.18-alpine` ya viene todo y con las versiones correctas. El profesor, o cualquier persona, solo necesita Docker.
3. **Mismo resultado en cualquier computadora.** "En mi máquina sí funciona" desaparece: todos corren exactamente la misma imagen.
4. **Un paquete listo para ejecutar (`mix release`).** La primera etapa del Dockerfile compila el proyecto y genera un *release*: el programa ya compilado junto con la máquina virtual de Erlang. La segunda etapa solo copia ese release; el código fuente y las herramientas de compilación no quedan en la imagen final.
5. **Aislamiento.** El contenedor de Elixir **no publica ningún puerto** al exterior: solo el proxy puede hablarle, por la red interna de Docker. Así, lo único expuesto es la puerta de entrada.
6. **Todo junto y en orden.** Compose arranca los 5 servicios, los conecta por nombre (`backend`, `funcional`…) y los reinicia juntos.

---

## 3. El código de Elixir, explicado

### 3.1 La idea central: núcleo puro + cáscara

| | Qué es | Archivos | Regla |
| :--- | :--- | :--- | :--- |
| **Núcleo** | Funciones **puras**: reciben datos y devuelven datos | `avistamiento, colores, geo, busqueda, estadisticas, zonas` | No leen base de datos, red, reloj ni imprimen |
| **Cáscara** | Todo lo que toca el mundo exterior | `datos.ex` (HTTP al backend), `router.ex` (rutas), `application.ex` (arranque) | Traduce petición → llama al núcleo → responde |

Una función **pura** siempre da el mismo resultado con los mismos datos. Por eso el núcleo se prueba con `mix test` sin levantar nada.

### 3.2 Conceptos de Elixir que se usan (con ejemplos del proyecto)

**Pattern matching con varias cláusulas** (en vez de `if` anidados), `busqueda.ex`:
```elixir
defp no_antes?(_fecha, nil), do: true                      # sin fecha "desde": siempre cumple
defp no_antes?(fecha, desde),                               # con fecha "desde": compara
  do: NaiveDateTime.compare(fecha, desde) != :lt
```
Elixir prueba las cláusulas **de arriba hacia abajo** y usa la primera que encaja.

**Función que regresa una función**: cada criterio de búsqueda *devuelve* el filtro ya listo.
```elixir
def con_color(color), do: fn %{colores: colores} -> color in colores end

es_negro = Perritos.Busqueda.con_color(:negro)
es_negro.(%{colores: [:negro, :blanco]})   # => true
```

**Funciones que reciben funciones y recursión explícita**: `todos/1` (Y) y `alguno/1` (O) reciben una lista de filtros y devuelven **un** filtro. La lista se procesa sola: caso base + caso recursivo.
```elixir
def todos([]), do: fn _ -> true end                    # caso base: sin filtros, pasa todo
def todos([filtro | resto]) do                          # [primero | los_demás]
  filtro_resto = todos(resto)                           # recursión: el filtro de "los demás"
  fn elemento -> filtro.(elemento) and filtro_resto.(elemento) end
end
```
Así se arma cualquier combinación, por ejemplo "(negro **o** dorado) **y** raza desconocida":
```elixir
todos([alguno([con_color(:negro), con_color(:dorado)]), de_raza(nil)])
```

**Pipeline `|>`** (el resultado de una línea es el primer argumento de la siguiente), `buscar/4`:
```elixir
avistamientos
|> Enum.filter(filtro)                 # los que cumplen
|> Enum.map(&a_resultado(&1, origen))  # agrega la distancia a ti
|> ordenar(origen)                     # más cercano primero
|> Enum.take(limite)                   # los primeros n
```

**Sin estado mutable:** nunca se "suma a una variable". Se usa `Enum.reduce`:
```elixir
Enum.reduce(claves, %{}, fn clave, acc -> Map.update(acc, clave, 1, &(&1 + 1)) end)
```
Empieza con un mapa vacío `%{}` y en cada vuelta devuelve un mapa **nuevo** con el conteo aumentado.

**Stream** (procesar sin crear listas intermedias; es "perezoso"): `Stream.flat_map(& &1.colores) |> contar()`. Las funciones de estadísticas aceptan una lista **o** un Stream.

### 3.3 Módulo por módulo

* **`Avistamiento`**: un `struct` (como un registro): `id, nombre, raza, colores, lat, lon, foto, fecha`. Solo datos.
* **`Colores`**: catálogo cerrado (`negro, blanco, cafe…`). Convierte texto → átomo con un mapa, sin crear átomos nuevos (evita llenar la memoria con basura que mande un usuario).
* **`Geo`**: `distancia_m/2` con la fórmula de **haversine** (distancia sobre una esfera, en metros).
* **`Busqueda`** *(buscar cerca de mí)*: criterios `con_color/1`, `de_raza/1`, `cerca_de/2`, `entre_fechas/2`; combinadores `todos/1` y `alguno/1`; `filtro/1` arma un solo filtro desde un mapa de criterios (los que no vengan se ignoran); `buscar/4` filtra, calcula la distancia a ti y ordena del más cercano al más lejano.
* **`Estadisticas`**: `contar/1` (reduce), `por_color/por_raza/por_dia`, `top/2` (los n más comunes; empata alfabéticamente para ser predecible), `serie_diaria/3` (recursión: una entrada por día, con 0 donde no hubo avistamientos, para que la gráfica no tenga huecos).
* **`Zonas`**: `celda/2` convierte una coordenada en `{fila, columna}` de una cuadrícula global (dividiendo entre el tamaño de celda en grados y redondeando hacia abajo); `limites/2` devuelve el rectángulo para dibujarlo; `contar_celdas/2` cuenta con recursión; `resumen/3` entrega todo y, si le pasas tu ubicación, también **qué zona es la más concentrada, cuál es la más cercana y a qué distancia**.

### 3.3b Cómo se conectan (lo "dinámico")
El router acepta **los mismos filtros** (`colores`, `raza`, `desde`, `hasta`…) en `/f/busqueda`, `/f/estadisticas` y `/f/zonas`: convierte los textos del URL en un mapa de criterios y se lo pasa al núcleo (`Busqueda.filtro/1`). En la página:
* **Estadísticas → toca una barra de color →** se abre **Buscar cerca de mí** con ese color: ves dónde están y a cuántos metros de ti.
* **Zonas** con filtro de color y tu ubicación: la zona más concentrada puede estar lejos (p. ej. a 3.5 km) mientras otra con menos perros te queda a 172 m.
* Al cambiar un filtro, la pantalla vuelve a consultar sola (no hay botón "buscar").

### 3.4 La cáscara

* **`Datos`**: `Req.get(BACKEND_URL <> "/api/avistamientos")` → lista JSON → la convierte en structs. Si el backend falla devuelve `{:error, …}`.
* **`Router`**: con `Plug.Router`. Cada ruta (`get "/f/zonas"`) hace lo mismo: lee los parámetros → `Datos.avistamientos()` → llama al núcleo → `Jason.encode!` → responde. Los parámetros inválidos no truenan: se ignoran (`a_numero/2`, `a_fecha/2` regresan `nil`) y la búsqueda sigue con los demás.
* **`Application`**: arranca el servidor web **Bandit** supervisado (si cae, el supervisor lo reinicia).

### 3.5 Endpoints

| Ruta | Para qué |
| :--- | :--- |
| `GET /f/salud` | Comprobar que vive (`ok`) |
| `GET /f/avistamientos` | Ver que Elixir lee los datos del backend |
| `GET /f/busqueda?colores=&raza=&lat=&lon=&radio=&desde=&hasta=` | Búsqueda combinada, ordenada por cercanía si das `lat` y `lon` |
| `GET /f/estadisticas?n=5` (+ filtros) | Conteos, top y serie diaria |
| `GET /f/zonas?tam=500` (+ filtros, `lat`, `lon`) | Celdas con su total; con tu ubicación, zona más concentrada y más cercana |

---

## 4. Docker, explicado

### 4.1 El Dockerfile de Elixir (dos etapas)
```dockerfile
FROM elixir:1.18-alpine AS compilar      # Etapa 1: con todas las herramientas
RUN apk add --no-cache build-base git
ENV MIX_ENV=prod
COPY mix.exs mix.lock* ./                # primero SOLO las dependencias…
RUN mix deps.get --only prod && mix deps.compile   # …así Docker reutiliza esta capa si no cambian
COPY lib lib
RUN mix release                          # genera el programa empaquetado

FROM elixir:1.18-alpine                  # Etapa 2: solo para ejecutar
RUN apk add --no-cache tzdata            # zona horaria (hoy/ayer de Saltillo)
COPY --from=compilar /app/_build/prod/rel/funcional ./
CMD ["bin/funcional", "start"]
```

### 4.2 `docker-compose.yml`
| Servicio | Qué hace | Detalles |
| :--- | :--- | :--- |
| `backend` | Python + SQLite | Volúmenes `datos_db` (base) y `fotos` (imágenes): los datos **sobreviven** a reiniciar los contenedores y quedan fuera del código |
| `frontend` | nginx con los HTML/JS/CSS | Sin puertos publicados |
| `funcional` | Elixir | `BACKEND_URL=http://backend:8000`; **sin puertos publicados** |
| `proxy` | nginx | **Único** servicio con puerto: `${PUERTO_PROXY:-8080}:80` |
| `tunel` | cloudflared | Apunta a `http://proxy:80` |

Los contenedores se encuentran **por nombre de servicio** (`backend`, `proxy`…). Por eso dentro de Docker nunca se usa `localhost`: ahí significa "este mismo contenedor".

### 4.3 El proxy (`proxy/nginx.conf`)
```nginx
location /api/ { proxy_pass http://backend:8000; }   # sin "/" final: conserva el prefijo /api
location /f/   { proxy_pass http://funcional:4000; } # conserva /f
location /     { proxy_pass http://frontend:80; }
```
Gracias a esto el navegador solo habla con **un** origen, y el frontend usa rutas relativas (`/api/...`, `/f/...`) que funcionan igual en local y por el túnel.

### 4.4 Qué puertos están abiertos
Solo el del proxy (8080 en tu PC). Backend, Elixir y frontend solo se ven entre contenedores.

---

## 5. El túnel de Cloudflare

### 5.1 Qué es y cómo funciona
Tu computadora está detrás de un router: desde internet nadie puede entrar. El contenedor `cloudflared` hace lo contrario: **abre una conexión de salida** hacia Cloudflare y la deja abierta. Cloudflare te da una URL pública `https://algo.trycloudflare.com`; cuando alguien la visita, Cloudflare manda la petición **por esa conexión ya abierta** hasta tu proxy. Por eso:

* no se abren puertos en el router,
* no hace falta IP pública ni dominio,
* y la URL ya viene con **HTTPS** (necesario para que el celular permita cámara y GPS).

El comando es: `tunnel --no-autoupdate --protocol http2 --url http://proxy:80`. `--protocol http2` hace que use TCP/443 en lugar de UDP/7844 (QUIC), que muchas redes bloquean.

### 5.2 ¿Hay que hacer cambios en la web de Cloudflare?
**No.** El *quick tunnel* (`trycloudflare.com`) **no necesita cuenta, ni entrar a dash.cloudflare.com, ni configurar DNS**. Todo está en el comando del contenedor. Solo necesitas internet.

*Opcional (URL fija):* si algún integrante tiene cuenta de Cloudflare y un dominio, puede crear un túnel con nombre (Zero Trust → Networks → Tunnels; los menús pueden cambiar), apuntar un *Public hostname* al servicio `http://proxy:80`, guardar el token en `.env` como `TUNNEL_TOKEN` y cambiar el comando del servicio `tunel` a `tunnel --no-autoupdate run`. No es obligatorio.

### 5.3 Si "no abre": causas más comunes
| Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| Intentas abrir una URL "del túnel" y no existe | La URL no está en ninguna web: se **imprime en los registros** | `scripts\url-tunel.bat` (Windows) o `./scripts/url-tunel.sh`, o `docker compose logs tunel` |
| `ports are not available… 8080` | Otro programa usa el 8080: **el proxy no arrancó** y el túnel no tiene a dónde llegar (verás 502) | En `.env`: `PUERTO_PROXY=8081`, luego `docker compose down` y `docker compose up --build` |
| Error 1033 / 530 en la URL | El túnel se reinició (la URL **cambió**) o no está conectado | Vuelve a sacar la URL con el script |
| 502 Bad Gateway | El proxy no está corriendo | `docker compose ps`; revisa `docker compose logs proxy` |
| En los registros: errores de conexión o *timeout* | La red bloquea cloudflared (escuelas, hotspots) | Ya usa `http2`; prueba con otra red (datos del celular compartidos) |
| La URL no resuelve al instante | DNS tarda unos segundos | Espera 20–30 s |
| `localhost:8080` no abre en el celular | `localhost` es el propio celular | Usa la URL pública, o la IP de la PC en la misma Wi-Fi |

### 5.4 Limitaciones
* La URL **cambia** cada vez que se reinicia el contenedor `tunel`. Levántalo antes de clase y no lo toques.
* Solo vive mientras la computadora esté prendida, con Docker corriendo e internet.
* Es gratuito pero sin garantías de disponibilidad (sirve para demostración, no para producción).
