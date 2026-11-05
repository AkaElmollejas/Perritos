-- Esquema SQLite (compatible con el diagrama ER). Se puede ejecutar varias veces.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS razas (
    id_raza INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre  TEXT NOT NULL UNIQUE CHECK (length(trim(nombre)) > 0 AND length(nombre) <= 100),
    activo  INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1))
);

CREATE TABLE IF NOT EXISTS colores (
    id_color INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre   TEXT NOT NULL UNIQUE CHECK (length(trim(nombre)) > 0 AND length(nombre) <= 50),
    activo   INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1))
);

CREATE TABLE IF NOT EXISTS perritos (
    id_perrito      INTEGER PRIMARY KEY AUTOINCREMENT,
    id_raza         INTEGER NULL REFERENCES razas(id_raza) ON UPDATE CASCADE ON DELETE RESTRICT,
    nombre          TEXT NOT NULL CHECK (length(trim(nombre)) > 0 AND length(nombre) <= 100),
    descripcion     TEXT NULL CHECK (descripcion IS NULL OR length(descripcion) <= 500),
    color_principal INTEGER NOT NULL REFERENCES colores(id_color) ON UPDATE CASCADE ON DELETE RESTRICT,
    latitud         REAL NOT NULL CHECK (latitud  BETWEEN -90  AND 90),
    longitud        REAL NOT NULL CHECK (longitud BETWEEN -180 AND 180),
    foto            TEXT NOT NULL,
    fecha_registro  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Idempotencia: la misma clave no puede registrarse dos veces
    clave_idempotencia TEXT NOT NULL UNIQUE CHECK (length(clave_idempotencia) = 36)
);

-- Colores ADICIONALES (máx. 2; el principal vive en perritos.color_principal)
CREATE TABLE IF NOT EXISTS perrito_colores (
    id_perrito INTEGER NOT NULL REFERENCES perritos(id_perrito) ON DELETE CASCADE ON UPDATE CASCADE,
    id_color   INTEGER NOT NULL REFERENCES colores(id_color) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (id_perrito, id_color)
);

CREATE INDEX IF NOT EXISTS idx_perritos_raza            ON perritos(id_raza);
CREATE INDEX IF NOT EXISTS idx_perritos_color_principal ON perritos(color_principal);
CREATE INDEX IF NOT EXISTS idx_perritos_fecha           ON perritos(fecha_registro);
CREATE INDEX IF NOT EXISTS idx_perritos_ubicacion       ON perritos(latitud, longitud);
CREATE INDEX IF NOT EXISTS idx_perrito_colores_color    ON perrito_colores(id_color);
