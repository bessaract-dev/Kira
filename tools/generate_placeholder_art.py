"""Генерирует временную (placeholder) графику для каркаса игры.

Запуск: python3 tools/generate_placeholder_art.py  (нужен Pillow: pip install pillow)
Настоящие спрайты потом просто кладутся поверх этих файлов с теми же именами.
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures")
T = 32  # размер тайла


def save(img, *parts):
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


def tiles():
    """Атлас 4x1: камень, дерево, платформа-полка, тёмный кирпич."""
    rnd = random.Random(3)
    img = Image.new("RGBA", (T * 4, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 0: камень (готическая кладка)
    d.rectangle([0, 0, T - 1, T - 1], fill=(52, 50, 62))
    for y in (0, 16):
        d.line([0, y, T, y], fill=(30, 28, 38))
    for x, y in ((0, 0), (16, 0), (8, 16), (24, 16)):
        d.line([x, y, x, y + 16], fill=(30, 28, 38))
    for _ in range(25):
        px, py = rnd.randrange(T), rnd.randrange(T)
        d.point((px, py), fill=(70, 68, 82))
    d.line([0, 0, T, 0], fill=(80, 78, 95))
    # 1: дерево (пол дома)
    o = T
    d.rectangle([o, 0, o + T - 1, T - 1], fill=(62, 42, 34))
    for y in (8, 16, 24):
        d.line([o, y, o + T, y], fill=(40, 26, 22))
    d.line([o + 12, 0, o + 12, 8], fill=(40, 26, 22))
    d.line([o + 22, 8, o + 22, 16], fill=(40, 26, 22))
    d.line([o + 6, 16, o + 6, 24], fill=(40, 26, 22))
    d.line([o, 0, o + T, 0], fill=(95, 68, 52))
    # 2: полка / односторонняя платформа (верхние 8 px)
    o = T * 2
    d.rectangle([o, 0, o + T - 1, 7], fill=(78, 56, 44))
    d.line([o, 0, o + T, 0], fill=(110, 80, 60))
    d.line([o + 4, 8, o + 8, 14], fill=(50, 34, 28), width=2)
    d.line([o + T - 5, 8, o + T - 9, 14], fill=(50, 34, 28), width=2)
    # 3: тёмный кирпич
    o = T * 3
    d.rectangle([o, 0, o + T - 1, T - 1], fill=(36, 30, 40))
    for y in (0, 10, 21):
        d.line([o, y, o + T, y], fill=(22, 18, 26))
    for x, y in ((o + 10, 0), (o + 22, 10), (o + 6, 21), (o + 26, 21)):
        d.line([x, y, x, y + 10], fill=(22, 18, 26))
    save(img, "tiles.png")


def ghost_girl():
    """Девочка-душа: бледно-голубой силуэт, 24x44, смотрит вправо."""
    img = Image.new("RGBA", (24, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (190, 215, 255, 230)
    # платье
    d.polygon([(12, 18), (3, 41), (21, 41)], fill=body)
    # волосы и голова
    d.ellipse([5, 2, 19, 17], fill=(120, 140, 190, 235))
    d.ellipse([7, 4, 19, 17], fill=body)
    d.rectangle([4, 8, 8, 24], fill=(120, 140, 190, 235))
    # глаза
    d.rectangle([14, 9, 15, 11], fill=(30, 40, 70, 255))
    d.rectangle([17, 9, 18, 11], fill=(30, 40, 70, 255))
    # призрачный низ платья
    for x in range(4, 21, 4):
        d.polygon([(x, 41), (x + 2, 44), (x + 4, 41)], fill=body)
    glow = img.filter(ImageFilter.GaussianBlur(1))
    out = Image.alpha_composite(glow, img)
    save(out, "entities", "player.png")


def shade():
    """Враг-тень: тёмный сгусток с красными глазами, 32x32."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([3, 4, 29, 30], fill=(18, 10, 24, 235))
    for x in range(3, 29, 6):
        d.polygon([(x, 24), (x + 3, 32), (x + 6, 24)], fill=(18, 10, 24, 235))
    d.ellipse([10, 12, 14, 16], fill=(230, 40, 50, 255))
    d.ellipse([19, 12, 23, 16], fill=(230, 40, 50, 255))
    save(img, "entities", "shade.png")


def shard():
    img = Image.new("RGBA", (16, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(8, 0), (15, 10), (8, 19), (1, 10)], fill=(120, 230, 255, 255))
    d.polygon([(8, 2), (12, 10), (8, 10)], fill=(220, 250, 255, 255))
    save(img, "entities", "shard.png")


def note():
    img = Image.new("RGBA", (18, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(1, 1), (17, 3), (16, 21), (2, 20)], fill=(225, 210, 175, 255))
    for y in (6, 10, 14):
        d.line([4, y, 14, y + 1], fill=(120, 100, 80, 255))
    save(img, "entities", "note.png")


