@echo off
rem Muestra la URL publica del tunel de Cloudflare (ejecutar con "docker compose up" corriendo)
docker compose logs tunel | findstr trycloudflare
