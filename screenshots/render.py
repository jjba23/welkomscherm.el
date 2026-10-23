#!/usr/bin/env python3
"""Draw welkomscherm's captured output as a screenshot and an animated GIF.

The text, the styling runs (muted / button / default) and the separator
positions all come from `capture.el', which renders the *real* package in a
batch Emacs.  This script only picks colours and draws the frame around it,
using the Modus themes' own palette values, so the pictures show what the
package actually puts in the buffer.
"""

import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)

FONT_PATH = "/usr/share/fonts/texlive-dejavu/DejaVuSansMono.ttf"
FONT_SIZE = 18
LINE_H = 26
PAD_X = 34
PAD_TOP = 30
GAP_BEFORE_MODE_LINE = 22
MODE_LINE_H = 32
RADIUS = 12
SHADOW_BLUR = 16
SHADOW_OFFSET = 8

THEMES = {
    "dark": {
        # modus-vivendi / modus-vivendi-warp values
        "bg": "#0d0e1c",
        "fg": "#ffffff",
        "muted": "#989898",
        "button": "#2fafff",
        "mode_line_bg": "#505050",
        "mode_line_fg": "#ffffff",
        "border": "#242640",
        "canvas": "#16171f",
    },
    "light": {
        # modus-operandi values
        "bg": "#ffffff",
        "fg": "#000000",
        "muted": "#595959",
        "button": "#0031a9",
        "mode_line_bg": "#c8c8c8",
        "mode_line_fg": "#000000",
        "border": "#d0d0d0",
        "canvas": "#e8e8ee",
    },
}

FONT = ImageFont.truetype(FONT_PATH, FONT_SIZE)
ADVANCE = FONT.getlength("M")  # monospace: every glyph is ADVANCE wide


def load(name):
    with open(os.path.join(HERE, "out", name), encoding="utf-8") as handle:
        return json.load(handle)


def line_width(row):
    if row["type"] != "text":
        return 0
    return sum(len(run["text"]) for run in row["runs"])


def window_size(data, rows):
    cols = max([data["cols"]] + [line_width(row) for row in data["rows"]])
    width = round(cols * ADVANCE) + 2 * PAD_X
    height = PAD_TOP + rows * LINE_H + GAP_BEFORE_MODE_LINE + MODE_LINE_H
    return cols, width, height


def draw_row(draw, row, y, x0, cols, theme, rule_width):
    """Draw one captured row at vertical offset Y."""
    if row["type"] == "rule":
        glyphs = "─" * rule_width
        draw.text((x0, y), glyphs, font=FONT, fill=theme["muted"])
        return
    col = 0
    for run in row["runs"]:
        text = run["text"]
        face = run["face"]
        x = x0 + round(col * ADVANCE)
        if face == "muted":
            colour = theme["muted"]
        elif face == "button":
            colour = theme["button"]
        else:
            colour = theme["fg"]
        draw.text((x, y), text, font=FONT, fill=colour)
        if face == "button":
            # Emacs draws buttons underlined; a dotted rule is the familiar look.
            underline_y = y + FONT_SIZE + 3
            for dot in range(0, round(len(text) * ADVANCE), 4):
                draw.line(
                    [(x + dot, underline_y), (x + dot + 1, underline_y)],
                    fill=colour,
                )
        col += len(text)


def draw_mode_line(draw, y, width, theme):
    draw.rectangle([0, y, width, y + MODE_LINE_H], fill=theme["mode_line_bg"])
    text_y = y + (MODE_LINE_H - FONT_SIZE) // 2 - 1
    draw.text((PAD_X, text_y), "*welkomscherm*   All L1   (Fundamental)",
              font=FONT, fill=theme["mode_line_fg"])
    right = "Top"
    draw.text((width - PAD_X - round(len(right) * ADVANCE), text_y), right,
              font=FONT, fill=theme["mode_line_fg"])


