# Respaldo y restauración de la base de datos

La base es un único archivo SQLite (`database/perritos.db`). Se crea sola al iniciar el
backend con `01_schema.sql`, `02_catalogos.sql` y `03_datos_prueba.sql` (15 perritos).

## Respaldo
```
cd backend
python respaldo.py respaldar
```
Genera `database/respaldo_perritos.sql` (estructura + datos, en UTF-8).

## Restauración
```
cd backend
python respaldo.py restaurar
```
Guarda la base actual como `perritos.bak` y la recrea desde el respaldo.

## Verificación
```
python -c "import sqlite3;print(sqlite3.connect('../database/perritos.db').execute('SELECT COUNT(*) FROM perritos').fetchone())"
```
Debe mostrar `(15,)` en una instalación nueva. Para volver al estado inicial basta con borrar
`database/perritos.db` y reiniciar el backend.