def key():
    img = Image.new("RGBA", (20, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 1, 9, 10], outline=(200, 170, 90, 255), width=2)
    d.rectangle([8, 5, 19, 6], fill=(200, 170, 90, 255))
    d.rectangle([15, 7, 16, 10], fill=(200, 170, 90, 255))
    d.rectangle([18, 7, 19, 9], fill=(200, 170, 90, 255))
    save(img, "entities", "key.png")


def medallion():
    img = Image.new("RGBA", (16, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([8, 0, 8, 6], fill=(200, 170, 90, 255))
    d.ellipse([1, 6, 15, 20], fill=(210, 175, 80, 255), outline=(120, 90, 40, 255))
    d.ellipse([5, 10, 11, 16], fill=(150, 110, 50, 255))
    save(img, "entities", "medallion.png")


def page():
    img = Image.new("RGBA", (18, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(1, 1), (17, 1), (15, 8), (17, 14), (16, 21), (2, 21)], fill=(200, 185, 150, 255))
    for y in (5, 9, 13, 17):
        d.line([4, y, 13, y], fill=(130, 30, 40, 255))
    save(img, "entities", "page.png")


def door():
    img = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 8, 29, 63], fill=(70, 45, 35, 255))
    d.ellipse([2, 0, 29, 20], fill=(70, 45, 35, 255))
    d.line([16, 4, 16, 63], fill=(45, 28, 22, 255))
    d.ellipse([20, 34, 24, 38], fill=(200, 170, 90, 255))
    save(img, "entities", "door.png")


def altar():
    """Каменный алтарь с телом девочки, 64x40."""
    img = Image.new("RGBA", (64, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 20, 59, 39], fill=(80, 76, 90, 255))
    d.rectangle([0, 16, 63, 21], fill=(100, 96, 112, 255))
    # тело (лежит)
    d.ellipse([8, 6, 20, 17], fill=(230, 225, 220, 255))
    d.polygon([(18, 9), (56, 8), (56, 17), (18, 17)], fill=(235, 235, 240, 255))
    save(img, "entities", "altar.png")


def shrine():
    """Свеча-святилище (точка сохранения и прокачки), 32x48."""
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 34, 27, 47], fill=(70, 66, 80, 255))
    d.rectangle([2, 30, 29, 34], fill=(95, 90, 105, 255))
    d.rectangle([13, 14, 18, 30], fill=(230, 225, 200, 255))
    d.ellipse([12, 4, 19, 15], fill=(255, 200, 90, 255))
    d.ellipse([14, 8, 17, 14], fill=(255, 245, 200, 255))
    save(img, "entities", "shrine.png")


def candle():
    img = Image.new("RGBA", (10, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 9, 6, 21], fill=(225, 220, 195, 255))
    d.ellipse([2, 1, 7, 10], fill=(255, 190, 80, 255))
    save(img, "entities", "candle.png")


