# 🐶 Registro de Perritos de la Calle

Proyecto: Programación Lógica y Funcional, 6:00 pm, Ago–Dic 2026.
Aplicación web para registrar perros en situación de calle con foto, nombre, raza, colores y
ubicación en un mapa (Leaflet). **Funciona en Windows, macOS y Linux, sin Docker y sin instalar
ningún servidor de base de datos** (usa SQLite, que ya viene con Python).

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
(14 razas, 13 colores) y los **15 perritos de prueba**. Abre:

* Aplicación: http://localhost:8000
* Documentación interactiva de la API: http://localhost:8000/docs

El mismo servidor entrega la API **y** la página, por eso no hace falta un segundo servidor para el frontend.

Comprobar los datos: abre http://localhost:8000/api/perritos (deben aparecer 15).

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
├── database/   01_schema.sql · 02_catalogos.sql · 03_datos_prueba.sql · 04_consultas.sql · 05_respaldo.md · respaldo_perritos.sql
├── media/      pruebas/ (15 fotos de ejemplo). Las fotos que suban los usuarios se guardan aquí, fuera del código y fuera de git.
├── requirements.txt
└── README.md
```

Las fotos de `media/pruebas/` son imágenes de ejemplo; para usar fotos reales reemplázalas conservando el nombre (`max.png`, `luna.png`, …).

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

* Volver al estado inicial: borra `database/perritos.db` y reinicia el backend.
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
