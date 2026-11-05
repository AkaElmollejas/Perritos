# 🐶 Registro de Perritos de la Calle

Proyecto: Programación Lógica y Funcional, 6:00 pm, Ago–Dic 2026.
Aplicación web para registrar perros en situación de calle con foto, nombre, raza, colores y
ubicación en un mapa (Leaflet). **El P1 funciona en Windows, macOS y Linux sin Docker y sin instalar
ningún servidor de base de datos** (usa SQLite, que ya viene con Python). **El P2 se levanta con Docker** (ver abajo).


---

# 🐕 Proyecto 2 — Funcionalidades en Elixir

> **Estado: completo para la entrega (5-nov-2026).** Las 3 funcionalidades en Elixir (núcleo puro + cáscara) están integradas en el frontend, con 38 pruebas + 17 doctests pasando. Más detalle: [`docs/EXPLICACION_P2.md`](docs/EXPLICACION_P2.md) (cómo funciona el código, Docker y el túnel) y [`docs/GIT_P2.md`](docs/GIT_P2.md) (issues, ramas y quién sube qué).

## P2.1 Integrantes y funcionalidades

| Integrante | Rol (P1) | Funcionalidad P2 | Módulo del núcleo | Issue |
| :--- | :--- | :--- | :--- | :--- |
| René Emiliano Olivares Saucedo | Backend | 1. Búsqueda combinada ("cerca de mí") | `Perritos.Busqueda` | #__ |
| Xavier Israel Saucedo Castillo | DBA | 
| Edwin Uriel Cárdenas Garza | Frontend |

Base compartida (pura): `Perritos.Avistamiento` (struct), `Perritos.Geo` (haversine), `Perritos.Colores` (catálogo cerrado).

## P2.2 Del P1 al P2

**Al terminar el P1:** FastAPI + SQLite + frontend estático (HTML/CSS/JS + Leaflet), registro idempotente de perritos con foto, mapa y lista.

**Agregado en el P2:** carpeta `funcional/` (servicio Elixir), `proxy/`, `docker-compose.yml`, Dockerfiles de backend, frontend y Elixir, `.env.example`, script `database/06_avistamientos_p2.sql` (90 avistamientos más), el endpoint `GET /api/avistamientos`, y en el frontend `ui_busqueda.js`, `ui_estadisticas.js`, `ui_zonas.js` (una pantalla por funcionalidad), `scripts/` y `docs/`.

**Modificado del P1:**
* `backend/main.py`: nuevo endpoint `/api/avistamientos` (colores como lista con el principal primero, raza `null` si es desconocida/criollo, fecha ISO 8601).
* `backend/database.py`: las fotos ahora van por defecto a `~/PerritosStorage/media` (antes `./media` dentro del repo) y se copian las de prueba desde `database/fotos_prueba/`; `init_db` carga también el script 06.
* `database/02_catalogos.sql`: el color **"Negro y blanco" se desactiva** (`activo = 0`; los registros viejos se conservan). Son dos colores (principal + adicional); como color único, `negro_y_blanco` no coincidiría al buscar por `negro` o por `blanco`.
* `frontend/funciones.js`: constante `F_BASE_URL`, evento `abierto` al abrir un diálogo y utilidades compartidas al final (`slug`, `pedirUbicacionUsuario`, `formatearDistancia`, `copiarOpciones`). `base.html`: el botón *Cerca de mí* del P1 ahora se llama **Perritos registrados**; botones nuevos **Buscar cerca de mí**, **Estadísticas** y **Zonas** con sus diálogos. `style.css`: estilos de gráficas, zonas y filtros.
* Datos: de 15 a 105 avistamientos, con fechas repartidas (ago–oct 2026), 5 zonas de concentración y 20 perros que no se ven desde septiembre (para probar fechas y zonas).

## P2.3 Levantarla con Docker (desde un clon limpio)

Requisito: Docker Desktop (Windows/macOS) o Docker Engine con Compose (Linux). Nada más.

```bash
git clone https://github.com/EdwinCardeGar/Perritos.git
cd Perritos
cp .env.example .env          # Windows CMD: copy .env.example .env
docker compose up --build
```

* Local: http://localhost:8080 (proxy). API Elixir: http://localhost:8080/f/salud → `ok`.
* **URL pública (túnel de Cloudflare):** en otra terminal
  ```bash
  docker compose logs tunel | grep trycloudflare      # Windows PowerShell: docker compose logs tunel | Select-String trycloudflare
  ```
  O más fácil: `scripts\url-tunel.bat` (Windows) / `./scripts/url-tunel.sh` (Mac/Linux).
  Cambia cada vez que se reinicia el contenedor `tunel`. URL de la demostración: `https://________.trycloudflare.com`
