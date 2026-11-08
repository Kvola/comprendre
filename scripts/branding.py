#!/usr/bin/env python3
"""Identité visuelle de Comprendre : une seule source pour tous les visuels.

    python3 scripts/branding.py

Le symbole : une page de texte dont un passage est surligné, éclairée par une
idée (soleil ambre) qui porte une coche — lire, comprendre, vérifier. Bleu-vert profond (réflexion,
calme) et ambre (l'idée qui s'allume), les couleurs de l'application.

Produit (SVG puis PNG, via scripts/svg2png.swift) :
  assets/branding/icon-full.png        icône complète (fond plein) — lanceur, iOS
  assets/branding/icon-foreground.png  premier plan de l'icône adaptative Android (zone sûre)
  assets/branding/splash.png           écran de lancement Android 12+
  assets/branding/logo.png / logo-en.png        logo horizontal (symbole + nom), fond transparent
  assets/branding/logo-stacked.png / -en.png    logo vertical
  ../comprendre_backend/static/description/icon.png   icône du module Odoo (256 px)
"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'branding'
MODULE_ICON = ROOT.parent / 'comprendre_backend' / 'static' / 'description' / 'icon.png'

TEAL = '#0E5E6F'
TEAL_DARK = '#0A4552'
AMBER = '#F2A541'
PAGE_RIGHT = '#E3F1F4'
INK = '#16323A'

# Symbole dessiné dans un carré de 1024 : une page de texte dont un passage est
# surligné (ce que fait l'application : chaque réponse renvoie au passage qui la
# justifie), éclairée par l'idée qui porte la coche. Volontairement SANS livre
# ouvert, pour ne pas ressembler à l'icône du Quiz Biblique.
MARK = f'''
  <g>
    <!-- La page -->
    <rect x="212" y="236" width="470" height="600" rx="48" fill="#FFFFFF"/>
    <!-- Le passage surligné -->
    <rect x="258" y="550" width="372" height="96" rx="22" fill="#F8C77A"/>
    <!-- Lignes de texte -->
    <g stroke="{TEAL}" stroke-width="30" stroke-linecap="round">
      <path d="M290 382 H 470" opacity="0.45"/>
      <path d="M290 466 H 590" opacity="0.45"/>
      <path d="M298 598 H 560"/>
      <path d="M290 730 H 520" opacity="0.45"/>
    </g>
    <!-- Rayons de l'idée -->
    <g stroke="{AMBER}" stroke-width="34" stroke-linecap="round">
      <path d="M690 108 L690 150"/>
      <path d="M842 170 L812 200"/>
      <path d="M906 318 L864 318"/>
    </g>
    <!-- L'idée, qui porte la coche (cerclée de la couleur du fond pour se détacher de la page) -->
    <circle cx="690" cy="318" r="140" fill="{AMBER}" stroke="{TEAL}" stroke-width="28"/>
    <path d="M626 322 L672 368 L758 278" fill="none" stroke="{TEAL}" stroke-width="42"
          stroke-linecap="round" stroke-linejoin="round"/>
  </g>'''


def mark_at(scale, cx=512, cy=512):
    """Le symbole réduit à [scale], centré sur (cx, cy). Le dessin occupe x = 212…906,
    y = 108…836 : son centre est (559, 472)."""
    return f'<g transform="translate({cx} {cy}) scale({scale}) translate(-559 -472)">{MARK}</g>'


def square(bg, scale, radius=0):
    rect = f'<rect width="1024" height="1024" rx="{radius}" fill="{bg}"/>' if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">'
            f'{rect}{mark_at(scale)}</svg>')


def logo(name, tagline, stacked=False):
    tile = f'<rect x="0" y="0" width="400" height="400" rx="92" fill="{TEAL}"/>{mark_at(0.36, 200, 200)}'
    font = "font-family=\"Avenir Next, Helvetica Neue, Helvetica, Arial\""
    # Avenir Next : « 600/700 » donne la graisse Bold (trop lourde), « 500 » la Medium.
    bold = "font-family=\"Avenir Next, Helvetica Neue, Arial\" font-weight=\"500\""
    if stacked:
        w, h = 1000, 760
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
                f'<g transform="translate(300 0)">{tile}</g>'
                f'<text x="500" y="560" {bold} font-size="128" fill="{INK}" text-anchor="middle">{name}</text>'
                f'<text x="500" y="650" {font} font-size="46" fill="{TEAL}" text-anchor="middle">{tagline}</text></svg>')
    w, h = 1600, 400
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{tile}'
            f'<text x="460" y="232" {bold} font-size="150" fill="{INK}">{name}</text>'
            f'<text x="466" y="318" {font} font-size="50" fill="{TEAL}">{tagline}</text></svg>')


def render(svg, png, width):
    src = png.with_suffix('.svg')
    src.write_text(svg, encoding='utf-8')
    subprocess.run(['swift', str(ROOT / 'scripts' / 'svg2png.swift'), str(src), str(png), str(width)], check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    render(square(TEAL, 0.86), OUT / 'icon-full.png', 1024)
    # Icône adaptative Android : seul le disque central (≈ 66 %) est toujours visible.
    render(square(None, 0.72), OUT / 'icon-foreground.png', 1024)
    render(square(TEAL, 0.62), OUT / 'splash.png', 1024)
    render(logo('Comprendre', 'Un quiz pour comprendre tout texte'), OUT / 'logo.png', 1600)
    render(logo('Understand', 'A quiz to understand any text'), OUT / 'logo-en.png', 1600)
    render(logo('Comprendre', 'Un quiz pour comprendre tout texte', stacked=True), OUT / 'logo-stacked.png', 1000)
    render(logo('Understand', 'A quiz to understand any text', stacked=True), OUT / 'logo-stacked-en.png', 1000)
    # Module Odoo : fond plein (Odoo arrondit lui-même), 256 px comme les autres modules Kvola.
    MODULE_ICON.parent.mkdir(parents=True, exist_ok=True)
    render(square(TEAL, 0.86), MODULE_ICON, 256)
    MODULE_ICON.with_suffix('.svg').unlink()  # le module ne garde que le PNG
    print('Visuels écrits dans', OUT, 'et', MODULE_ICON)


if __name__ == '__main__':
    main()