def render(data, theme_name, rows=None, canvas_colour=None):
    """Return the welcome screen drawn as an image, window and all.

    When ROWS is given it is the height of the frame, in text rows, and the
    drawn lines sit centred in it, the way a short dashboard looks in a tall
    window.  CANVAS-COLOUR lets every frame of the GIF share one backdrop.
    """
    theme = dict(THEMES[theme_name])
    if canvas_colour:
        theme["canvas"] = canvas_colour
    cols, width, height = window_size(data, rows or len(data["rows"]))
    x0 = PAD_X

    body = Image.new("RGB", (width, height), theme["bg"])
    draw = ImageDraw.Draw(body)

    mode_line_y = height - MODE_LINE_H
    draw_mode_line(draw, mode_line_y, width, theme)
    draw.line([(0, mode_line_y), (width, mode_line_y)], fill=theme["border"])

    offset = (rows - len(data["rows"])) * LINE_H // 2 if rows else 0
    for index, row in enumerate(data["rows"]):
        draw_row(draw, row, PAD_TOP + offset + index * LINE_H, x0, cols, theme,
                 data["cols"])

    # Rounded corners, a hairline border and a soft shadow: enough chrome to
    # read as a window, not so much that it distracts from the screen itself.
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, width - 1, height - 1], radius=RADIUS, fill=255
    )
    frame = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    frame.paste(body, (0, 0))
    frame.putalpha(mask)

    border = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(border).rounded_rectangle(
        [0, 0, width - 1, height - 1], radius=RADIUS,
        outline=theme["border"], width=1,
    )
    frame = Image.alpha_composite(frame, border)

    pad = 2 * SHADOW_BLUR
    canvas = Image.new("RGB", (width + 2 * pad, height + 2 * pad),
                       theme["canvas"])
    shadow_mask = Image.new("L", canvas.size, 0)
    shadow_mask.paste(mask, (pad, pad + SHADOW_OFFSET))
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))
    shadow = Image.new("RGB", canvas.size, "#000000")
    canvas.paste(shadow, (0, 0), shadow_mask.point(lambda value: value * 0.45))
    canvas.paste(frame, (pad, pad), frame)
    return canvas


def save_gif(frames, path, durations):
    width, height = frames[0].size
    stack = Image.new("RGB", (width, height * len(frames)))
    for index, frame in enumerate(frames):
        stack.paste(frame, (0, index * height))
    palette_source = stack.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    quantised = [
        frame.quantize(palette=palette_source, dither=Image.Dither.NONE)
        for frame in frames
    ]
    quantised[0].save(
        path,
        save_all=True,
        append_images=quantised[1:],
        duration=durations,
        loop=0,
        optimize=True,
        disposal=2,
    )


def main():
    out_dir = os.path.join(REPO, "screenshots")
    os.makedirs(out_dir, exist_ok=True)

    default = load("default.json")
    full = load("full.json")
    rows = max(len(default["rows"]), len(full["rows"]))

    for theme, data, name in (
        ("dark", default, "welkomscherm-dark.png"),
        ("light", default, "welkomscherm-light.png"),
        ("dark", full, "welkomscherm-full-dark.png"),
        ("light", full, "welkomscherm-full-light.png"),
    ):
        image = render(data, theme)
        image.save(os.path.join(out_dir, name))
        print("wrote", name, image.size)

    # One backdrop for every frame, so that switching theme does not flash.
    backdrop = "#14151b"
    frames = [
        render(default, "dark", rows, backdrop),
        render(full, "dark", rows, backdrop),
        render(default, "light", rows, backdrop),
        render(full, "light", rows, backdrop),
    ]
    gif = os.path.join(out_dir, "welkomscherm-demo.gif")
    save_gif(frames, gif, [2200, 2600, 2200, 2600])
    print("wrote welkomscherm-demo.gif", os.path.getsize(gif) // 1024, "KiB")


if __name__ == "__main__":
    sys.exit(main())