* ¿El puerto 8080 está ocupado (`ports are not available`)? Pon `PUERTO_PROXY=8081` en tu `.env`, haz `docker compose down` y vuelve a levantar.
* Para volver a empezar con datos limpios: `docker compose down -v` (borra los volúmenes de BD y fotos).

## P2.4 Arquitectura

```
visitante ──▶ https://….trycloudflare.com
                    │
              túnel (cloudflared)
                    │
              proxy (nginx) ── único puerto publicado (8080 local)
        ┌───────────┼──────────────┐
        │ /         │ /api/        │ /f/
   frontend      backend (P1)    funcional (Elixir)
   (nginx)     FastAPI + SQLite   CÁSCARA: router + Datos (Req)
                    ▲              NÚCLEO: funciones puras
                    └── GET /api/avistamientos ──┘
```

**Cómo obtiene los datos Elixir: opción B** (a través del backend, con `Req`). Se eligió porque la base del P1 es **SQLite**, y Postgrex/MyXQL solo hablan con PostgreSQL/MySQL; así no se duplica el acceso a la base ni se comparte el archivo `.db` entre contenedores. Son **5 contenedores** (frontend, backend, funcional, proxy, túnel); no hay contenedor de base de datos porque SQLite es un archivo dentro del volumen `datos_db`. (`herramientas` solo existe para correr `mix` y no arranca con `up`.)

Núcleo vs. cáscara: `lib/perritos/{avistamiento,colores,geo,busqueda,estadisticas,zonas}.ex` son **núcleo** (no leen BD, red, reloj ni imprimen); `datos.ex`, `router.ex` y `application.ex` son **cáscara**.

## P2.5 Funcionalidades

Todas responden JSON y se consultan con `GET` (ejemplo local: `curl http://localhost:8080/f/estadisticas?n=3`).

### 1. Búsqueda combinada ("cerca de mí") — Issue #__ — `funcional/lib/perritos/busqueda.ex`
Encuentra perritos por **color, raza, cercanía a tu ubicación y fechas**, en cualquier combinación. Cada criterio es una función; se combinan con `todos/1` (Y) y `alguno/1` (O). Con tu ubicación ordena del más cercano al más lejano.

| Endpoint | Descripción |
| :--- | :--- |
| `GET /f/busqueda?colores=negro,blanco&modo=todos&raza=Beagle&lat=25.42&lon=-100.99&radio=1000&desde=2026-09-01&hasta=2026-10-30&limite=20` | Todos los parámetros son opcionales. `modo=todos` exige todos los colores (por omisión, alguno). Sin `radio`, no limita la distancia |

```json
{"total":29,"resultados":[{"id":58,"nombre":"Panda","colores":["manchado","canela"],"distancia_m":380,"foto":"/api/fotos/pruebas/max.png","raza":"Poodle","lat":25.42,"lon":-100.99,"fecha":"2026-09-28T17:14:00"}]}
```
Paradigma: **regresan función** `con_color/1`, `de_raza/1`, `cerca_de/2`, `entre_fechas/2` · **reciben funciones y regresan una función, con recursión explícita** `todos/1` y `alguno/1` · pattern matching en `filtro/1` (una cláusula por criterio) y en `entre_fechas/2` (límites `nil`) · pipeline en `buscar/4`.

### 3. Estadísticas — Issue #__ — `funcional/lib/perritos/estadisticas.ex`
Conteos por color (cada perro cuenta en todos sus colores), raza y día; los `n` más comunes; serie diaria sin huecos para la gráfica.

| Endpoint | Descripción |
| :--- | :--- |
| `GET /f/estadisticas?n=5` | Resumen completo. Acepta los mismos filtros que la búsqueda (`colores`, `raza`, `desde`, `hasta`…) |

```json
{"total":105,"por_color":[{"clave":"manchado","total":29}],"por_raza":[{"clave":"Bulldog","total":14}],"por_dia":[{"dia":"2026-08-02","total":3}]}
```
Paradigma: `contar/1` con `Enum.reduce` (sin contadores) · **regresa función** `contador_por/1` · **recibe función** (el mismo `contador_por/1`, `clave_de`) · **recursión** `serie_diaria/3` · pattern matching en `etiqueta_raza/1` y `serie_diaria/1` · **Stream**: `por_color`, `contador_por` usan `Stream.map/flat_map`, y las funciones aceptan lista o `Stream` (hay prueba). *Este es el Stream del equipo.*

