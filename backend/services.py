from functools import reduce


def procesar_colores_funcional(color_principal: int, adicionales_str: str = "") -> list:
    """
    Recibe el color principal y el texto "2,3,..." de adicionales.
    Normaliza, descarta vacíos/no numéricos, evita duplicados y limita a 3 colores
    en total. Solo usa map, filter y reduce (sin bucles ni mutación).
    """
    tokens = filter(str.isdigit, map(str.strip, (adicionales_str or "").split(",")))
    adicionales = map(int, tokens)
    return reduce(
        lambda acc, x: acc if x in acc or len(acc) >= 3 else acc + [x],
        adicionales,
        [color_principal],
    )
