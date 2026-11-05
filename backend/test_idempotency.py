"""Demuestra la idempotencia. Con el servidor encendido:  python test_idempotency.py"""
import struct
import sys
import uuid
import zlib

import requests

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"


def png_minimo():
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    raw = b"\x00\xff\x00\x00"
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def enviar(clave):
    return requests.post(
        f"{BASE}/api/perritos",
        headers={"Idempotency-Key": clave},
        data={"nombre": "Prueba idempotencia", "latitud": 25.44, "longitud": -100.97,
              "color_principal": 1, "colores_adicionales": "2,3"},
        files={"foto": ("t.png", png_minimo(), "image/png")},
    )


total_antes = len(requests.get(f"{BASE}/api/perritos").json())
clave = str(uuid.uuid4())
r1, r2 = enviar(clave), enviar(clave)
total_despues = len(requests.get(f"{BASE}/api/perritos").json())

print("Petición 1:", r1.status_code, r1.json())
print("Petición 2:", r2.status_code, r2.json())
assert (r1.status_code, r2.status_code) == (201, 200), "Se esperaba 201 y luego 200"
assert r1.json()["id_perrito"] == r2.json()["id_perrito"], "Los IDs deben ser iguales"
assert total_despues == total_antes + 1, "No debe duplicarse la fila"
print("OK: misma clave => mismo ID, una sola fila nueva.")