### 4. Zonas de concentración — Issue #__ — `funcional/lib/perritos/zonas.ex`
Cuadrícula global de celdas de `tam` metros (50–5000, por defecto 500); el frontend solo pinta los rectángulos.

| Endpoint | Descripción |
| :--- | :--- |
| `GET /f/zonas?tam=500&colores=manchado&lat=25.42&lon=-100.99` | Celdas con su total y límites en grados. Acepta los filtros de la búsqueda; con `lat` y `lon` agrega `mas_concentrada` y `mas_cercana` con su `distancia_m` |

```json
{"tam_m":500,"total":105,"zonas":[{"fila":5667,"columna":-20305,"total":8,"sur":25.4...,"norte":25.4...,"oeste":-100.9...,"este":-100.9...}],"mas_concentrada":{"total":8,"distancia_m":3500},"mas_cercana":{"total":4,"distancia_m":172}}
```
Paradigma: `celda/2` y `limites/2` puras · **regresa función** `celdador/1` · **recibe función** `contar_celdas/2` (`clasificar`) · **recursión** `contar_celdas/3` con acumulador · `reduce` en `resumen/3` · pattern matching en la cabeza de `zonas/2` (`{{fila, columna} = celda, total}`).

### Comprobar que el servicio lee los avistamientos
`GET /f/avistamientos` devuelve `{"total":105,"avistamientos":[...]}`.

## P2.5b Cómo se usa en la app

| Funcionalidad | Dónde | Qué hace |
| :--- | :--- | :--- |
| Búsqueda combinada | Barra superior → **Buscar cerca de mí** | Pide tu ubicación y muestra en mapa y lista los perritos del más cercano al más lejano ("A 380 m de ti"). Filtros de **color, raza y distancia**: al cambiar cualquiera se vuelve a buscar solo |
| Estadísticas | Barra superior → **Estadísticas** | Barras de colores y razas más comunes y avistamientos por día. **Toca una barra de color** y se abre la búsqueda con ese color para ver dónde están y qué tan cerca te quedan |
| Zonas | Barra superior → **Zonas** | Mapa con cuadrícula (250 m a 2 km); más rojo = más perros. Filtro de color y botón **¿Qué tan lejos estoy?**: dice a qué distancia queda la zona más concentrada (borde negro) y la zona con perros más cercana |

Si no das permiso de ubicación, todo sigue funcionando: se muestran los resultados sin distancia.

## P2.5c Cloudflare: ¿hay que configurar algo en su página web?

