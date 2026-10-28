"""Conexión a SQLite (incluido en Python, no requiere instalar nada)."""
import os
import shutil
import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SQL_DIR = BASE_DIR / "database"
DB_PATH = Path(os.getenv("DB_PATH", SQL_DIR / "perritos.db"))
# Fotos FUERA del proyecto (regla del curso). Por defecto: ~/PerritosStorage/media
# En Docker se define RUTA_IMAGENES=/data/media (un volumen).
STORAGE_DIR = Path(os.getenv("RUTA_IMAGENES", Path.home() / "PerritosStorage" / "media"))
FOTOS_PRUEBA = SQL_DIR / "fotos_prueba"


def get_db_connection():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")  # SQLite no valida FK por defecto
    return conn


def copiar_fotos_prueba():
    """Copia las fotos de los perritos de prueba a la carpeta externa (sin pisar las existentes)."""
    destino = STORAGE_DIR / "pruebas"
    destino.mkdir(parents=True, exist_ok=True)
    if FOTOS_PRUEBA.is_dir():
        for foto in FOTOS_PRUEBA.iterdir():
            if foto.is_file() and not (destino / foto.name).exists():
                shutil.copy2(foto, destino / foto.name)


def _ejecutar_script(conn, nombre):
    conn.executescript((SQL_DIR / nombre).read_text(encoding="utf-8"))


def init_db():
    """Crea tablas, catálogos y (solo si la BD está vacía) los 105 avistamientos de prueba."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = get_db_connection()
    try:
        _ejecutar_script(conn, "01_schema.sql")
        _ejecutar_script(conn, "02_catalogos.sql")
        if conn.execute("SELECT COUNT(*) FROM perritos").fetchone()[0] == 0:
            _ejecutar_script(conn, "03_datos_prueba.sql")      # 15 perritos del P1
            _ejecutar_script(conn, "06_avistamientos_p2.sql")  # +90 para el P2 (total 105)
        conn.commit()
    finally:
        conn.close()
