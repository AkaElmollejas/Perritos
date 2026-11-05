"""Respaldo/restauración de la BD en SQL de texto (sin herramientas externas).
   python respaldo.py respaldar   -> database/respaldo_perritos.sql
   python respaldo.py restaurar   -> recrea perritos.db desde ese archivo
"""
import sys
import sqlite3
from database import DB_PATH, SQL_DIR

ARCHIVO = SQL_DIR / "respaldo_perritos.sql"

if len(sys.argv) != 2 or sys.argv[1] not in ("respaldar", "restaurar"):
    sys.exit(__doc__)

if sys.argv[1] == "respaldar":
    conn = sqlite3.connect(DB_PATH)
    ARCHIVO.write_text("\n".join(conn.iterdump()) + "\n", encoding="utf-8")
    conn.close()
    print(f"Respaldo creado: {ARCHIVO}")
else:
    if DB_PATH.exists():
        DB_PATH.replace(DB_PATH.with_suffix(".bak"))
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(ARCHIVO.read_text(encoding="utf-8"))
    conn.close()
    print(f"Base restaurada en: {DB_PATH}")
