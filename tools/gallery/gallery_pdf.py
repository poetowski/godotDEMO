"""Builds build/godotDEMO-gallery.pdf from the pictures tools/gallery.gd took into .shots/gallery/
and the text in tools/gallery/gallery.json. Run by `npm run gallery`, or `npm run gallery -- pdf`
to rebuild from the pictures already taken. Needs Python with reportlab and Pillow.
"""
import json
import os
import re
import subprocess
import sys
import time
from xml.sax.saxutils import escape

try:
    from PIL import Image
    from reportlab.lib.colors import HexColor
    from reportlab.lib.styles import ParagraphStyle
    from reportlab.lib.utils import ImageReader
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.pdfgen import canvas
    from reportlab.platypus import Paragraph
except ImportError as error:
    sys.exit(f"[gallery] needs reportlab and Pillow (pip install reportlab pillow): {error}")

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHOTS = os.path.join(ROOT, ".shots", "gallery")
CACHE = os.path.join(SHOTS, "jpg")
OUT = os.path.join(ROOT, "build", "godotDEMO-gallery.pdf")

WIDTH, HEIGHT = 960, 540
MARGIN = 36
# Pixels and quality of what goes in the file: the whole PDF should stay small enough to send.
SHOT_PIXELS, SHOT_QUALITY = 1920, 85
AERIAL_PIXELS, AERIAL_QUALITY = 700, 80
MODEL_PIXELS, MODEL_QUALITY = 480, 80

PAGE = HexColor("#171a16")
PANEL = HexColor("#242820")
TEXT = HexColor("#efe9da")
MUTED = HexColor("#aeaa98")
ACCENT = HexColor("#cfa862")
# Metres along a region's side: the regions' origins in gallery.json are multiples of it.
REGION_SIZE = 200
# Columns and rows of a page of models, the first that holds a whole family; bigger families run on.
MODEL_GRIDS = ((3, 2), (4, 3), (5, 3), (6, 3), (6, 4), (7, 4))
MODEL_RUNNING_ON = (6, 4)


def fonts():
    """Georgia and Segoe UI where Windows has them, else the PDF's own."""
    folder = os.path.join(os.environ.get("WINDIR", "C:/Windows"), "Fonts")
    wanted = {"Serif": "georgia.ttf", "SerifBold": "georgiab.ttf", "SerifItalic": "georgiai.ttf", "Sans": "segoeui.ttf", "SansBold": "seguisb.ttf"}
    if all(os.path.exists(os.path.join(folder, name)) for name in wanted.values()):
        for font, name in wanted.items():
            pdfmetrics.registerFont(TTFont(font, os.path.join(folder, name)))
        return {"serif": "Serif", "bold": "SerifBold", "italic": "SerifItalic", "sans": "Sans", "sans_bold": "SansBold"}
    return {"serif": "Times-Roman", "bold": "Times-Bold", "italic": "Times-Italic", "sans": "Helvetica", "sans_bold": "Helvetica-Bold"}


def region_grid(regions):
    """The regions as a map, north row first: their ids where they lie, None where none is."""
    cells = {(round(region["origin"][0] / REGION_SIZE), round(region["origin"][1] / REGION_SIZE)): region["id"] for region in regions}
    xs = [x for x, _ in cells]
    ys = [y for _, y in cells]
    return [[cells.get((x, y)) for x in range(min(xs), max(xs) + 1)] for y in range(max(ys), min(ys) - 1, -1)]


