# 🐶 Registro de Perritos de la Calle

Proyecto: Programación Lógica y Funcional, 6:00 pm, Ago–Dic 2026.
Aplicación web para registrar perros en situación de calle con foto, nombre, raza, colores y
ubicación en un mapa (Leaflet). **El P1 funciona en Windows, macOS y Linux sin Docker y sin instalar
ningún servidor de base de datos** (usa SQLite, que ya viene con Python). **El P2 se levanta con Docker** (ver abajo).


---

# 🐕 Proyecto 2 — Funcionalidades en Elixir

> **Estado: Revisión 1 (26-oct-2026).** Hecho: `docker compose up` levanta frontend, backend, servicio Elixir, proxy y túnel; el servicio Elixir lee los avistamientos del backend; los tres núcleos tienen pruebas pasando. Pendiente para la Revisión 2 (3-nov): botones y vistas en el frontend para las tres funcionalidades.

## P2.1 Integrantes y funcionalidades

| Integrante | Rol (P1) | Funcionalidad P2 | Módulo del núcleo | Issue |
| :--- | :--- | :--- | :--- | :--- |
| René Emiliano Olivares Saucedo | Backend | 2. Posibles duplicados | `Perritos.Duplicados` | #__ |
| Xavier Israel Saucedo Castillo | DBA | 3. Estadísticas | `Perritos.Estadisticas` | #__ |
| Edwin Uriel Cárdenas Garza | Frontend | 4. Zonas de concentración | `Perritos.Zonas` | #__ |

Base compartida (pura): `Perritos.Avistamiento` (struct), `Perritos.Geo` (haversine), `Perritos.Colores` (catálogo cerrado).

## P2.2 Del P1 al P2

**Al terminar el P1:** FastAPI + SQLite + frontend estático (HTML/CSS/JS + Leaflet), registro idempotente de perritos con foto, mapa y lista.

**Agregado en el P2:** carpeta `funcional/` (servicio Elixir), `proxy/`, `docker-compose.yml`, Dockerfiles de backend, frontend y Elixir, `.env.example`, script `database/06_avistamientos_p2.sql` (90 avistamientos más) y el endpoint `GET /api/avistamientos`.

**Modificado del P1:**
* `backend/main.py`: nuevo endpoint `/api/avistamientos` (colores como lista con el principal primero, raza `null` si es desconocida/criollo, fecha ISO 8601).
* `backend/database.py`: las fotos ahora van por defecto a `~/PerritosStorage/media` (antes `./media` dentro del repo) y se copian las de prueba desde `database/fotos_prueba/`; `init_db` carga también el script 06.
* `database/02_catalogos.sql`: el color **"Negro y blanco" se desactiva** (`activo = 0`; los registros viejos se conservan). Son dos colores (principal + adicional); como color único rompería el índice de Jaccard (`[negro_y_blanco]` vs `[negro, blanco]` daría 0).
* Datos: de 15 a 105 avistamientos, con fechas repartidas (ago–oct 2026), 5 zonas, 20 perros sin verse desde septiembre y 20 reportes repetidos del mismo perro con otro nombre.

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
  Cambia cada vez que se reinicia el contenedor `tunel`. URL de la demostración: `https://________.trycloudflare.com`
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

Núcleo vs. cáscara: `lib/perritos/{avistamiento,colores,geo,duplicados,estadisticas,zonas}.ex` son **núcleo** (no leen BD, red, reloj ni imprimen); `datos.ex`, `router.ex` y `application.ex` son **cáscara**.

## P2.5 Funcionalidades

Todas responden JSON y se consultan con `GET` (ejemplo local: `curl http://localhost:8080/f/estadisticas?n=3`).

### 2. Posibles duplicados — Issue #__ — `funcional/lib/perritos/duplicados.ex`
`similitud = 0.4·colores (Jaccard) + 0.2·raza + 0.4·cercanía` (haversine, 500 m). Sirve para avisar "¿no será éste?" al registrar.

