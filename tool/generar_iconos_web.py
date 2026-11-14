"""Genera los iconos de la versión web (PWA): cruz patada roja sobre fondo crema, como en la portada.

Uso: py tool/generar_iconos_web.py   (necesita PyMuPDF: pip install pymupdf)
"""
from pathlib import Path

import fitz

WEB = Path(__file__).resolve().parent.parent / "web"
CREMA = (0xFD / 255, 0xFB / 255, 0xF7 / 255)
ROJO = (0xC0 / 255, 0, 0)


def icono(lado, escala):
    """Cruz patada centrada; `escala` es la fracción del lado que ocupa (menor en los maskable)."""
    doc = fitz.open()
    pagina = doc.new_page(width=lado, height=lado)
    pagina.draw_rect(pagina.rect, color=None, fill=CREMA)
    c = lado / 2
    largo = lado * escala / 2          # del centro al extremo de cada brazo
    estrecho = largo * 0.11            # medio ancho del brazo junto al centro
    ancho = largo * 0.44               # medio ancho del brazo en el extremo
    forma = pagina.new_shape()
    for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        px, py = -dy, dx  # perpendicular
        puntos = [
            (c + px * estrecho, c + py * estrecho),
            (c + dx * largo + px * ancho, c + dy * largo + py * ancho),
            (c + dx * largo * 0.9, c + dy * largo * 0.9),  # muesca suave en el extremo
            (c + dx * largo - px * ancho, c + dy * largo - py * ancho),
            (c - px * estrecho, c - py * estrecho),
        ]
        forma.draw_polyline([fitz.Point(*p) for p in puntos] + [fitz.Point(*puntos[0])])
    forma.draw_circle(fitz.Point(c, c), estrecho * 1.05)
    forma.finish(color=None, fill=ROJO, closePath=True)
    forma.commit()
    return pagina.get_pixmap(alpha=False)


def main():
    salidas = {
        WEB / "icons" / "Icon-192.png": (192, 0.78),
        WEB / "icons" / "Icon-512.png": (512, 0.78),
        WEB / "icons" / "Icon-maskable-192.png": (192, 0.56),
        WEB / "icons" / "Icon-maskable-512.png": (512, 0.56),
        WEB / "favicon.png": (64, 0.86),
    }
    for ruta, (lado, escala) in salidas.items():
        icono(lado, escala).save(ruta)
        print("Generado", ruta.relative_to(WEB.parent))


if __name__ == "__main__":
    main()
