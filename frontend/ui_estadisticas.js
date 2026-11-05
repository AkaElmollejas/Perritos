// P2 · Funcionalidad 3 (pantalla): estadísticas con gráficas de barras.
// Los conteos los calcula Elixir (GET /f/estadisticas); aquí solo se dibujan barras con HTML/CSS.

const contenidoEstadisticas = document.getElementById("contenidoEstadisticas");
const nombresColor = { cafe: "café", marron: "marrón" };

function crearElemento(etiqueta, clase, texto) {
    const el = document.createElement(etiqueta);
    if (clase) el.className = clase;
    if (texto !== undefined) el.textContent = texto;
    return el;
}

// Un bloque con una barra horizontal por fila: [{clave, total}]
function bloqueBarras(titulo, filas, alTocar) {
    const bloque = crearElemento("section", "bloque-grafica");
    bloque.append(crearElemento("h3", "", titulo));
    const maximo = Math.max(...filas.map(f => f.total), 1);
    filas.forEach(f => {
        const fila = crearElemento("div", "barra-fila");
        const relleno = crearElemento("div", "barra-relleno");
        relleno.style.width = `${(f.total / maximo) * 100}%`;
        const pista = crearElemento("div", "barra-pista");
        pista.append(relleno);
        fila.append(crearElemento("span", "barra-etiqueta", nombresColor[f.clave] || f.clave),
                    pista, crearElemento("span", "barra-total", f.total));
        if (alTocar) {   // fila tocable: abre la búsqueda con ese color
            fila.classList.add("clicable");
            fila.title = "Ver dónde están";
            fila.addEventListener("click", () => alTocar(f.clave));
        }
        bloque.append(fila);
    });
    return bloque;
}

// Una barra vertical por día: [{dia, total}]
function bloqueSerie(serie) {
    const bloque = crearElemento("section", "bloque-grafica");
    bloque.append(crearElemento("h3", "", "Avistamientos por día"));
    const maximo = Math.max(...serie.map(d => d.total), 1);
    const contenedor = crearElemento("div", "serie");
    serie.forEach(d => {
        const barra = crearElemento("div", "serie-barra");
        barra.style.height = `${(d.total / maximo) * 100}%`;
        barra.title = `${d.dia}: ${d.total}`;
        contenedor.append(barra);
    });
    bloque.append(contenedor);
    if (serie.length > 0) {
        bloque.append(crearElemento("p", "serie-rango", `${serie[0].dia}  →  ${serie[serie.length - 1].dia}`));
    }
    return bloque;
}

async function cargarEstadisticas() {
    contenidoEstadisticas.textContent = "Cargando estadísticas...";
    try {
        const res = await fetch(`${F_BASE_URL}/estadisticas?n=5`);
        if (!res.ok) throw new Error("respuesta " + res.status);
        const datos = await res.json();
        const mas = datos.por_color[0];
        const resumen = mas
            ? `Total de avistamientos: ${datos.total}. El color más registrado es ${nombresColor[mas.clave] || mas.clave} (${mas.total}).`
            : "Todavía no hay avistamientos.";
        contenidoEstadisticas.replaceChildren(
            crearElemento("p", "", resumen),
            crearElemento("p", "ayuda", "Toca un color para ver dónde están y qué tan cerca te quedan."),
            bloqueBarras("Colores más comunes", datos.por_color, color => window.abrirBusqueda && window.abrirBusqueda(color)),
            bloqueBarras("Razas más comunes", datos.por_raza),
            bloqueSerie(datos.por_dia)
        );
    } catch (e) {
        console.error(e);
        contenidoEstadisticas.textContent = "No se pudieron cargar las estadísticas (¿está encendido el servicio?).";
    }
}

document.getElementById("estadisticasDialog").addEventListener("abierto", cargarEstadisticas);
