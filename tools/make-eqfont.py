#!/usr/bin/env python3
"""Builds CueEQ-Regular.ttf: a font whose digit glyphs are equalizer-bar
patterns. Rendered through Text(timerInterval:) in a Live Activity, the
seconds digit cycles 0-9 once per second, so the bars dance with zero
content updates (the system re-renders timer text natively).

Usage: python3 tools/make-eqfont.py ios/CueWidgets/CueEQ.ttf
"""
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

UPM = 1000
ADVANCE = 640
BAR_W = 110
GAP = 60
N_BARS = 4
MAX_H = 700
MIN_H = 90

# Bar heights per digit (fractions of MAX_H) — hand-tuned so consecutive
# digits look like motion, not noise.
PATTERNS = {
    "0": (0.35, 0.90, 0.55, 0.20),
    "1": (0.60, 0.45, 0.95, 0.35),
    "2": (0.90, 0.25, 0.60, 0.70),
    "3": (0.45, 0.75, 0.30, 0.95),
    "4": (0.25, 0.55, 0.85, 0.45),
    "5": (0.70, 0.95, 0.40, 0.60),
    "6": (0.50, 0.30, 0.75, 0.90),
    "7": (0.95, 0.60, 0.25, 0.50),
    "8": (0.40, 0.80, 0.95, 0.30),
    "9": (0.65, 0.35, 0.50, 0.80),
}


def bar_glyph(heights):
    pen = TTGlyphPen(None)
    total = N_BARS * BAR_W + (N_BARS - 1) * GAP
    x = (ADVANCE - total) // 2
    for frac in heights:
        h = max(int(MAX_H * frac), MIN_H)
        y0 = (MAX_H - h) // 2  # bars grow from vertical center
        pen.moveTo((x, y0))
        pen.lineTo((x, y0 + h))
        pen.lineTo((x + BAR_W, y0 + h))
        pen.lineTo((x + BAR_W, y0))
        pen.closePath()
        x += BAR_W + GAP
    return pen.glyph()


def empty_glyph():
    return TTGlyphPen(None).glyph()


def main(out_path):
    glyph_order = [".notdef"] + [f"d{c}" for c in PATTERNS] + ["colon", "space"]
    cmap = {ord(c): f"d{c}" for c in PATTERNS}
    cmap[ord(":")] = "colon"
    cmap[ord(" ")] = "space"

    glyphs = {".notdef": empty_glyph(), "colon": empty_glyph(), "space": empty_glyph()}
    for char, pattern in PATTERNS.items():
        glyphs[f"d{char}"] = bar_glyph(pattern)

    metrics = {name: (ADVANCE, 0) for name in glyph_order}
    # Colon and space stay invisible but keep a small advance so the string
    # layout is stable; they get clipped away in the UI anyway.
    metrics["colon"] = (240, 0)
    metrics["space"] = (240, 0)

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(glyph_order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=MAX_H + 100, descent=-100)
    fb.setupOS2(sTypoAscender=MAX_H + 100, sTypoDescender=-100, usWinAscent=MAX_H + 100, usWinDescent=100)
    fb.setupNameTable({"familyName": "CueEQ", "styleName": "Regular", "psName": "CueEQ-Regular", "fullName": "CueEQ Regular"})
    fb.setupPost()
    fb.save(out_path)
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "CueEQ.ttf")