| Endpoint | Descripción |
| :--- | :--- |
| `GET /f/duplicados?id=7&umbral=0.8` | Parecidos a un avistamiento existente |
| `GET /f/duplicados?lat=25.44&lon=-100.99&colores=negro,blanco&raza=Beagle` | Parecidos a un perro **aún no registrado** (`raza` vacía = desconocida) |
| `GET /f/duplicados/pares?umbral=0.85` | Todas las parejas probables de la base |

```json
{"pares":[{"a":61,"nombre_a":"Pinto 2","b":101,"nombre_b":"Pepe (vecino)","similitud":0.986}]}
```
Paradigma: núcleo puro todo el módulo · pattern matching `similitud_raza/2`, `similitud_colores/2` · **regresa función** `filtro_umbral/1` · **recibe función** `entre_si/3` (parámetro `medida`) · **recursión** `parejas/1` · pipelines en `parecidos/4`.

### 3. Estadísticas — Issue #__ — `funcional/lib/perritos/estadisticas.ex`
Conteos por color (cada perro cuenta en todos sus colores), raza y día; los `n` más comunes; serie diaria sin huecos para la gráfica.

| Endpoint | Descripción |
| :--- | :--- |
| `GET /f/estadisticas?n=5` | Resumen completo |

```json
{"total":105,"por_color":[{"clave":"manchado","total":29}],"por_raza":[{"clave":"Bulldog","total":14}],"por_dia":[{"dia":"2026-08-02","total":3}]}
```
Paradigma: `contar/1` con `Enum.reduce` (sin contadores) · **regresa función** `contador_por/1` · **recibe función** (el mismo `contador_por/1`, `clave_de`) · **recursión** `serie_diaria/3` · pattern matching en `etiqueta_raza/1` y `serie_diaria/1` · **Stream**: `por_color`, `contador_por` usan `Stream.map/flat_map`, y las funciones aceptan lista o `Stream` (hay prueba). *Este es el Stream del equipo.*

### 4. Zonas de concentración — Issue #__ — `funcional/lib/perritos/zonas.ex`
Cuadrícula global de celdas de `tam` metros (50–5000, por defecto 500); el frontend solo pinta los rectángulos.

| Endpoint | Descripción |
| :--- | :--- |
| `GET /f/zonas?tam=500` | Celdas con su total y límites en grados |

```json
{"tam_m":500,"total":105,"zonas":[{"fila":5667,"columna":-20305,"total":8,"sur":25.4...,"norte":25.4...,"oeste":-100.9...,"este":-100.9...}]}
```
Paradigma: `celda/2` y `limites/2` puras · **regresa función** `celdador/1` · **recibe función** `contar_celdas/2` (`clasificar`) · **recursión** `contar_celdas/3` con acumulador · `reduce` en `resumen/2` · pattern matching en la cabeza de `zonas/2` (`{{fila, columna} = celda, total}`).

### Comprobar que el servicio lee los avistamientos
`GET /f/avistamientos` devuelve `{"total":105,"avistamientos":[...]}`.

## P2.6 Pruebas

El núcleo se prueba sin base de datos ni servidor (`test: "test --no-start"` en `mix.exs`):

```bash
docker compose run --rm herramientas mix local.hex --force      # solo la primera vez
docker compose run --rm herramientas mix local.rebar --force    # solo la primera vez
docker compose run --rm herramientas mix deps.get               # genera mix.lock: súbanlo a git
docker compose run --rm herramientas mix test
```
Resultado esperado: `15 doctests, 33 tests, 0 failures` (`test/duplicados_test.exs`, `estadisticas_test.exs`, `zonas_test.exs`, `geo_test.exs`).

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
├── frontend/   base.html · style.css · funciones.js
├── database/   01_schema · 02_catalogos · 03_datos_prueba · 04_consultas · 05_respaldo.md · 06_avistamientos_p2 (P2) · fotos_prueba/ · respaldo_perritos.sql
├── funcional/  (P2) servicio Elixir: lib/perritos/*.ex · test/*.exs · Dockerfile · mix.exs
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
