import re
import unicodedata
import uuid
import sqlite3
from contextlib import asynccontextmanager
from typing import Optional

import filetype
from fastapi import FastAPI, UploadFile, File, Form, Header, HTTPException
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from database import BASE_DIR, STORAGE_DIR, copiar_fotos_prueba, get_db_connection, init_db
from services import procesar_colores_funcional

FRONTEND_DIR = BASE_DIR / "frontend"
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_BYTES = 10 * 1024 * 1024  # 10 MB


@asynccontextmanager
async def lifespan(app: FastAPI):
    STORAGE_DIR.mkdir(parents=True, exist_ok=True)
    copiar_fotos_prueba()
    init_db()
    yield


app = FastAPI(title="Perritos API", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

SQL_LISTADO = """
    SELECT p.id_perrito AS id, p.nombre,
           COALESCE(r.nombre, 'Sin especificar') AS raza,
           p.latitud, p.longitud, p.foto, p.descripcion, p.fecha_registro,
           cp.nombre AS color_principal,
           COALESCE(GROUP_CONCAT(ca.nombre, ', '), '') AS colores_adicionales
    FROM perritos p
    LEFT JOIN razas r ON r.id_raza = p.id_raza
    JOIN colores cp ON cp.id_color = p.color_principal
    LEFT JOIN perrito_colores pc ON pc.id_perrito = p.id_perrito
    LEFT JOIN colores ca ON ca.id_color = pc.id_color
    {filtro}
    GROUP BY p.id_perrito
    ORDER BY p.fecha_registro DESC, p.id_perrito DESC
"""


def _perrito_a_dict(f):
    return {
        "id": f["id"], "nombre": f["nombre"], "raza": f["raza"],
        "latitud": f["latitud"], "longitud": f["longitud"],
        "foto_url": f"/api/fotos/{f['foto']}", "descripcion": f["descripcion"],
        "fecha_registro": f["fecha_registro"],
        "color_principal": f["color_principal"],
        "colores_adicionales": f["colores_adicionales"],
    }


def _catalogo(tabla, col_id):
    conn = get_db_connection()
    try:
        filas = conn.execute(
            f"SELECT {col_id} AS id, nombre FROM {tabla} WHERE activo = 1 ORDER BY nombre"
        ).fetchall()
        return [dict(f) for f in filas]
    finally:
        conn.close()


# ---------- Catálogos ----------
@app.get("/api/catalogos/razas")
@app.get("/api/razas")
def listar_razas():
    return _catalogo("razas", "id_raza")


@app.get("/api/catalogos/colores")
@app.get("/api/colores")
def listar_colores():
    return _catalogo("colores", "id_color")



# ---------- P2: avistamientos para el servicio Elixir ----------
SQL_AVISTAMIENTOS = """
    SELECT p.id_perrito AS id, p.nombre, r.nombre AS raza,
           p.latitud AS lat, p.longitud AS lon, p.foto,
           REPLACE(p.fecha_registro, ' ', 'T') AS fecha,
           cp.nombre AS color_principal,
           GROUP_CONCAT(ca.nombre, '|') AS adicionales
    FROM perritos p
    LEFT JOIN razas r ON r.id_raza = p.id_raza
    JOIN colores cp ON cp.id_color = p.color_principal
    LEFT JOIN perrito_colores pc ON pc.id_perrito = p.id_perrito
    LEFT JOIN colores ca ON ca.id_color = pc.id_color
    GROUP BY p.id_perrito
    ORDER BY p.id_perrito
"""


def _slug(nombre):
    """'Café' -> 'cafe', 'Marrón' -> 'marron' (el catálogo cerrado de colores de Elixir)."""
    sin_acentos = "".join(c for c in unicodedata.normalize("NFD", nombre) if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", sin_acentos.lower()).strip("_")


@app.get("/api/avistamientos")
def listar_avistamientos():
    """Mismos perritos pero en la forma que consume Elixir: colores como lista
    (el principal primero), raza None si es desconocida/criollo, fecha ISO 8601."""
    conn = get_db_connection()
    try:
        filas = conn.execute(SQL_AVISTAMIENTOS).fetchall()
    finally:
        conn.close()
    resultado = []
    for f in filas:
        extras = f["adicionales"].split("|") if f["adicionales"] else []
        raza = None if f["raza"] in (None, "Sin raza definida / criollo") else f["raza"]
        resultado.append({
            "id": f["id"], "nombre": f["nombre"], "raza": raza,
            "colores": [_slug(c) for c in [f["color_principal"], *extras]],
            "lat": f["lat"], "lon": f["lon"],
            "foto": f"/api/fotos/{f['foto']}", "fecha": f["fecha"],
        })
    return resultado


# ---------- Perritos ----------
@app.get("/api/perritos")
def listar_perritos():
    conn = get_db_connection()
    try:
        filas = conn.execute(SQL_LISTADO.format(filtro="")).fetchall()
        return [_perrito_a_dict(f) for f in filas]
    finally:
        conn.close()


@app.get("/api/perritos/{id_perrito}")
def detalle_perrito(id_perrito: int):
    conn = get_db_connection()
    try:
        fila = conn.execute(
            SQL_LISTADO.format(filtro="WHERE p.id_perrito = ?"), (id_perrito,)
        ).fetchone()
        if fila is None or fila["id"] is None:
            raise HTTPException(status_code=404, detail="Perrito no encontrado")
        return _perrito_a_dict(fila)
    finally:
        conn.close()


@app.get("/api/estadisticas/colores")
def estadisticas_colores():
    conn = get_db_connection()
    try:
        filas = conn.execute(
            """SELECT c.nombre AS color, COUNT(p.id_perrito) AS total_perritos
               FROM colores c LEFT JOIN perritos p ON p.color_principal = c.id_color
               GROUP BY c.id_color, c.nombre ORDER BY total_perritos DESC, c.nombre"""
        ).fetchall()
        return [dict(f) for f in filas]
    finally:
        conn.close()


def _buscar_por_clave(conn, clave):
    return conn.execute(
        "SELECT id_perrito, foto FROM perritos WHERE clave_idempotencia = ?", (clave,)
    ).fetchone()


def _respuesta(fila, mensaje):
    return {"mensaje": mensaje, "id": fila["id_perrito"], "id_perrito": fila["id_perrito"],
            "foto_url": f"/api/fotos/{fila['foto']}"}


@app.post("/api/perritos", status_code=201)
def registrar_perrito(
    nombre: str = Form(...),
    latitud: float = Form(...),
    longitud: float = Form(...),
    color_principal: int = Form(...),
    id_raza: Optional[int] = Form(None),
    colores_adicionales: Optional[str] = Form(None),  # "2,3"
    foto: UploadFile = File(...),
    idempotency_key: str = Header(..., alias="Idempotency-Key"),
):
    try:
        clave = str(uuid.UUID(idempotency_key))
    except ValueError:
        raise HTTPException(400, "Idempotency-Key debe ser un UUID válido.")

    conn = get_db_connection()
    ruta_destino = None
    try:
        # 1. Idempotencia: si la clave ya existe, se devuelve el registro previo (200)
        previo = _buscar_por_clave(conn, clave)
        if previo:
            return JSONResponse(status_code=200,
                                content=_respuesta(previo, "Perrito previamente registrado (idempotencia)"))

        # 2. Validaciones de servidor
        nombre = nombre.strip()
        if not nombre or len(nombre) > 100:
            raise HTTPException(400, "El nombre es obligatorio (máximo 100 caracteres).")
        if not (-90 <= latitud <= 90 and -180 <= longitud <= 180):
            raise HTTPException(400, "Coordenadas fuera de rango.")

        contenido = foto.file.read(MAX_BYTES + 1)
        if len(contenido) > MAX_BYTES:
            raise HTTPException(400, "La imagen supera el máximo de 10 MB.")
        tipo = filetype.guess(contenido)  # tipo real por magic bytes, no por extensión
        if tipo is None or tipo.mime not in ALLOWED_MIME_TYPES:
            raise HTTPException(400, "El archivo no es una imagen válida (JPEG, PNG o WEBP).")

        colores = procesar_colores_funcional(color_principal, colores_adicionales or "")

        # 3. Guardar foto y registrar en una sola transacción
        nombre_archivo = f"{uuid.uuid4()}.{tipo.extension}"
        ruta_destino = STORAGE_DIR / nombre_archivo
        ruta_destino.write_bytes(contenido)
        try:
            cur = conn.execute(
                """INSERT INTO perritos (clave_idempotencia, nombre, id_raza, color_principal,
                                         latitud, longitud, foto)
                   VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (clave, nombre, id_raza, color_principal, latitud, longitud, nombre_archivo),
            )
            nuevo_id = cur.lastrowid
            conn.executemany(
                "INSERT INTO perrito_colores (id_perrito, id_color) VALUES (?, ?)",
                [(nuevo_id, c) for c in colores[1:]],
            )
            conn.commit()
        except sqlite3.IntegrityError:
            conn.rollback()
            ruta_destino.unlink(missing_ok=True)
            previo = _buscar_por_clave(conn, clave)  # doble clic simultáneo
            if previo:
                return JSONResponse(status_code=200,
                                    content=_respuesta(previo, "Perrito previamente registrado (idempotencia)"))
            raise HTTPException(400, "La raza o el color seleccionado no existe.")

        return _respuesta({"id_perrito": nuevo_id, "foto": nombre_archivo},
                          "Perrito registrado exitosamente")
    finally:
        conn.close()


@app.get("/api/fotos/{ruta:path}")
def obtener_foto(ruta: str):
    base = STORAGE_DIR.resolve()
    archivo = (base / ruta).resolve()
    if base not in archivo.parents or not archivo.is_file():  # evita ../ (path traversal)
        raise HTTPException(404, "Imagen no encontrada")
    return FileResponse(archivo)


# ---------- Frontend (mismo origen => funciona igual en local y con Cloudflare) ----------
@app.get("/", include_in_schema=False)
def raiz():
    return RedirectResponse("/base.html")


if FRONTEND_DIR.exists():
    app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="frontend")