**No.** El túnel rápido (`trycloudflare.com`) no pide cuenta, ni panel web, ni DNS: todo está en el comando del contenedor `tunel`. La URL no está en ninguna página; se imprime en los registros (`scripts/url-tunel.*`). Si "no abre": casi siempre es que el proxy no arrancó (puerto 8080 ocupado), que la URL cambió tras reiniciar, o que la red bloquea el túnel. Tabla completa de causas y soluciones en [`docs/EXPLICACION_P2.md`](docs/EXPLICACION_P2.md#53-si-no-abre-causas-más-comunes).

## P2.6 Pruebas

El núcleo se prueba sin base de datos ni servidor (`test: "test --no-start"` en `mix.exs`):

```bash
docker compose run --rm herramientas mix local.hex --force      # solo la primera vez
docker compose run --rm herramientas mix local.rebar --force    # solo la primera vez
docker compose run --rm herramientas mix deps.get               # genera mix.lock: súbanlo a git
docker compose run --rm herramientas mix test
```
Resultado esperado: `17 doctests, 38 tests, 0 failures` (`test/busqueda_test.exs`, `estadisticas_test.exs`, `zonas_test.exs`, `geo_test.exs`).

---

# Proyecto 1 — Instalación sin Docker

## 1. Integrantes y roles

| Integrante | Rol | Responsabilidades |
| :--- | :--- | :--- |
| **Edwin Uriel Cárdenas Garza** | Frontend | `base.html`, `style.css`, `funciones.js`, mapa Leaflet, cámara/archivo, validaciones en cliente, diseño móvil. |
| **René Emiliano Olivares Saucedo** | Backend | API REST (FastAPI), validación en servidor, almacenamiento externo de fotos, idempotencia. |
| **Xavier Israel Saucedo Castillo** | DBA | Esquema, catálogos, datos de prueba y respaldos (`database/`). |

## 2. Requisitos

* **Python 3.10 o superior** (`python --version`; en Mac/Linux `python3 --version`). Descarga: https://www.python.org/downloads/ (en Windows marca *"Add python.exe to PATH"*).
* **Git** (https://git-scm.com/downloads).
* Un navegador moderno (Chrome, Edge, Firefox, Safari).
* Internet (para los mapas de OpenStreetMap/Leaflet y para el túnel de Cloudflare).

No se necesita MySQL, Docker ni configurar variables de entorno.

## 3. Instalación

```bash
git clone https://github.com/EdwinCardeGar/Perritos.git
cd Perritos
```

**Windows (CMD o PowerShell)**
```cmd
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```
> Si PowerShell bloquea `activate`: `Set-ExecutionPolicy -Scope Process Bypass` y vuelve a intentar.

**macOS / Linux**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 4. Ejecución (un solo comando)

```bash
cd backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```
*(en Mac/Linux, `python3` si `python` no existe; con el entorno activado normalmente basta `python`)*

Al primer arranque se crea automáticamente `database/perritos.db` con las tablas, los catálogos
(14 razas, 12 colores activos) y los **105 avistamientos de prueba**. Abre:

* Aplicación: http://localhost:8000
* Documentación interactiva de la API: http://localhost:8000/docs

El mismo servidor entrega la API **y** la página, por eso no hace falta un segundo servidor para el frontend.

Comprobar los datos: abre http://localhost:8000/api/perritos (deben aparecer 105).

## 5. Acceso desde el celular u otra PC

### Opción A — Internet con Cloudflare Tunnel (recomendada: da HTTPS, necesario para cámara y GPS)

1. Instala `cloudflared` (una sola vez):
   * Windows: `winget install --id Cloudflare.cloudflared` (o descarga el `.exe` en https://github.com/cloudflare/cloudflared/releases)
   * macOS: `brew install cloudflared`
   * Ubuntu/Debian: descarga el `.deb` de la página de releases anterior.
2. Con el backend corriendo (paso 4), abre **otra terminal** y ejecuta:
   ```bash
   cloudflared tunnel --url http://localhost:8000
   ```
3. Aparecerá una URL como `https://algo-aleatorio.trycloudflare.com`. Ábrela desde cualquier celular
   o computadora (no necesitan estar en la misma red). La página funciona sin cambios porque usa rutas relativas (`/api`).

> La URL cambia cada vez que reinicias el túnel y solo existe mientras ambas terminales sigan abiertas. No requiere cuenta de Cloudflare. Para una URL fija se necesita cuenta y dominio propio (túnel con nombre).

### Opción B — Misma red Wi-Fi (sin Cloudflare)

1. Averigua la IP de la PC: `ipconfig` (Windows) o `ifconfig` / `ipconfig getifaddr en0` (Mac).
2. En el celular abre `http://<IP>:8000` (ej. `http://192.168.0.15:8000`). Permite el puerto 8000 en el firewall si lo pide.
3. Sin HTTPS, Chrome móvil bloquea GPS y cámara: usa la Opción A, o selecciona la ubicación tocando el mapa y elige la foto desde la galería.

## 6. Estructura del repositorio

```
Perritos/
├── backend/    main.py (API) · database.py · services.py (funcional) · respaldo.py · test_idempotency.py
├── database/   01_schema · 02_catalogos · 03_datos_prueba · 04_consultas · 05_respaldo.md · 06_avistamientos_p2 (P2) · fotos_prueba/ · respaldo_perritos.sql
├── frontend/   base.html · style.css · funciones.js · ui_busqueda.js · ui_estadisticas.js · ui_zonas.js · Dockerfile (P2)
├── funcional/  (P2) servicio Elixir: lib/perritos/*.ex · test/*.exs · Dockerfile · mix.exs
├── docs/       (P2) EXPLICACION_P2.md · GIT_P2.md
├── scripts/    (P2) url-tunel.bat · url-tunel.sh
├── proxy/      (P2) nginx.conf — única puerta de entrada
├── docker-compose.yml · .env.example   (P2)
├── requirements.txt
└── README.md
```

**Las fotos NO viven en el repositorio**: se guardan en `RUTA_IMAGENES` (por defecto `~/PerritosStorage/media`, fuera del proyecto; en Docker, el volumen `fotos`). Al arrancar, el backend copia ahí las fotos de ejemplo de `database/fotos_prueba/` (imágenes de relleno; reemplázalas por fotos reales conservando el nombre).

## 7. Endpoints de la API

| Método | Endpoint | Descripción |
| :--- | :--- | :--- |
| POST | `/api/perritos` | Registra un perrito (`multipart/form-data`). Header obligatorio `Idempotency-Key` (UUID). Campos: `nombre`, `latitud`, `longitud`, `color_principal`, `id_raza` (opcional), `colores_adicionales` (ej. `"2,3"`), `foto`. Responde **201** si es nuevo y **200** si la clave ya existía. |
| GET | `/api/perritos` | Lista todos los perritos (pines del mapa y tarjetas). |
| GET | `/api/perritos/{id}` | Detalle de un perrito. |
| GET | `/api/catalogos/razas` | Catálogo de razas (alias `/api/razas`). |
| GET | `/api/catalogos/colores` | Catálogo de colores (alias `/api/colores`). |
| GET | `/api/fotos/{archivo}` | Sirve la foto guardada fuera del código fuente (protegido contra `../`). |
| GET | `/api/estadisticas/colores` | Perritos por color (agregación SQL). |

## 8. Base de datos (SQLite)

Esquema según `diagrama_er.png`: `razas`, `colores`, `perritos` y la tabla intermedia `perrito_colores`
(colores adicionales, máximo 2; el principal está en `perritos.color_principal`).
Restricciones: llaves foráneas activas, `CHECK` de nombre no vacío y de rango de latitud/longitud, y `UNIQUE` sobre `clave_idempotencia`.

* Volver al estado inicial: borra `database/perritos.db` y reinicia el backend (ahora trae 105 avistamientos: 15 del P1 + 90 del P2; si tu `perritos.db` es anterior, bórrala para recibirlos).
* Respaldo/restauración: ver `database/05_respaldo.md` (`python respaldo.py respaldar | restaurar`).

## 9. Idempotencia del registro

* **Cliente:** `funciones.js` genera un UUID al cargar la página y lo envía en `Idempotency-Key`. Solo se renueva después de un registro exitoso; si hay error de red o doble clic se reenvía la misma clave.
* **Servidor:** busca la clave en `perritos.clave_idempotencia` (columna `UNIQUE`). Si existe, no inserta nada y devuelve **200** con el mismo `id`. Si dos peticiones llegan al mismo tiempo, la restricción `UNIQUE` frena a la segunda y también recibe el registro original.
* **Demostración** (con el servidor encendido):
  ```bash
  cd backend
  python test_idempotency.py
  ```
  Envía dos peticiones con la misma clave y comprueba: primera 201, segunda 200, mismo ID y una sola fila nueva.

## 10. Sección Paradigmas

* **Declarativo (SQL):** filtrado, `JOIN`, ordenamiento y agregación (`GROUP BY` + `COUNT`, `GROUP_CONCAT`) se resuelven en el motor SQL (`main.py`, `database/04_consultas.sql`), sin ciclos en Python.
* **Declarativo (frontend):** HTML y CSS describen la estructura y el estilo del formulario.
* **Funcional:** `backend/services.py → procesar_colores_funcional` usa `map`, `filter` y `reduce` para normalizar, quitar vacíos y duplicados y limitar a 3 colores, sin mutar colecciones.
* **Imperativo:** `main.py → registrar_perrito` ejecuta la secuencia estricta: validar clave → revisar idempotencia → validar campos e imagen (magic bytes) → guardar foto → insertar en transacción.

## 11. Problemas comunes

| Problema | Solución |
| :--- | :--- |
| `python` no se reconoce | Reinstala Python marcando *Add to PATH*, o usa `py` (Windows) / `python3` (Mac/Linux). |
| `No module named 'multipart'` o `fastapi` | Activa el entorno (`venv`) y ejecuta `pip install -r requirements.txt`. |
| Puerto 8000 ocupado | Usa `--port 8001` (y `cloudflared tunnel --url http://localhost:8001`). |
| Cámara/GPS bloqueados en el celular | Necesitan HTTPS: usa el túnel de Cloudflare (sección 5A). |
| Cambios en JS/CSS no se ven | Recarga forzada: `Ctrl + F5` (`Cmd + Shift + R` en Mac). |
| Quiero empezar de cero | Borra `database/perritos.db` y reinicia el backend. |

## 12. Despliegue permanente (opcional)

Servidor Linux con FastAPI bajo `systemd`, Nginx/Caddy como proxy inverso con HTTPS hacia el puerto 8000, y `media/` en una ruta fuera del código (variable `RUTA_IMAGENES`). La ruta de la BD puede cambiarse con `DB_PATH`.

## 13. Capturas de pantalla
*(Adjuntar: vista móvil, formulario con foto, mapa general con pines y lista con miniaturas.)*

**URL pública de la demostración:** `https://________.trycloudflare.com`
