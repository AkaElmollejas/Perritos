// P2 · Funcionalidad 4 (pantalla): zonas de concentración.
// Elixir divide la ciudad en celdas y cuenta perros (GET /f/zonas); aquí solo se pintan
// los rectángulos (más rojo = más perros). Puedes filtrar por color y, con tu ubicación,
// saber qué tan lejos queda la zona más concentrada y la zona más cercana.

const tamZonaSelect = document.getElementById("tamZona");
const zonaColor = document.getElementById("zonaColor");
const resumenZonas = document.getElementById("resumenZonas");
let mapaZonas;
let capaZonas;

async function cargarZonas() {
    resumenZonas.textContent = "Cargando zonas...";
    const params = new URLSearchParams({ tam: tamZonaSelect.value });
    if (zonaColor.value) params.set("colores", zonaColor.value);
    if (ubicacionUsuario) {
        params.set("lat", ubicacionUsuario.lat);
        params.set("lon", ubicacionUsuario.lon);
    }
    try {
        const res = await fetch(`${F_BASE_URL}/zonas?${params}`);
        if (!res.ok) throw new Error("respuesta " + res.status);
        pintarZonas(await res.json());
    } catch (e) {
        console.error(e);
        resumenZonas.textContent = "No se pudieron cargar las zonas (¿está encendido el servicio?).";
    }
}

function pintarZonas(datos) {
    if (!mapaZonas) {
        mapaZonas = L.map("mapaZonas").setView(defaultLocation, 12);
        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", { attribution: "© OpenStreetMap" }).addTo(mapaZonas);
        capaZonas = L.layerGroup().addTo(mapaZonas);
    }
    capaZonas.clearLayers();

    const maximo = Math.max(...datos.zonas.map(z => z.total), 1);
    datos.zonas.forEach(z => {
        const esLaMasConcentrada = datos.mas_concentrada && z.fila === datos.mas_concentrada.fila && z.columna === datos.mas_concentrada.columna;
        L.rectangle([[z.sur, z.oeste], [z.norte, z.este]], {
            color: esLaMasConcentrada ? "#000" : "#c0392b",
            weight: esLaMasConcentrada ? 3 : 1,
            fillOpacity: 0.15 + 0.6 * (z.total / maximo)
        }).bindTooltip(String(z.total), { permanent: true, direction: "center", className: "etiqueta-zona" })
          .addTo(capaZonas);
    });

    const puntos = datos.zonas.map(z => [[z.sur, z.oeste], [z.norte, z.este]]);
    if (ubicacionUsuario) {
        L.circleMarker([ubicacionUsuario.lat, ubicacionUsuario.lon], { radius: 8, color: "#1e89e0", fillOpacity: 0.9 })
            .bindTooltip("Tú", { permanent: true, direction: "top" }).addTo(capaZonas);
        puntos.push([[ubicacionUsuario.lat, ubicacionUsuario.lon], [ubicacionUsuario.lat, ubicacionUsuario.lon]]);
    }
    resumenZonas.textContent = textoResumenZonas(datos);
    mapaZonas.invalidateSize();
    if (puntos.length > 0) mapaZonas.fitBounds(puntos, { padding: [20, 20] });
}

function textoResumenZonas(datos) {
    if (datos.zonas.length === 0) return "No hay avistamientos con ese filtro.";
    const mayor = datos.mas_concentrada;
    let texto = `${datos.zonas.length} zonas de ${datos.tam_m} m. La más concentrada (borde negro) tiene ${mayor.total} perros.`;
    if (datos.mas_cercana) {
        texto += ` Está a ${formatearDistancia(mayor.distancia_m)} de ti;`
              + ` la zona con perros más cercana (${datos.mas_cercana.total}) está a ${formatearDistancia(datos.mas_cercana.distancia_m)}.`;
    }
    return texto;
}

document.getElementById("zonasDialog").addEventListener("abierto", () => {
    if (zonaColor.options.length <= 1) copiarOpciones(zonaColor, colorPrincipalSelect, o => slug(o.textContent));
    cargarZonas();
});
tamZonaSelect.addEventListener("change", cargarZonas);
zonaColor.addEventListener("change", cargarZonas);
document.getElementById("zonaUbicacion").addEventListener("click", async () => {
    resumenZonas.textContent = "Buscando tu ubicación...";
    try {
        await pedirUbicacionUsuario(true);
    } catch (e) {
        resumenZonas.textContent = "No pude obtener tu ubicación (permiso negado o sin HTTPS).";
        return;
    }
    cargarZonas();
});
