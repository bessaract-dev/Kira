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
    """Атлас 4x1: камень склепа, плита пола, полка-уступ, глубокая кладка."""
    rnd = random.Random(3)
    img = Image.new("RGBA", (T * 4, T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 0: камень склепа (холодный голубовато-серый)
    d.rectangle([0, 0, T - 1, T - 1], fill=(46, 54, 70))
    for y in (0, 16):
        d.line([0, y, T, y], fill=(26, 30, 42))
    for x, y in ((0, 0), (16, 0), (8, 16), (24, 16)):
        d.line([x, y, x, y + 16], fill=(26, 30, 42))
    for _ in range(25):
        d.point((rnd.randrange(T), rnd.randrange(T)), fill=(66, 76, 96))
    d.line([0, 0, T, 0], fill=(90, 110, 140))
    # 1: плиты катакомб с трещинами
    o = T
    d.rectangle([o, 0, o + T - 1, T - 1], fill=(40, 44, 58))
    d.rectangle([o, 0, o + T - 1, 3], fill=(70, 82, 104))
    d.line([o + 6, 6, o + 12, 14, o + 10, 22], fill=(24, 26, 36))
    d.line([o + 22, 10, o + 26, 26], fill=(24, 26, 36))
    for _ in range(20):
        d.point((o + rnd.randrange(T), rnd.randrange(4, T)), fill=(58, 64, 82))
    # 2: каменный уступ (односторонняя платформа, верхние 8 px)
    o = T * 2
    d.rectangle([o, 0, o + T - 1, 7], fill=(64, 72, 92))
    d.line([o, 0, o + T, 0], fill=(110, 126, 156))
    d.polygon([(o + 6, 8), (o + 16, 15), (o + 26, 8)], fill=(40, 46, 60))
    # 3: глубокая кладка
    o = T * 3
    d.rectangle([o, 0, o + T - 1, T - 1], fill=(26, 28, 38))
    for y in (0, 10, 21):
        d.line([o, y, o + T, y], fill=(16, 16, 24))
    for x, y in ((o + 10, 0), (o + 22, 10), (o + 6, 21), (o + 26, 21)):
        d.line([x, y, x, y + 10], fill=(16, 16, 24))
    save(img, "tiles.png")


def kira():
    """Кира-душа: рыжая короткая стрижка, круглые очки, бледное призрачное тело. 24x44."""
    img = Image.new("RGBA", (24, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (196, 222, 250, 225)
    d.polygon([(12, 18), (4, 40), (20, 40)], fill=body)              # рубашка/платье
    d.rectangle([8, 36, 10, 43], fill=body)                           # ноги
    d.rectangle([14, 36, 16, 43], fill=body)
    d.ellipse([6, 3, 20, 17], fill=(236, 220, 210, 240))             # лицо
    d.pieslice([5, 1, 21, 17], 180, 360, fill=(222, 96, 40, 255))    # рыжая стрижка
    d.rectangle([5, 8, 8, 13], fill=(222, 96, 40, 255))
    d.ellipse([12, 8, 16, 12], outline=(60, 70, 90, 255))           # очки
    d.ellipse([16, 8, 20, 12], outline=(60, 70, 90, 255))
    d.point((14, 10), fill=(40, 50, 80, 255))
    d.point((18, 10), fill=(40, 50, 80, 255))
    d.point((21, 6), fill=(120, 190, 255, 255))                      # голубые бабочки
    d.point((22, 7), fill=(120, 190, 255, 255))
    d.point((11, 6), fill=(120, 190, 255, 255))
    d.rectangle([6, 20, 7, 30], fill=body)                           # руки
    d.rectangle([17, 20, 18, 30], fill=body)
    glow = img.filter(ImageFilter.GaussianBlur(1))
    save(Image.alpha_composite(glow, img), "entities", "player.png")
    # Цепи поверх героини: оковы на руках и ногах с обрывками
    ch = Image.new("RGBA", (24, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(ch)
    iron = (150, 156, 170, 255)
    for x in (5, 16):
        d.rectangle([x, 27, x + 3, 29], fill=iron)
    for x in (7, 13):
        d.rectangle([x, 40, x + 4, 41], fill=iron)
    for i in range(4):
        d.ellipse([1 - i % 2, 30 + i * 3, 4 - i % 2, 33 + i * 3], outline=iron)
        d.ellipse([20 + i % 2, 30 + i * 3, 23 + i % 2, 33 + i * 3], outline=iron)
    save(ch, "entities", "chains.png")


def soul():
    """Душа-человек с белыми пустыми глазами, 24x40."""
    img = Image.new("RGBA", (24, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = (90, 110, 140, 200)
    d.ellipse([6, 1, 18, 14], fill=c)
    d.polygon([(4, 14), (20, 14), (22, 40), (2, 40)], fill=c)
    for x in range(2, 22, 5):
        d.polygon([(x, 36), (x + 2, 40), (x + 5, 36)], fill=(0, 0, 0, 0))
    d.ellipse([8, 6, 11, 9], fill=(250, 250, 255, 255))
    d.ellipse([13, 6, 16, 9], fill=(250, 250, 255, 255))
    d.line([10, 11, 14, 11], fill=(40, 50, 70, 255))
    glow = img.filter(ImageFilter.GaussianBlur(1.5))
    save(Image.alpha_composite(glow, img), "entities", "soul.png")


def skeleton():
    """Скелет в броне, 28x42."""
    img = Image.new("RGBA", (28, 42), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    bone = (215, 210, 195, 255)
    armor = (90, 96, 110, 255)
    d.ellipse([8, 1, 20, 13], fill=bone)
    d.rectangle([7, 0, 21, 5], fill=armor)                            # шлем
    d.rectangle([10, 6, 12, 8], fill=(20, 10, 10, 255))
    d.rectangle([16, 6, 18, 8], fill=(20, 10, 10, 255))
    d.rectangle([6, 14, 22, 28], fill=armor)                          # кираса
    d.line([14, 14, 14, 28], fill=(60, 64, 76, 255))
    d.rectangle([3, 15, 5, 27], fill=bone)
    d.rectangle([23, 15, 25, 27], fill=bone)
    d.rectangle([9, 29, 11, 41], fill=bone)
    d.rectangle([17, 29, 19, 41], fill=bone)
    d.rectangle([24, 8, 26, 30], fill=(140, 140, 150, 255))           # меч
    save(img, "entities", "skeleton.png")


def doll():
    """Маленькая заводная кукла, 20x26."""
    img = Image.new("RGBA", (20, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([4, 0, 16, 12], fill=(235, 225, 215, 255))
    d.ellipse([6, 4, 9, 7], fill=(10, 10, 10, 255))
    d.ellipse([11, 4, 14, 7], fill=(10, 10, 10, 255))
    d.line([7, 10, 13, 10], fill=(140, 20, 30, 255))
    d.polygon([(10, 12), (2, 24), (18, 24)], fill=(120, 30, 50, 255))
    d.rectangle([7, 24, 8, 25], fill=(60, 50, 50, 255))
    d.rectangle([11, 24, 12, 25], fill=(60, 50, 50, 255))
    d.rectangle([0, 15, 3, 16], fill=(180, 150, 80, 255))             # заводной ключ
    d.rectangle([0, 13, 1, 18], fill=(180, 150, 80, 255))
    save(img, "entities", "doll.png")


def hook_point():
    img = Image.new("RGBA", (20, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([8, 0, 11, 6], fill=(110, 116, 130, 255))
    d.ellipse([2, 6, 17, 21], outline=(170, 176, 190, 255), width=3)
    save(img, "entities", "hook_point.png")


def chain_link():
    """Одно звено цепи (тайлится вдоль линии хлыста/броска/крюка), 8x6."""
    img = Image.new("RGBA", (8, 6), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, 7, 5], outline=(175, 182, 198, 255), width=2)
    save(img, "entities", "chain_link.png")


def chaser():
    """Стена тьмы с белыми глазами для погони, 96x256 (тянется по высоте уровня)."""
    rnd = random.Random(11)
    img = Image.new("RGBA", (96, 256), (0, 0, 0, 0))
    px = img.load()
    for y in range(256):
        for x in range(96):
            a = min(1.0, (96 - x) / 60.0) if x > 36 else 1.0
            px[x, y] = (8, 6, 16, int(a * 235))
    d = ImageDraw.Draw(img)
    for _ in range(14):
        x, y = rnd.randrange(20, 70), rnd.randrange(8, 248)
        d.ellipse([x, y, x + 3, y + 3], fill=(240, 240, 255, 255))
        d.ellipse([x + 6, y, x + 9, y + 3], fill=(240, 240, 255, 255))
    save(img, "entities", "chaser.png")


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


def door():
    img = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 8, 29, 63], fill=(30, 34, 46, 255))
    d.ellipse([2, 0, 29, 20], fill=(30, 34, 46, 255))
    for x in range(6, 29, 6):
        d.line([x, 4, x, 63], fill=(120, 126, 140, 255), width=2)
    d.line([2, 30, 29, 30], fill=(120, 126, 140, 255), width=2)
    save(img, "entities", "door.png")


def altar():
    """Каменный саркофаг с телом Киры, 64x40."""
    img = Image.new("RGBA", (64, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 20, 59, 39], fill=(80, 76, 90, 255))
    d.rectangle([0, 16, 63, 21], fill=(100, 96, 112, 255))
    # тело (лежит)
    d.ellipse([8, 6, 20, 17], fill=(236, 222, 212, 255))
    d.pieslice([6, 4, 18, 18], 90, 270, fill=(222, 96, 40, 255))
    d.polygon([(18, 9), (56, 8), (56, 17), (18, 17)], fill=(150, 170, 200, 255))
    save(img, "entities", "altar.png")


def shrine():
    """Голубое пламя (точка сохранения и прокачки), 32x48."""
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 34, 27, 47], fill=(70, 66, 80, 255))
    d.rectangle([2, 30, 29, 34], fill=(95, 90, 105, 255))
    d.rectangle([13, 14, 18, 30], fill=(230, 225, 200, 255))
    d.ellipse([12, 4, 19, 15], fill=(90, 170, 255, 255))
    d.ellipse([14, 8, 17, 14], fill=(220, 240, 255, 255))
    save(img, "entities", "shrine.png")


def candle():
    img = Image.new("RGBA", (10, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 9, 6, 21], fill=(200, 200, 210, 255))
    d.ellipse([2, 1, 7, 10], fill=(255, 255, 255, 255))
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
        d.ellipse([4, 4, 123, 123], fill=(12, 18, 30, 140), outline=(150, 190, 230, 200), width=4)
        return img, d

    fg = (210, 228, 245, 230)
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
    # хлыст: дуга из звеньев
    img, d = base()
    for i in range(7):
        a = math.pi * (0.9 + i * 0.13)
        x, y = 64 + 34 * math.cos(a), 74 + 34 * math.sin(a)
        d.ellipse([x - 6, y - 4, x + 6, y + 4], outline=fg, width=3)
    save(img, "ui", "btn_whip.png")
    # бросок: прямая цепь со стрелкой
    img, d = base()
    for x in range(30, 80, 12):
        d.ellipse([x, 59, x + 12, 69], outline=fg, width=3)
    d.polygon([(82, 50), (100, 64), (82, 78)], fill=fg)
    save(img, "ui", "btn_throw.png")
    # крюк
    img, d = base()
    d.line([64, 30, 64, 70], fill=fg, width=6)
    d.arc([40, 52, 88, 100], 0, 180, fill=fg, width=6)
    d.polygon([(84, 76), (94, 68), (92, 82)], fill=fg)
    d.polygon([(44, 76), (34, 68), (36, 82)], fill=fg)
    save(img, "ui", "btn_hook.png")
    img, d = base()
    d.ellipse([44, 44, 84, 84], outline=fg, width=8)
    d.ellipse([58, 58, 70, 70], fill=fg)
    save(img, "ui", "btn_action.png")
    img = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([4, 4, 91, 91], fill=(12, 18, 30, 140), outline=(150, 190, 230, 200), width=4)
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
    w, h = 1280, 720

    def gradient(top, bottom):
        img = Image.new("RGBA", (w, h))
        d = ImageDraw.Draw(img)
        for y in range(h):
            t = y / h
            d.line([0, y, w, y], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
        return img

    def arches(color, top, width, seed, niches):
        """Ряд готических арок (силуэт стены склепа) с нишами для черепов."""
        r = random.Random(seed)
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([0, 0, w, h], fill=color)
        for x in range(0, w, width):
            hole = (0, 0, 0, 0)
            ax0, ax1 = x + width * 0.18, x + width * 0.82
            d.rectangle([ax0, top + (ax1 - ax0) / 2, ax1, h], fill=hole)
            d.pieslice([ax0, top, ax1, top + (ax1 - ax0)], 180, 360, fill=hole)
            if niches:
                for ny in range(top + 40, h - 60, 70):
                    for nx in (x + 6, x + width - 26):
                        if r.random() < 0.35:
                            shade = tuple(int(c * 0.6) for c in color[:3]) + (255,)
                            bone = tuple(min(255, int(c * 2.2) + 20) for c in color[:3]) + (255,)
                            d.pieslice([nx, ny, nx + 20, ny + 20], 180, 360, fill=shade)
                            d.rectangle([nx, ny + 10, nx + 20, ny + 26], fill=shade)
                            d.ellipse([nx + 5, ny + 10, nx + 15, ny + 20], fill=bone)
                            d.rectangle([nx + 7, ny + 19, nx + 13, ny + 22], fill=bone)
                            d.point((nx + 8, ny + 14), fill=shade)
                            d.point((nx + 12, ny + 14), fill=shade)
        return img

    # Склеп: холодный голубой
    save(gradient((8, 14, 26), (18, 32, 52)), "backgrounds", "crypt_back.png")
    save(arches((22, 30, 46, 255), 160, 320, 1, False), "backgrounds", "crypt_far.png")
    save(arches((12, 16, 26, 255), 260, 420, 2, True), "backgrounds", "crypt_near.png")
    # Катакомбы: голубой с фиолетовыми отсветами
    save(gradient((10, 10, 24), (34, 22, 50)), "backgrounds", "catacombs_back.png")
    save(arches((26, 22, 42, 255), 120, 240, 3, True), "backgrounds", "catacombs_far.png")
    # Глубины: тьма с красным
    save(gradient((14, 4, 10), (50, 10, 20)), "backgrounds", "depths_back.png")
    save(arches((30, 10, 18, 255), 200, 360, 4, True), "backgrounds", "depths_far.png")

    # Туман: мягкие пятна, бесшовный по горизонтали
    fog = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(fog)
    r = random.Random(9)
    for _ in range(40):
        x, y = r.randrange(w), r.randrange(h // 3, h)
        rx, ry = r.randint(80, 220), r.randint(30, 70)
        for dx in (-w, 0, w):
            d.ellipse([x + dx - rx, y - ry, x + dx + rx, y + ry], fill=(200, 220, 255, 26))
    save(fog.filter(ImageFilter.GaussianBlur(24)), "backgrounds", "fog.png")


def icon():
    img = Image.new("RGBA", (128, 128), (10, 16, 28, 255))
    d = ImageDraw.Draw(img)
    glow = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([24, 14, 104, 114], fill=(90, 160, 255, 90))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(14)))
    girl = Image.open(os.path.join(ROOT, "entities", "player.png")).resize((48, 88), Image.NEAREST)
    chains = Image.open(os.path.join(ROOT, "entities", "chains.png")).resize((48, 88), Image.NEAREST)
    img.alpha_composite(girl, (40, 22))
    img.alpha_composite(chains, (40, 22))
    img.save(os.path.join(ROOT, "..", "..", "icon.png"))


if __name__ == "__main__":
    tiles()
    kira()
    soul()
    skeleton()
    doll()
    hook_point()
    chain_link()
    chaser()
    shard()
    note()
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