def picture(name, pixels, quality, square=False):
    """A cached JPEG of a PNG, its path relative to the shots: sized for the file."""
    source = os.path.join(SHOTS, name + ".png")
    if not os.path.exists(source):
        sys.exit(f"[gallery] no picture {source}: run npm run gallery -- world (or models)")
    target = os.path.join(CACHE, f"{name}_{pixels}_{quality}.jpg")
    if os.path.exists(target) and os.path.getmtime(target) >= os.path.getmtime(source):
        return target
    os.makedirs(os.path.dirname(target), exist_ok=True)
    image = Image.open(source).convert("RGB")
    if square:
        w, h = image.size
        image = image.crop(((w - h) // 2, 0, (w + h) // 2, h))
    image.thumbnail((pixels, pixels), Image.LANCZOS)
    image.save(target, quality=quality, optimize=True)
    return target


class Book:
    def __init__(self, data):
        self.data = data
        self.f = fonts()
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        self.c = canvas.Canvas(OUT, pagesize=(WIDTH, HEIGHT), pageCompression=1)
        self.c.setTitle(f'{data["title"]}: {data["subtitle"]}')
        self.c.setSubject(data["note"])
        self.c.setAuthor(data["title"])
        self.grid = region_grid(data["regions"])
        self.number = 0

    def page(self, background=PAGE):
        if self.number:
            self.c.showPage()
        self.number += 1
        self.c.setFillColor(background)
        self.c.rect(0, 0, WIDTH, HEIGHT, stroke=0, fill=1)

    def text(self, words, x, top, width, font, size, color=TEXT, leading=None):
        """A wrapped paragraph hanging from `top`. Returns where it ends."""
        style = ParagraphStyle("t", fontName=font, fontSize=size, leading=leading or size * 1.38, textColor=color)
        paragraph = Paragraph(escape(words), style)
        _, high = paragraph.wrap(width, HEIGHT)
        paragraph.drawOn(self.c, x, top - high)
        return top - high

    def image(self, path, x, y, w, h):
        self.c.drawImage(ImageReader(path), x, y, w, h)

    def fade(self, high, strength):
        """A dark fade up from the page's foot, so text on a picture reads."""
        path = os.path.join(CACHE, f"fade_{round(strength * 100)}.png")
        if not os.path.exists(path):
            os.makedirs(CACHE, exist_ok=True)
            rows = 512
            image = Image.new("RGBA", (4, rows))
            red, green, blue = [round(part * 255) for part in (PAGE.red, PAGE.green, PAGE.blue)]
            for y in range(rows):
                alpha = round(255 * strength * (y / (rows - 1)) ** 1.3)
                for x in range(4):
                    image.putpixel((x, y), (red, green, blue, alpha))
            image.save(path)
        self.c.drawImage(path, 0, 0, WIDTH, high, mask="auto")

    def footer(self, words=""):
        self.c.setFillColor(MUTED)
        self.c.setFont(self.f["sans"], 8.5)
        self.c.drawRightString(WIDTH - MARGIN, 16, str(self.number))
        if words:
            self.c.drawString(MARGIN, 16, words)

    def mark(self, key, title, level=0):
        self.c.bookmarkPage(key)
        self.c.addOutlineEntry(title, key, level)

    # ---- pages

    def cover(self):
        data = self.data
        self.page()
        self.image(picture(data["cover"][0]["id"], SHOT_PIXELS, SHOT_QUALITY), 0, 0, WIDTH, HEIGHT)
        self.fade(300, 0.92)
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["bold"], 58)
        self.c.drawString(MARGIN + 6, 92, data["title"])
        self.c.setFillColor(ACCENT)
        self.c.setFont(self.f["italic"], 22)
        self.c.drawString(MARGIN + 8, 60, data["subtitle"])
        self.c.setFillColor(MUTED)
        self.c.setFont(self.f["sans"], 10.5)
        self.c.drawString(MARGIN + 8, 36, data["note"])
        self.c.drawRightString(WIDTH - MARGIN, 36, time.strftime("%B %Y"))
        self.mark("cover", data["title"])

    def map_page(self):
        self.page()
        self.mark("map", "The world")
        side = HEIGHT - 2 * 26
        rows, columns = len(self.grid), len(self.grid[0])
        cell = side / max(rows, columns)
        left, bottom = 26, 26
        for r, row in enumerate(self.grid):
            for c, name in enumerate(row):
                if name is None:
                    continue
                x, y = left + c * cell, bottom + (rows - 1 - r) * cell
                self.image(picture(f"aerial_{name}", AERIAL_PIXELS, AERIAL_QUALITY, square=True), x, y, cell, cell)
                self.c.setFillColor(PAGE)
                self.c.setFillAlpha(0.62)
                self.c.roundRect(x + 6, y + cell - 25, 29, 19, 4, stroke=0, fill=1)
                self.c.setFillAlpha(1)
                self.c.setFillColor(TEXT)
                self.c.setFont(self.f["sans_bold"], 11)
                self.c.drawCentredString(x + 20.5, y + cell - 20, name)
                self.c.linkRect("", f"region_{name}", (x, y, x + cell, y + cell), relative=0, thickness=0)
        self.c.setStrokeColor(PAGE)
        self.c.setLineWidth(1.2)
        for k in range(1, columns):
            self.c.line(left + k * cell, bottom, left + k * cell, bottom + rows * cell)
        for k in range(1, rows):
            self.c.line(left, bottom + k * cell, left + columns * cell, bottom + k * cell)
        x = left + side + 28
        width = WIDTH - x - MARGIN
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["bold"], 25)
        self.c.drawString(x, HEIGHT - 58, "The world")
        y = HEIGHT - 72
        for paragraph in self.data["about"]:
            y = self.text(paragraph, x, y, width, self.f["sans"], 11, leading=15) - 7
        y -= 8
        self.c.setFillColor(ACCENT)
        self.c.setFont(self.f["sans_bold"], 9.5)
        self.c.drawString(x, y, "IN THIS BOOK")
        y -= 16
        for region in self.data["regions"]:
            name = region["id"]
            self.c.setFillColor(TEXT)
            self.c.setFont(self.f["sans_bold"], 10)
            self.c.drawString(x, y, name)
            self.c.setFillColor(MUTED)
            self.c.setFont(self.f["sans"], 10)
            self.c.drawString(x + 24, y, region["status"])
            self.c.linkRect("", f"region_{name}", (x, y - 3, x + width, y + 10), relative=0, thickness=0)
            y -= 15
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["sans_bold"], 10)
        self.c.drawString(x, y, "+")
        self.c.setFillColor(MUTED)
        self.c.setFont(self.f["sans"], 10)
        extras = [group["title"] for group in self.data.get("extra", [])]
        self.c.drawString(x + 24, y, ", ".join(extras + ["every model"]).capitalize())
        self.c.linkRect("", "models", (x, y - 3, x + width, y + 10), relative=0, thickness=0)

    def locator(self, name, x, y, cell=15):
        """The regions as a little map, this one lit."""
        rows = len(self.grid)
        for r, row in enumerate(self.grid):
            for c, other in enumerate(row):
                if other is None:
                    continue
                self.c.setFillColor(ACCENT if other == name else PANEL)
                self.c.rect(x + c * (cell + 2), y + (rows - 1 - r) * (cell + 2), cell, cell, stroke=0, fill=1)

    def region_column(self, region, x, width, top=HEIGHT - 38):
        name = region["id"]
        self.c.setFillColor(ACCENT)
        self.c.setFont(self.f["bold"], 44)
        self.c.drawString(x, top - 40, name)
        self.locator(name, x + width - 55, top - 41)
        y = self.text(region["status"], x, top - 56, width, self.f["italic"], 17, leading=21)
        return self.text(region["intro"], x, y - 10, width, self.f["sans"], 11.2, leading=15.6)

    def region_opener(self, region):
        self.page()
        self.mark(f'region_{region["id"]}', f'{region["id"]}: {region["status"]}')
        side = HEIGHT - 2 * 26
        self.image(picture(f'aerial_{region["id"]}', AERIAL_PIXELS, AERIAL_QUALITY, square=True), WIDTH - side - 26, 26, side, side)
        width = WIDTH - side - 26 - MARGIN - 28
        y = self.region_column(region, MARGIN, width) - 20
        self.c.setFillColor(ACCENT)
        self.c.setFont(self.f["sans_bold"], 9.5)
        self.c.drawString(MARGIN, y, "IN THESE PAGES")
        y -= 17
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["sans"], 11)
        for shot in region["shots"]:
            self.c.drawString(MARGIN, y, shot["title"])
            y -= 15.5
        self.c.setFillColor(MUTED)
        self.c.setFont(self.f["sans"], 8.5)
        self.c.drawString(MARGIN, 30, "From above, north up. 200 by 200 metres.")
        self.footer()

    def region_alone(self, region):
        """A region with one picture: its text and aerial beside it."""
        self.page()
        self.mark(f'region_{region["id"]}', f'{region["id"]}: {region["status"]}')
        width = 250
        y = self.region_column(region, MARGIN, width)
        side = min(width, y - 50)
        self.image(picture(f'aerial_{region["id"]}', AERIAL_PIXELS, AERIAL_QUALITY, square=True), MARGIN, 34, side, side)
        shot = region["shots"][0]
        x = MARGIN + width + 26
        w = WIDTH - x - 26
        h = w * 9 / 16
        top = HEIGHT - 58
        self.image(picture(shot["id"], SHOT_PIXELS, SHOT_QUALITY), x, top - h, w, h)
        self.caption(shot, x, top - h - 12, w)
        self.footer()

    def region_two(self, region):
        """A region with two pictures: its text and aerial, and the two with their words beside them."""
        self.page()
        self.mark(f'region_{region["id"]}', f'{region["id"]}: {region["status"]}')
        width = 250
        y = self.region_column(region, MARGIN, width)
        side = min(width, y - 50)
        self.image(picture(f'aerial_{region["id"]}', AERIAL_PIXELS, AERIAL_QUALITY, square=True), MARGIN, 34, side, side)
        x = MARGIN + width + 26
        h = (HEIGHT - 2 * 34 - 14) / 2
        w = h * 16 / 9
        for k, shot in enumerate(region["shots"]):
            top = HEIGHT - 34 - k * (h + 14)
            self.image(picture(shot["id"], SHOT_PIXELS, SHOT_QUALITY), x, top - h, w, h)
            self.caption(shot, x + w + 14, top, WIDTH - x - w - 14 - 26)
        self.footer()

    def caption(self, shot, x, top, width):
        y = self.text(shot["title"], x, top, width, self.f["bold"], 16, leading=20)
        return self.text(shot["caption"], x, y - 3, width, self.f["sans"], 11.4, MUTED, leading=15.4)

    def full(self, shot, tag):
        self.page()
        self.image(picture(shot["id"], SHOT_PIXELS, SHOT_QUALITY), 0, 0, WIDTH, HEIGHT)
        self.fade(150, 0.9)
        y = self.text(shot["title"], MARGIN, 76, WIDTH - 2 * MARGIN, self.f["bold"], 22, leading=27)
        self.text(shot["caption"], MARGIN, y - 2, 700, self.f["sans"], 11.4, leading=15)
        self.c.setFillColor(ACCENT)
        self.c.setFont(self.f["sans_bold"], 10)
        self.c.drawRightString(WIDTH - MARGIN, 34, tag)
        self.footer()

    def pair(self, shots, tag):
        self.page()
        gap = 16
        w = (WIDTH - 2 * 26 - gap) / 2
        h = w * 9 / 16
        # The pictures and their words sit in the middle of the page.
        top = HEIGHT / 2 + (h + 76) / 2
        self.c.setFillColor(ACCENT)
        self.c.setFont(self.f["sans_bold"], 11)
        self.c.drawString(26, top + 12, tag)
        for k, shot in enumerate(shots):
            x = 26 + k * (w + gap)
            self.image(picture(shot["id"], SHOT_PIXELS, SHOT_QUALITY), x, top - h, w, h)
            self.caption(shot, x, top - h - 14, w)
        self.footer()

    def region(self, region):
        shots = region["shots"]
        if len(shots) == 1:
            self.region_alone(region)
            return
        if len(shots) == 2:
            self.region_two(region)
            return
        self.region_opener(region)
        tag = region["id"]
        waiting = []
        for shot in shots:
            if shot.get("layout") == "half":
                waiting.append(shot)
                if len(waiting) == 2:
                    self.pair(waiting, tag)
                    waiting = []
            else:
                self.full(shot, tag)
        if waiting:
            self.full(waiting[0], tag)

    def time_page(self, group):
        self.page()
        self.mark("time", group["title"])
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["bold"], 25)
        self.c.drawString(MARGIN, HEIGHT - 46, group["title"])
        self.text(group["text"], MARGIN, HEIGHT - 54, WIDTH - 2 * MARGIN, self.f["sans"], 11, MUTED)
        gap = 8
        h = (HEIGHT - 82 - 28 - gap) / 2
        w = h * 16 / 9
        left = (WIDTH - 2 * w - gap) / 2
        for k, shot in enumerate(group["shots"]):
            x = left + (k % 2) * (w + gap)
            y = 28 + (1 - k // 2) * (h + gap)
            self.image(picture(shot["id"], SHOT_PIXELS, SHOT_QUALITY), x, y, w, h)
            self.c.setFillColor(PAGE)
            self.c.setFillAlpha(0.65)
            self.c.roundRect(x + 8, y + 8, 56, 20, 4, stroke=0, fill=1)
            self.c.setFillAlpha(1)
            self.c.setFillColor(TEXT)
            self.c.setFont(self.f["sans_bold"], 10)
            self.c.drawCentredString(x + 36, y + 14.5, shot["label"])
        self.footer()

    def models(self):
        path = os.path.join(SHOTS, "models.json")
        if not os.path.exists(path):
            sys.exit("[gallery] no models.json: run npm run gallery -- models")
        with open(path, encoding="utf-8") as file:
            sizes = json.load(file)
        families = {}
        for slug in sizes:
            families.setdefault(family_of(slug), []).append(slug)
        known = self.data["families"]
        for family in families:
            if family not in known:
                print(f"[gallery] no title for family {family!r}: add it to gallery.json")
        order = [name for name in known if name in families and name != "hero"] + [name for name in families if name not in known]
        self.models_intro(sizes, families, order)
        for family in order:
            slugs = sorted(families[family])
            grid = next((grid for grid in MODEL_GRIDS if grid[0] * grid[1] >= len(slugs)), MODEL_RUNNING_ON)
            per_page = grid[0] * grid[1]
            for k in range(0, len(slugs), per_page):
                self.models_page(family, slugs[k : k + per_page], sizes, len(slugs), k > 0, grid)

    def models_intro(self, sizes, families, order):
        self.page()
        self.mark("models", "Every model")
        known = self.data["families"]
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["bold"], 30)
        self.c.drawString(MARGIN, HEIGHT - 62, "Every model")
        y = self.text(f"{len(sizes)} models so far, all made in this project in Blender, grouped in families so that what stands together looks like it belongs together. Each is shown here on a plain floor, with its size in metres.", MARGIN, HEIGHT - 76, 430, self.f["sans"], 11.4, leading=16)
        y -= 16
        for family in order:
            info = known.get(family, {"title": family.capitalize(), "text": ""})
            self.c.setFillColor(ACCENT)
            self.c.setFont(self.f["sans_bold"], 10.5)
            self.c.drawString(MARGIN, y, f'{info["title"]}  ({len(families[family])})')
            y = self.text(info["text"], MARGIN, y - 4, 430, self.f["sans"], 9.6, MUTED, leading=12.6) - 11
        if "hero" in sizes:
            w = 410
            h = w * 2 / 3
            x = WIDTH - w - MARGIN
            bottom = (HEIGHT - h) / 2 + 8
            self.image(picture("models/hero", 800, 82), x, bottom, w, h)
            info = known["hero"]
            self.text(f'{info["title"]}. {info["text"]}', x, bottom - 8, w, self.f["sans"], 10, MUTED)
        self.footer()

    def models_page(self, family, slugs, sizes, count, more, grid):
        self.page()
        info = self.data["families"].get(family, {"title": family.capitalize(), "text": ""})
        if not more:
            self.mark(f"family_{family}", info["title"], 1)
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["bold"], 19)
        self.c.drawString(MARGIN, HEIGHT - 40, info["title"] + (", continued" if more else ""))
        self.c.setFillColor(MUTED)
        self.c.setFont(self.f["sans"], 10)
        self.c.drawRightString(WIDTH - MARGIN, HEIGHT - 39, f"{count} models")
        columns, rows = grid
        gap = 8
        label = 25
        top = HEIGHT - 52
        h = min((WIDTH - 2 * MARGIN - (columns - 1) * gap) / columns * 2 / 3, (top - 30) / rows - label)
        w = h * 3 / 2
        row = h + label
        left = (WIDTH - columns * w - (columns - 1) * gap) / 2
        for k, slug in enumerate(slugs):
            x = left + (k % columns) * (w + gap)
            y = top - (k // columns) * row - h
            self.image(picture(f"models/{slug}", MODEL_PIXELS, MODEL_QUALITY), x, y, w, h)
            self.c.setFillColor(TEXT)
            self.c.setFont(self.f["sans_bold"], 8.2)
            self.c.drawString(x, y - 10, model_name(slug))
            sx, sy, sz = sizes[slug]
            self.c.setFillColor(MUTED)
            self.c.setFont(self.f["sans"], 7.2)
            self.c.drawString(x, y - 19, f"{sx:.1f} x {sz:.1f} m, {sy:.1f} m tall")
        self.footer()

    def closing(self):
        self.page()
        extra = self.data.get("extra", [])
        shot = extra[0]["shots"][-1]["id"] if extra else self.data["cover"][0]["id"]
        self.image(picture(shot, SHOT_PIXELS, SHOT_QUALITY), 0, 0, WIDTH, HEIGHT)
        self.c.setFillColor(PAGE)
        self.c.setFillAlpha(0.58)
        self.c.rect(0, 0, WIDTH, HEIGHT, stroke=0, fill=1)
        self.c.setFillAlpha(1)
        self.c.setFillColor(TEXT)
        self.c.setFont(self.f["bold"], 34)
        self.c.drawCentredString(WIDTH / 2, HEIGHT / 2 + 12, "More to come")
        self.c.setFillColor(MUTED)
        self.c.setFont(self.f["sans"], 11)
        self.c.drawCentredString(WIDTH / 2, HEIGHT / 2 - 14, "Made with Godot and Blender. Pictures taken in the game.")
        self.c.setFont(self.f["sans"], 9)
        self.c.drawCentredString(WIDTH / 2, 28, f"Build {revision()}, {time.strftime('%d %B %Y')}")

    def build(self):
        self.cover()
        self.map_page()
        for region in self.data["regions"]:
            self.region(region)
        for group in self.data.get("extra", []):
            self.time_page(group)
        self.models()
        self.closing()
        self.c.save()


def family_of(slug):
    if slug == "hero":
        return "hero"
    script = os.path.join(ROOT, "tools", "blender", "assets", slug + ".py")
    if os.path.exists(script):
        with open(script, encoding="utf-8") as file:
            source = file.read()
        found = re.search(r"Part of the (.+?) family", source) or re.search(r"^import (\w+)\s+# noqa", source, re.M) or re.search(r"from (\w+) import", source)
        if found:
            return found[1]
    return "other"


def model_name(slug):
    words = slug.split("_")
    if len(words[-1]) == 1:
        words[-1] = words[-1].upper()
    return " ".join(words).capitalize() if len(words[-1]) > 1 else " ".join(words[:-1]).capitalize() + " " + words[-1]


def revision():
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def main():
    with open(os.path.join(ROOT, "tools", "gallery", "gallery.json"), encoding="utf-8") as file:
        data = json.load(file)
    book = Book(data)
    book.build()
    size = os.path.getsize(OUT) / (1024 * 1024)
    print(f"[gallery] {OUT}: {book.number} pages, {size:.1f} MB")


if __name__ == "__main__":
    main()
