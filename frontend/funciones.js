// Ruta relativa: el frontend lo sirve el mismo FastAPI, así funciona igual en
// localhost, en la red local y a través de Cloudflare Tunnel (HTTPS).
const API_BASE_URL = window.PERRITOS_API_BASE_URL || "/api";
const ORIGEN_API = API_BASE_URL.startsWith("http") ? new URL(API_BASE_URL).origin : "";
const defaultLocation = [25.438, -100.973];

const registrationForm = document.getElementById("miFormulario");
const dogList = document.getElementById("listaPerritos");
const mapContainer = document.getElementById("mapContainer");
const mapToggle = document.getElementById("toggleMapa");
const latitudeInput = document.getElementById("latitud");
const longitudeInput = document.getElementById("longitud");
const locationText = document.getElementById("ubicacion");
const razaSelect = document.getElementById("raza");
const colorPrincipalSelect = document.getElementById("colorPrincipal");
const coloresFieldset = document.getElementById("coloresAdicionales");
const fotoInput = document.getElementById("foto");
const submitButton = document.getElementById("btnSubmit");
const submitStatus = document.getElementById("estadoEnvio");

// 1. Clave de idempotencia: se genera al cargar y solo se renueva tras un registro exitoso.
//    Si el usuario da doble clic o la red reintenta, se reenvía LA MISMA clave.
function generarUUID() {
    if (window.crypto && crypto.randomUUID) return crypto.randomUUID();
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, c => {
        const r = Math.random() * 16 | 0;
        return (c === "x" ? r : (r & 0x3 | 0x8)).toString(16);
    });
}
let currentIdempotencyKey = generarUUID();

// 2. Catálogos desde la API
const getChecks = () => Array.from(coloresFieldset.querySelectorAll("input[type='checkbox']"));

async function cargarCatalogos() {
    try {
        const [resR, resC] = await Promise.all([
            fetch(`${API_BASE_URL}/catalogos/razas`),
            fetch(`${API_BASE_URL}/catalogos/colores`)
        ]);
        if (!resR.ok || !resC.ok) throw new Error("catálogos no disponibles");
        const razas = await resR.json();
        const colores = await resC.json();

        razas.forEach(r => razaSelect.append(new Option(r.nombre, r.id)));
        colores.forEach(c => {
            colorPrincipalSelect.append(new Option(c.nombre, c.id));
            const label = document.createElement("label");
            const chk = document.createElement("input");
            chk.type = "checkbox";
            chk.name = "colores";
            chk.value = c.id;
            label.append(chk, c.nombre);
            coloresFieldset.append(label);
        });
        actualizarReglasColores();
    } catch (e) {
        console.error(e);
        submitStatus.textContent = "No se pudieron cargar razas y colores. Recargue la página.";
        submitStatus.style.color = "red";
    }
}

function actualizarReglasColores() {
    const principal = colorPrincipalSelect.value;
    const checks = getChecks();
    checks.forEach(chk => {
        if (chk.value === principal) chk.checked = false;
        chk.disabled = chk.value === principal;
    });
    if (checks.filter(c => c.checked).length >= 2) {
        checks.forEach(chk => { if (!chk.checked) chk.disabled = true; });
    }
}
colorPrincipalSelect.addEventListener("change", actualizarReglasColores);
coloresFieldset.addEventListener("change", actualizarReglasColores);

// 3. Ubicación
let map, marker, mapaGlobal;
let marcadoresGlobales = [];

function setLocation(latitude, longitude) {
    latitudeInput.value = latitude;
    longitudeInput.value = longitude;
    locationText.textContent = `Latitud: ${Number(latitude).toFixed(6)}, Longitud: ${Number(longitude).toFixed(6)}`;
    if (marker) marker.setLatLng([latitude, longitude]);
    if (map) map.setView([latitude, longitude], 15);
}

function limpiarUbicacion() {
    latitudeInput.value = "";
    longitudeInput.value = "";
    locationText.textContent = "Aún no has elegido una ubicación.";
}
limpiarUbicacion();