def spikes():
    img = Image.new("RGBA", (32, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x in range(0, 32, 8):
        d.polygon([(x, 14), (x + 4, 0), (x + 8, 14)], fill=(150, 150, 165, 255))
        d.line([x + 4, 0, x + 4, 14], fill=(200, 200, 215, 255))
    save(img, "entities", "spikes.png")


def light():
    """Мягкое радиальное пятно для 2D-света."""
    s = 256
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    px = img.load()
    for y in range(s):
        for x in range(s):
            r = math.hypot(x - s / 2, y - s / 2) / (s / 2)
            a = max(0.0, 1.0 - r) ** 2
            px[x, y] = (255, 255, 255, int(a * 255))
    save(img, "entities", "light.png")


def touch_buttons():
    """Круглые полупрозрачные кнопки для планшета, 128x128."""
    def base():
        img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.ellipse([4, 4, 123, 123], fill=(20, 16, 30, 140), outline=(200, 180, 140, 200), width=4)
        return img, d

    fg = (225, 215, 190, 230)
    img, d = base()
    d.polygon([(40, 64), (78, 36), (78, 92)], fill=fg)
    save(img, "ui", "btn_left.png")
    img, d = base()
    d.polygon([(88, 64), (50, 36), (50, 92)], fill=fg)
    save(img, "ui", "btn_right.png")
    img, d = base()
    d.polygon([(64, 34), (94, 74), (34, 74)], fill=fg)
    d.rectangle([54, 74, 74, 94], fill=fg)
    save(img, "ui", "btn_jump.png")
    img, d = base()
    for x in (38, 62):
        d.polygon([(x, 38), (x + 26, 64), (x, 90), (x + 10, 64)], fill=fg)
    save(img, "ui", "btn_dash.png")
    img, d = base()
    pts = []
    for i in range(16):
        ang = i * math.pi / 8
        r = 36 if i % 2 == 0 else 14
        pts.append((64 + r * math.cos(ang), 64 + r * math.sin(ang)))
    d.polygon(pts, fill=fg)
    save(img, "ui", "btn_attack.png")
    img, d = base()
    d.ellipse([44, 44, 84, 84], outline=fg, width=8)
    d.ellipse([58, 58, 70, 70], fill=fg)
    save(img, "ui", "btn_action.png")
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([4, 4, 91, 91], fill=(20, 16, 30, 140), outline=(200, 180, 140, 200), width=4)
    d.rectangle([32, 28, 42, 68], fill=fg)
    d.rectangle([54, 28, 64, 68], fill=fg)
    save(img, "ui", "btn_pause.png")


def heart():
    img = Image.new("RGBA", (24, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, 13, 13], fill=(180, 210, 255, 255))
    d.ellipse([10, 0, 23, 13], fill=(180, 210, 255, 255))
    d.polygon([(1, 9), (22, 9), (12, 21)], fill=(180, 210, 255, 255))
    save(img, "ui", "heart_full.png")
    img2 = Image.new("RGBA", (24, 22), (0, 0, 0, 0))
    a = img.split()[3]
    dim = Image.new("RGBA", (24, 22), (60, 60, 80, 200))
    img2.paste(dim, (0, 0), a)
    save(img2, "ui", "heart_empty.png")


def backgrounds():
    rnd = random.Random(7)
    w, h = 1280, 720

    def sky(top, bottom, moon):
        img = Image.new("RGBA", (w, h))
        d = ImageDraw.Draw(img)
        for y in range(h):
            t = y / h
            c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
            d.line([0, y, w, y], fill=c + (255,))
        if moon:
            glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            gd = ImageDraw.Draw(glow)
            gd.ellipse([930, 60, 1130, 260], fill=moon + (90,))
            glow = glow.filter(ImageFilter.GaussianBlur(30))
            img = Image.alpha_composite(img, glow)
            d = ImageDraw.Draw(img)
            d.ellipse([985, 115, 1075, 205], fill=moon + (255,))
        for _ in range(60):
            x, y = rnd.randrange(w), rnd.randrange(h // 2)
            d.point((x, y), fill=(200, 200, 230, 255))
        return img

    def skyline(color, base_y, spires, seed):
        r = random.Random(seed)
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([0, base_y, w, h], fill=color)
        x = 0
        while x < w:
            bw = r.randint(60, 160)
            bh = r.randint(40, 200)
            d.rectangle([x, base_y - bh, x + bw, base_y], fill=color)
            if spires and r.random() < 0.6:
                cx = x + bw // 2
                d.polygon([(cx - 16, base_y - bh), (cx, base_y - bh - r.randint(60, 160)), (cx + 16, base_y - bh)], fill=color)
            if r.random() < 0.5:
                tx = x + r.randint(0, bw)
                d.line([tx, base_y - bh, tx, base_y - bh - 40], fill=color, width=3)
                d.line([tx - 10, base_y - bh - 28, tx + 10, base_y - bh - 28], fill=color, width=3)
            x += bw + r.randint(0, 40)
        return img

    save(sky((10, 8, 22), (40, 22, 48), (230, 225, 210)), "backgrounds", "otherworld_sky.png")
    save(skyline((26, 16, 34, 255), 520, True, 1), "backgrounds", "otherworld_far.png")
    save(skyline((14, 8, 18, 255), 600, True, 2), "backgrounds", "otherworld_near.png")
    # Дом: тёмные обои с узором и окна с луной
    img = Image.new("RGBA", (w, h), (28, 22, 32, 255))
    d = ImageDraw.Draw(img)
    for x in range(0, w, 64):
        for y in range(0, h, 64):
            d.polygon([(x + 32, y + 8), (x + 44, y + 32), (x + 32, y + 56), (x + 20, y + 32)], outline=(40, 32, 46, 255))
    for wx in (200, 840):
        d.rectangle([wx, 160, wx + 200, 420], fill=(20, 24, 44, 255), outline=(60, 44, 40, 255), width=10)
        d.line([wx + 100, 160, wx + 100, 420], fill=(60, 44, 40, 255), width=8)
        d.line([wx, 290, wx + 200, 290], fill=(60, 44, 40, 255), width=8)
    save(img, "backgrounds", "house_wall.png")


def icon():
    img = Image.new("RGBA", (128, 128), (14, 10, 22, 255))
    d = ImageDraw.Draw(img)
    d.ellipse([70, 14, 110, 54], fill=(230, 225, 210, 255))
    girl = Image.open(os.path.join(ROOT, "entities", "player.png")).resize((48, 88), Image.NEAREST)
    img.alpha_composite(girl, (40, 30))
    img.save(os.path.join(ROOT, "..", "..", "icon.png"))


if __name__ == "__main__":
    tiles()
    ghost_girl()
    shade()
    shard()
    note()
    key()
    medallion()
    page()
    door()
    altar()
    shrine()
    candle()
    spikes()
    light()
    touch_buttons()
    heart()
    backgrounds()
    icon()
    print("Готово")
