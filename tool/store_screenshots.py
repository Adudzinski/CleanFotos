"""Builds the 1.4 store screenshots and Play feature graphic.

Input: raw emulator captures (1080x2400) in RAW_DIR, named as in SHOTS.
Output: assets/store/1.4/{appstore_6.9,appstore_6.5,appstore_6.3,appstore_6.1,
play_phone}/ and assets/store/1.4/play_feature_graphic.png

    python tool/store_screenshots.py <raw_dir>

The Android status bar and gesture handle are cropped off, so the same
captures are fine for the App Store (Apple rejects other-platform chrome).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT_DIR = os.path.join(ROOT, 'assets', 'fonts')
OUT = os.path.join(ROOT, 'assets', 'store', '1.4')
LOGO = os.path.join(ROOT, 'assets', 'icon', 'icon_header.png')

BG = (10, 10, 12)
TEXT = (244, 244, 245)
MUTED = (161, 161, 170)
PURPLE = (108, 99, 255)
GOLD = (245, 196, 81)

# (raw file, headline, subline) — store order: strongest first.
SHOTS = [
    ('3b_swipe_drag.png', 'Swipe to keep\nor delete', 'Undo anytime. You confirm once.'),
    ('4_similar.png', 'Bursts and retakes,\nside by side', "Tap the ones you don't want."),
    ('5_finished.png', 'See the space\nyou really freed', 'Counted only after you confirm.'),
    ('1_home.png', 'Clean up your\nlibrary, calmly', 'New photos show up by themselves.'),
    ('2_resume_sheet.png', 'Pick up where\nyou left off', "Continue in 2024 — or see what's new."),
    ('6_milestones.png', 'Milestones that\nkeep you going', 'From 100 MB all the way to 50 GB.'),
]

# Crop of the 1080x2400 capture: below the status bar, above the gesture bar.
CROP = (0, 84, 1080, 2340)

# App Store Connect sizes per iPhone display class (portrait):
#   6.9": 1320x2868 · 6.5": 1284x2778 · 6.3": 1206x2622 · 6.1": 1179x2556
TARGETS = {
    'appstore_6.9': (1320, 2868),
    'appstore_6.5': (1284, 2778),
    'appstore_6.3': (1206, 2622),
    'appstore_6.1': (1179, 2556),
    'play_phone': (1080, 1920),
}


def font(weight, size):
    name = {600: 'Geist-SemiBold.ttf', 700: 'Geist-Bold.ttf',
            500: 'Geist-Medium.ttf', 400: 'Geist-Regular.ttf'}[weight]
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def glow_background(w, h, centers):
    """Noir background with soft purple light."""
    img = Image.new('RGB', (w, h), BG)
    layer = Image.new('RGB', (w, h), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    for (cx, cy, r, color) in centers:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(max(w, h) * 0.12))
    return Image.blend(img, Image.eval(layer, lambda v: v), 0.55)


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0] - 1, img.size[1] - 1], radius, fill=255)
    out = Image.new('RGBA', img.size)
    out.paste(img, (0, 0), mask)
    return out


def phone(capture, width):
    """The cropped capture in a rounded frame with a hairline and shadow."""
    shot = capture.crop(CROP).convert('RGB')
    h = round(shot.size[1] * width / shot.size[0])
    shot = shot.resize((width, h), Image.LANCZOS)
    radius = round(width * 0.075)
    framed = rounded(shot, radius)
    d = ImageDraw.Draw(framed)
    d.rounded_rectangle([1, 1, width - 2, h - 2], radius,
                        outline=(255, 255, 255, 46), width=max(2, width // 400))
    return framed


def paste_with_shadow(canvas, item, x, y, blur):
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sh = Image.new('RGBA', item.size, (0, 0, 0, 170))
    shadow.paste(sh, (x, y + blur // 2), item)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(item, (x, y))


def draw_centered(d, text, y, fnt, fill, w, spacing):
    for line in text.split('\n'):
        tw = d.textlength(line, font=fnt)
        d.text(((w - tw) / 2, y), line, font=fnt, fill=fill)
        y += round(fnt.size * spacing)
    return y


def screenshot(capture, headline, sub, size):
    w, h = size
    canvas = glow_background(w, h, [
        (w * 0.5, -h * 0.02, w * 0.75, PURPLE),
        (w * 1.0, h * 0.55, w * 0.45, (60, 45, 160)),
    ]).convert('RGBA')
    d = ImageDraw.Draw(canvas)
    tall = h / w > 2
    hf = font(600, round(w * (0.083 if tall else 0.072)))
    sf = font(400, round(w * (0.038 if tall else 0.034)))
    y = round(h * (0.06 if tall else 0.05))
    y = draw_centered(d, headline, y, hf, TEXT, w, 1.12)
    y += round(hf.size * 0.25)
    y = draw_centered(d, sub, y, sf, MUTED, w, 1.3)
    pw = round(w * (0.80 if tall else 0.70))
    p = phone(capture, pw)
    top = y + round(h * 0.035)
    paste_with_shadow(canvas, p, (w - pw) // 2, top, round(w * 0.03))
    return canvas.convert('RGB')


def feature_graphic(home, drag):
    w, h = 1024, 500
    canvas = glow_background(w, h, [
        (w * 0.18, h * 0.1, 360, PURPLE),
        (w * 0.85, h * 0.9, 300, (60, 45, 160)),
    ]).convert('RGBA')
    d = ImageDraw.Draw(canvas)
    logo = Image.open(LOGO).convert('RGBA').resize((112, 112), Image.LANCZOS)
    canvas.alpha_composite(logo, (56, 78))
    d.text((184, 98), 'CleanFotos', font=font(600, 64), fill=TEXT)
    d.text((60, 236), 'Clean up your library,', font=font(600, 40), fill=TEXT)
    d.text((60, 286), 'calmly.', font=font(600, 40), fill=TEXT)
    d.text((60, 352), 'Similar shots  ·  Swipe  ·  Undo', font=font(500, 24), fill=MUTED)
    # Milestone chip in gold — the reward colour.
    chip_font = font(600, 22)
    label = 'Milestones for real space freed'
    tw = d.textlength(label, font=chip_font)
    d.rounded_rectangle([60, 404, 60 + tw + 56, 446], 21,
                        fill=(30, 26, 12), outline=GOLD, width=2)
    d.ellipse([74, 418, 88, 432], fill=GOLD)
    d.text((98, 410), label, font=chip_font, fill=GOLD)
    # Two phones on the right, the front one tilted, bleeding off the bottom.
    back = phone(home, 230).rotate(6, resample=Image.BICUBIC, expand=True)
    front = phone(drag, 250).rotate(-5, resample=Image.BICUBIC, expand=True)
    paste_with_shadow(canvas, back, 760, 60, 16)
    paste_with_shadow(canvas, front, 590, 40, 18)
    return canvas.convert('RGB')


def main(raw_dir):
    for name in TARGETS:
        os.makedirs(os.path.join(OUT, name), exist_ok=True)
    for i, (raw, headline, sub) in enumerate(SHOTS, start=1):
        capture = Image.open(os.path.join(raw_dir, raw))
        assert capture.size == (1080, 2400), (raw, capture.size)
        slug = os.path.splitext(raw)[0].split('_', 1)[1]
        for name, size in TARGETS.items():
            img = screenshot(capture, headline, sub, size)
            assert img.size == size
            img.save(os.path.join(OUT, name, '%d_%s.png' % (i, slug)), optimize=True)
    fg = feature_graphic(Image.open(os.path.join(raw_dir, '1_home.png')),
                         Image.open(os.path.join(raw_dir, '3b_swipe_drag.png')))
    fg.save(os.path.join(OUT, 'play_feature_graphic.png'), optimize=True)
    print('done ->', OUT)


if __name__ == '__main__':
    main(sys.argv[1])