function toggleMapa() {
    const showMap = mapContainer.hidden;
    mapContainer.hidden = !showMap;
    mapToggle.setAttribute("aria-expanded", String(showMap));
    mapToggle.textContent = showMap ? "Ocultar mapa" : "Mostrar mapa para elegir ubicación";
    if (!showMap) return;

    if (!map) {
        const lat = Number(latitudeInput.value) || defaultLocation[0];
        const lng = Number(longitudeInput.value) || defaultLocation[1];
        map = L.map("map").setView([lat, lng], 14);
        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
            attribution: "© OpenStreetMap"
        }).addTo(map);
        marker = L.marker([lat, lng], { draggable: true }).addTo(map);
        marker.on("dragend", () => { const c = marker.getLatLng(); setLocation(c.lat, c.lng); });
        map.on("click", e => setLocation(e.latlng.lat, e.latlng.lng));
        if (!latitudeInput.value) locationText.textContent = "Toca el mapa o arrastra el pin para elegir la ubicación.";
    }
    setTimeout(() => map.invalidateSize(), 200);
}
mapToggle.addEventListener("click", toggleMapa);

function obtenerUbicacion() {
    if (!navigator.geolocation) {
        alert("La geolocalización no está soportada en este navegador.");
        return;
    }
    locationText.textContent = "Obteniendo ubicación del GPS...";
    navigator.geolocation.getCurrentPosition(
        pos => setLocation(pos.coords.latitude, pos.coords.longitude),
        err => {
            alert("No se pudo obtener la ubicación: " + err.message);
            locationText.textContent = latitudeInput.value ? locationText.textContent : "Error al obtener GPS.";
        },
        { enableHighAccuracy: true, timeout: 15000 }
    );
}
document.getElementById("usarUbicacion").addEventListener("click", obtenerUbicacion);

// 4. Foto seleccionada
fotoInput.addEventListener("change", e => {
    const archivo = e.target.files[0];
    document.getElementById("nombreArchivoFoto").textContent = archivo ? `Archivo seleccionado: ${archivo.name}` : "";
});

// 5. Diálogos
document.querySelectorAll("[data-open-dialog]").forEach(button => {
    button.addEventListener("click", async () => {
        const dialog = document.getElementById(button.dataset.openDialog);
        dialog.showModal();
        if (dialog.id === "perritosDialog") {
            await cargarPerritosEnMapa();
            if (mapaGlobal) mapaGlobal.invalidateSize();
        }
    });
});
document.querySelectorAll("[data-close-dialog]").forEach(button => {
    button.addEventListener("click", () => button.closest("dialog").close());
});

