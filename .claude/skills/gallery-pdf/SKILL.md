---
name: gallery-pdf
description: Make the shareable PDF of the game's world: clean screenshots of every region without the grid or HUD, an overhead map of the world, captions, a day-to-night page and a catalogue of every model, for people and fans. Use when asked for a PDF, gallery, showcase, lookbook or presentation of the game, or to refresh it after the world has changed. It only reads the game and changes nothing in it.
argument-hint: "[what changed, or what to show]"
---

# Gallery PDF

`npm run gallery` takes every picture in one run of the real world and builds
`build/godotDEMO-gallery.pdf`, which isn't committed. It's written for people outside the
project, so the words are plain and say nothing about tools, sectors or the repository.

| Command | What it does |
|---|---|
| `npm run gallery` | Everything, in a minute or two: world shots, model photographs, the PDF. |
| `npm run gallery -- world --only=r1_,time` | Retake only the shots whose id starts with these. |
| `npm run gallery -- models` | Photograph the models again. |
| `npm run gallery -- pdf` | Rebuild the PDF from the pictures already in `.shots/gallery/`, after changing words. |

The parts:

- `tools/gallery/gallery.json`: every shot and every word. Change this to change the book.
- `tools/gallery.gd`: takes the pictures. For its own run only, it hides the borders, HUD and
  hero and mutes the sound. It saves nothing but PNGs into `.shots/gallery/`.
- `tools/gallery/gallery_pdf.py`: lays out the pages. It needs Python with `reportlab` and
  `Pillow`, and uses Georgia and Segoe UI where Windows has them.

## Refreshing it

1. Run `git status --short data/world` and commit the author's land first, as with any world
   work, then check `tasklist` as usual: close the game before a run. The window has to stay
   open, as it renders.
2. Find what's new since the last book: `git log` and the regions' `terrain.md`. Add a shot for
   each new place to its region in `gallery.json`, and update that region's `status` and `intro`.
   A new region gets an entry in `regions` with its `origin` (its south-west corner in metres,
   `[x east, y north]`): the map is laid out from the origins. A region's overhead view and the
   map update themselves, as do the models: a new family only needs a title and a line under
   `families`, and the build prints which one is missing.
3. Run `npm run gallery`, then **look at every page**. Pictures alone won't show a broken page:
   render them with `uv run --no-project --with pypdfium2 --with pillow python <script>`, using
   `PdfDocument(path)[n].render(scale=0.5).to_pil()`, into your scratchpad.
4. Retake what's blocked or dull, rebuild, and give the author the file's path. If they asked for
   the tools to change, commit and push those. The PDF stays out of git.

## A shot

```json
{"id": "r1_land", "from": [20, 20, 2], "look": [120, 120, 0], "hour": 10, "fov": 58,
 "layout": "full", "title": "Open land", "caption": "..."}
```

- **`from` and `look`** are `[x east, y north, metres above the ground there]`, in the same metres
  as the rest of the world: R1 runs 0 to 200 each way.
- **Hanging over a drop:** a fourth item, `"abs"`, makes the height metres above sea level, for a
  camera out past a cliff's rim looking back at it, where "above the ground" would mean far below.
- **`layout`:** `full` fills the page with the words over it. Two `half`s in a row share a page. A
  region with one or two shots gets a single page with its text, and the layouts are ignored.
- **The id's start** sets what `--only` retakes, so keep the region in it.
- **Every picture is the game as it plays**, except the overhead views, which draw all plants at any
  distance and lift the haze so the map reads.

## Aiming

- Find a thing's position in `field.tscn`, or in the tables at the top of its sector's `.gd`.
- Blocked pictures are the usual fault: a roof, a tree or a hillside right in front of the camera.
  Step back and narrow `fov` to 45-50, or come from another side. Keep the eye at about 2 to 3 m for
  a person's view, higher only to show a layout.
- Avoid looking straight at the sun unless it's the point, and vary the `hour` from page to page.
  Evening light flatters the land; noon flattens it. Night needs lights in frame or it's black.

## The words

- **State only what's true and in the game:** what stands there, from `docs/world/regions/`.
- **Don't invent** lore, names or plans. The only names are the ones the author gave, so regions
  stay R1, R2..., and the game's title stays a working title.
- **Say so when a region is empty.** "Open land, not built yet" is the honest line, and it's fine.
