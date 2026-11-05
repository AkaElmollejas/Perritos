# Git del Proyecto 2: quién sube qué

El enunciado pide: **mismo repositorio** (sin repositorio nuevo ni historial reescrito), **un issue por funcionalidad**, **una rama por funcionalidad**, commits **de su autor** que mencionan el issue (`#n`) y el último cierra con `Closes #n`.

## 1. Repartición de archivos (cada quien sube y defiende lo suyo)

| Integrante | Funcionalidad | Archivos que le tocan |
| :--- | :--- | :--- |
| **René** (Backend) | 1. Búsqueda combinada | `funcional/lib/perritos/{busqueda,avistamiento,colores,geo,datos,router,application}.ex`, `funcional/{mix.exs,Dockerfile,.dockerignore}`, `funcional/test/{busqueda,geo}_test.exs`, `backend/{main.py,database.py,Dockerfile}`, `frontend/ui_busqueda.js` |
| **Xavier** (DBA) | 3. Estadísticas | `funcional/lib/perritos/estadisticas.ex`, `funcional/test/estadisticas_test.exs`, `frontend/ui_estadisticas.js`, `database/{02_catalogos.sql,06_avistamientos_p2.sql,respaldo_perritos.sql,fotos_prueba/}`, `.env.example` |
| **Edwin** (Frontend) | 4. Zonas de concentración | `funcional/lib/perritos/zonas.ex`, `funcional/test/zonas_test.exs`, `frontend/{ui_zonas.js,base.html,funciones.js,style.css,Dockerfile,nginx.conf}`, `proxy/nginx.conf`, `docker-compose.yml`, `scripts/`, `README.md`, `docs/` |

Cada quien debe poder **explicar línea por línea** lo suyo en la demostración (ver `docs/EXPLICACION_P2.md`).

## 2. Issues (crear en GitHub → Issues → New issue, asignado a su autor)

**#1 — Funcionalidad 1: búsqueda combinada "cerca de mí"** (René)
> Buscar perritos por color, raza, cercanía a mi ubicación y rango de fechas, en cualquier combinación. Cada criterio es una función y se combinan con `todos/1` (Y) y `alguno/1` (O). Núcleo puro `Perritos.Busqueda`, endpoint `/f/busqueda`, ventana "Buscar cerca de mí" con mapa y lista ordenada por distancia.

**#2 — Funcionalidad 3: estadísticas** (Xavier)
> Conteos por color, raza y día; los n más comunes; gráfica de barras en el frontend; al tocar un color se abre la búsqueda para ver dónde están. Núcleo puro `Perritos.Estadisticas` (reduce y Stream), endpoint `/f/estadisticas`, ventana "Estadísticas".

**#3 — Funcionalidad 4: zonas de concentración** (Edwin)
> Dividir la ciudad en una cuadrícula y mostrar en el mapa cuántos perros hay por celda, con filtro de color y la distancia a la zona más concentrada y a la más cercana a mí. Núcleo puro `Perritos.Zonas`, endpoint `/f/zonas`, ventana "Zonas".

## 3. Aplicar este paquete a la rama `prueba` (una sola vez, quien tenga el repositorio)

```bash
git checkout prueba
git pull origin prueba
# 1) Borrar los archivos viejos de MySQL que quedaron sueltos en la raíz
git rm main.py database.py services.py database/respaldo_perritos_utf8.sql
git rm -r --cached media            # las fotos ya no viven en el repo (se movieron a database/fotos_prueba)
# 2) Copiar encima TODO el contenido de la carpeta "Perritos" del ZIP (sobrescribir)
#    y borrar la carpeta local media/ si existe
git status                          # revisar
```

## 4. Cada integrante, en SU rama

```bash
git checkout -b feature/busqueda          # Edwin: feature/zonas · Xavier: feature/estadisticas
git add <solo sus archivos de la tabla>
git commit -m "Agrega núcleo puro de búsqueda combinada con filtros y pruebas (#1)"
git commit -m "Agrega ventana Buscar cerca de mí con mapa y distancias (#1)"
git commit -m "Documenta endpoint de búsqueda en el README. Closes #1"
git push origin feature/busqueda
```
Luego en GitHub: **Pull request** → `feature/...` hacia `main`, y **otro integrante la revisa** y la aprueba. El profesor debe estar como colaborador (Settings → Collaborators).

Buenos mensajes de commit dicen *qué cambió*: "Agrega…", "Corrige…", "Documenta…". Evitar "cambios", "ya quedó", "asdf".

## 5. Antes del jueves 5 de noviembre
* Todo fusionado en `main` antes de que empiece la clase (lo posterior no cuenta).
* `docker compose run --rm herramientas mix deps.get` y subir `funcional/mix.lock`.
* URL del túnel escrita en el README el día de la demostración.
