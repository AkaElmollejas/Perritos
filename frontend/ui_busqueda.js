// P2 · Funcionalidad 1 (pantalla): buscar perritos cerca de mí, combinando filtros.
// Color + raza + distancia + tu ubicación. Cada vez que cambias un filtro se vuelve a
// buscar. El filtrado y el orden por cercanía los hace Elixir (GET /f/busqueda).

const dialogoBusqueda = document.getElementById("busquedaDialog");
const busqColor = document.getElementById("busqColor");
const busqRaza = document.getElementById("busqRaza");
const busqRadio = document.getElementById("busqRadio");
const busqEstado = document.getElementById("busqEstado");
const busqResumen = document.getElementById("busqResumen");
const busqLista = document.getElementById("busqLista");
let mapaBusqueda;
let capaBusqueda;
let yaPidioUbicacion = false;
let colorPendiente = null;   // lo deja Estadísticas al tocar una barra de color

function llenarFiltros() {
    if (busqColor.options.length > 1) return;   // ya están llenos
    copiarOpciones(busqColor, colorPrincipalSelect, o => slug(o.textContent));
    copiarOpciones(busqRaza, razaSelect, o => o.textContent, o => o.textContent.startsWith("Sin raza"));
}

async function usarMiUbicacion(forzar) {
    busqEstado.textContent = "Buscando tu ubicación...";
    try {
        await pedirUbicacionUsuario(forzar);
        busqEstado.textContent = "Usando tu ubicación: los resultados van del más cercano al más lejano.";
    } catch (e) {
        busqEstado.textContent = "No pude obtener tu ubicación (permiso negado o sin HTTPS): se muestran sin distancia.";
    }
}

async function buscar() {
    const params = new URLSearchParams();
    if (busqColor.value) params.set("colores", busqColor.value);
    if (busqRaza.value) params.set("raza", busqRaza.value);
    if (ubicacionUsuario) {
        params.set("lat", ubicacionUsuario.lat);
        params.set("lon", ubicacionUsuario.lon);
        if (busqRadio.value !== "0") params.set("radio", busqRadio.value);
    }
    busqResumen.textContent = "Buscando...";
    try {
        const res = await fetch(`${F_BASE_URL}/busqueda?${params}`);
        if (!res.ok) throw new Error("respuesta " + res.status);
        pintarResultados(await res.json());
    } catch (e) {
        console.error(e);
        busqResumen.textContent = "No se pudo buscar (¿está encendido el servicio?).";
    }
}

function textoResumen(datos) {
    const color = busqColor.value ? ` de color ${busqColor.selectedOptions[0].textContent.toLowerCase()}` : "";
    if (datos.total === 0) return `No hay perritos${color} con esos filtros.`;
    let texto = `${datos.total} perrito(s)${color}.`;
    const primero = datos.resultados[0];
    if (ubicacionUsuario && primero.distancia_m !== null) {
        texto += ` El más cercano es ${primero.nombre}, a ${formatearDistancia(primero.distancia_m)} de ti.`;
    }
    return texto;
}

function pintarResultados(datos) {
    busqResumen.textContent = textoResumen(datos);

    if (!mapaBusqueda) {
        mapaBusqueda = L.map("mapaBusqueda").setView(defaultLocation, 12);
        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", { attribution: "© OpenStreetMap" }).addTo(mapaBusqueda);
        capaBusqueda = L.layerGroup().addTo(mapaBusqueda);
    }
    capaBusqueda.clearLayers();
    busqLista.replaceChildren();
    const puntos = [];

    datos.resultados.forEach(r => {
        puntos.push([r.lat, r.lon]);
        const distancia = formatearDistancia(r.distancia_m);
        const detalle = `${r.colores.join(", ")}${distancia ? " · a " + distancia : ""}`;

        const popup = document.createElement("div");
        const nombre = document.createElement("strong");
        nombre.textContent = r.nombre;
        const info = document.createElement("p");
        info.textContent = detalle;
        popup.append(nombre, info);
        L.marker([r.lat, r.lon]).bindPopup(popup).addTo(capaBusqueda);

        const tarjeta = document.createElement("article");
        tarjeta.className = "tarjeta-perro";
        const foto = document.createElement("img");
        foto.className = "mini-foto";
        foto.src = ORIGEN_API + r.foto;
        foto.alt = `Foto de ${r.nombre}`;
        foto.loading = "lazy";
        const cuerpo = document.createElement("div");
        cuerpo.className = "info-perro";
        const titulo = document.createElement("h3");
        titulo.textContent = r.nombre;
        const linea1 = document.createElement("p");
        linea1.textContent = `Colores: ${r.colores.join(", ")}`;
        const linea2 = document.createElement("p");
        linea2.textContent = distancia ? `A ${distancia} de ti` : `Raza: ${r.raza || "desconocida"}`;
        cuerpo.append(titulo, linea1, linea2);
        tarjeta.append(foto, cuerpo);
        busqLista.append(tarjeta);
    });

    if (ubicacionUsuario) {   // tú, y el círculo del radio si lo limitaste
        L.circleMarker([ubicacionUsuario.lat, ubicacionUsuario.lon], { radius: 8, color: "#1e89e0", fillOpacity: 0.9 })
            .bindTooltip("Tú", { permanent: true, direction: "top" }).addTo(capaBusqueda);
        if (busqRadio.value !== "0") {
            L.circle([ubicacionUsuario.lat, ubicacionUsuario.lon], { radius: Number(busqRadio.value), color: "#1e89e0", fillOpacity: 0.08 }).addTo(capaBusqueda);
        }
        puntos.push([ubicacionUsuario.lat, ubicacionUsuario.lon]);
    }
    mapaBusqueda.invalidateSize();
    if (puntos.length > 0) mapaBusqueda.fitBounds(puntos, { padding: [30, 30], maxZoom: 15 });
}

dialogoBusqueda.addEventListener("abierto", async () => {
    llenarFiltros();
    if (colorPendiente !== null) {
        busqColor.value = colorPendiente;
        colorPendiente = null;
    }
    if (!yaPidioUbicacion) {          // la primera vez se pide la ubicación sola
        yaPidioUbicacion = true;
        await usarMiUbicacion(false);
    }
    buscar();
});

document.getElementById("busqUbicacion").addEventListener("click", async () => {
    await usarMiUbicacion(true);
    buscar();
});
[busqColor, busqRaza, busqRadio].forEach(filtro => filtro.addEventListener("change", buscar));

// Lo llama Estadísticas: "toca un color para ver dónde están"
window.abrirBusqueda = function (color) {
    colorPendiente = color;
    document.getElementById("estadisticasDialog").close();
    dialogoBusqueda.showModal();
    dialogoBusqueda.dispatchEvent(new CustomEvent("abierto"));
};