// 6. Envío del formulario
registrationForm.addEventListener("submit", async event => {
    event.preventDefault();
    const nombre = document.getElementById("nombre").value.trim();
    const foto = fotoInput.files[0];
    const colorPrincipal = colorPrincipalSelect.value;
    const adicionales = getChecks().filter(c => c.checked).map(c => c.value);

    if (!nombre) return alert("Es necesario añadir un nombre.");
    if (!foto) return alert("Falta subir la foto.");
    if (!["image/jpeg", "image/png", "image/webp"].includes(foto.type))
        return alert("FORMATO DE IMAGEN NO VÁLIDO. Use JPG, PNG o WEBP.");
    if (!colorPrincipal) return alert("Es necesario elegir un color principal.");
    if (adicionales.length > 2) return alert("Seleccione máximo dos colores adicionales.");
    if (!latitudeInput.value || !longitudeInput.value)
        return alert("Debe elegir una ubicación (GPS o mapa).");

    const formData = new FormData();
    formData.append("nombre", nombre);
    formData.append("color_principal", colorPrincipal);
    formData.append("colores_adicionales", adicionales.join(","));
    formData.append("latitud", latitudeInput.value);
    formData.append("longitud", longitudeInput.value);
    formData.append("foto", foto);
    if (razaSelect.value) formData.append("id_raza", razaSelect.value);

    submitButton.disabled = true;
    submitStatus.textContent = "Registrando perrito en el servidor...";
    submitStatus.style.color = "#1e89e0";

    try {
        const respuesta = await fetch(`${API_BASE_URL}/perritos`, {
            method: "POST",
            headers: { "Idempotency-Key": currentIdempotencyKey },
            body: formData
        });
        const resultado = await respuesta.json().catch(() => ({}));

        if (respuesta.ok) {   // 201 = nuevo, 200 = ya estaba registrado (idempotencia)
            submitStatus.textContent = respuesta.status === 200
                ? `Este perrito ya estaba registrado. Folio: ${resultado.id_perrito}`
                : `Registro exitoso. Folio: ${resultado.id_perrito}`;
            submitStatus.style.color = "green";
            currentIdempotencyKey = generarUUID();   // nueva clave solo tras éxito
            registrationForm.reset();
            document.getElementById("nombreArchivoFoto").textContent = "";
            limpiarUbicacion();
            actualizarReglasColores();
            if (document.getElementById("perritosDialog").open) {
                await cargarPerritosEnMapa();
                if (mapaGlobal) mapaGlobal.invalidateSize();
            }
        } else {
            const detalle = Array.isArray(resultado.detail)
                ? resultado.detail.map(d => d.msg).join("; ") : resultado.detail;
            submitStatus.textContent = `Error: ${detalle || "No se pudo registrar"}`;
            submitStatus.style.color = "red";
        }
    } catch (err) {
        submitStatus.textContent = "Error al conectar con el servidor. Verifique su conexión y reintente.";
        submitStatus.style.color = "red";
    } finally {
        submitButton.disabled = false;
    }
});

// 7. Mapa general y tarjetas
async function cargarPerritosEnMapa() {
    try {
        const res = await fetch(`${API_BASE_URL}/perritos`);
        if (!res.ok) { dogList.textContent = "No fue posible cargar los registros."; return; }
        const perritos = await res.json();

        if (!mapaGlobal) {
            mapaGlobal = L.map("mapaGeneral").setView(defaultLocation, 12);
            L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
                attribution: "© OpenStreetMap"
            }).addTo(mapaGlobal);
        }
        marcadoresGlobales.forEach(m => mapaGlobal.removeLayer(m));
        marcadoresGlobales = [];
        dogList.replaceChildren();

        if (perritos.length === 0) {
            dogList.textContent = "Todavía no hay perritos registrados.";
            return;
        }

        perritos.forEach(p => {
            const urlFoto = ORIGEN_API + p.foto_url;
            const pin = L.marker([p.latitud, p.longitud]).addTo(mapaGlobal);
            const popup = document.createElement("div");
            const popupName = document.createElement("strong");
            popupName.textContent = p.nombre;
            const popupDetails = document.createElement("p");
            popupDetails.textContent = `Raza: ${p.raza} | Color: ${p.color_principal}`;
            popup.append(popupName, popupDetails);
            pin.bindPopup(popup);
            marcadoresGlobales.push(pin);

            const tarjeta = document.createElement("article");
            tarjeta.className = "tarjeta-perro";
            const image = document.createElement("img");
            image.src = urlFoto;
            image.alt = `Foto de ${p.nombre}`;
            image.className = "mini-foto";
            image.loading = "lazy";
            const info = document.createElement("div");
            info.className = "info-perro";
            const name = document.createElement("h3");
            name.textContent = p.nombre;
            const breed = document.createElement("p");
            breed.textContent = `Raza: ${p.raza}`;
            const colors = document.createElement("p");
            colors.textContent = `Colores: ${[p.color_principal, p.colores_adicionales].filter(Boolean).join(", ")}`;
            info.append(name, breed, colors);
            tarjeta.append(image, info);
            dogList.append(tarjeta);
        });

        mapaGlobal.fitBounds(perritos.map(p => [p.latitud, p.longitud]), { padding: [30, 30], maxZoom: 15 });
    } catch (e) {
        console.error("No se pudieron cargar los registros:", e);
        dogList.textContent = "Error al conectar con el servidor.";
    }
}

cargarCatalogos();
