"""Собирает карты уровней (data/levels/*.json) из координат.

Уровень можно править и прямо в JSON: каждая строка "map" это ряд клеток 32x32.
Этот скрипт просто удобный способ нарисовать стартовые уровни. Запуск:
    python3 tools/build_levels.py
"""
import json
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "levels")


class Grid:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["." for _ in range(w)] for _ in range(h)]

    def fill(self, x0, y0, x1, y1, ch="#"):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = ch

    def put(self, x, y, ch):
        assert self.g[y][x] == ".", f"клетка ({x},{y}) уже занята: {self.g[y][x]}"
        self.g[y][x] = ch

    def rows(self):
        return ["".join(r) for r in self.g]


def level_01():
    g = Grid(64, 16)
    g.fill(0, 13, 63, 15)          # пол
    g.fill(0, 0, 63, 0)            # потолок
    g.fill(0, 0, 0, 15)            # стены
    g.fill(63, 0, 63, 15)
    g.fill(20, 1, 20, 9)           # стена спальни (проём снизу)
    g.fill(42, 1, 42, 9)           # стена гостиной
    # спальня
    g.put(3, 12, "P")
    g.put(5, 12, "t")
    g.put(8, 12, "a")
    g.fill(12, 11, 14, 11, "=")
    g.fill(15, 9, 18, 9, "=")
    g.put(16, 8, "c")
    g.put(17, 8, "b")
    g.put(13, 10, "o")
    g.put(15, 8, "o")
    g.put(10, 12, "w")             # окно
    # коридор
    g.put(24, 12, "S")
    g.put(29, 12, "m")
    g.put(33, 12, "^")
    g.put(34, 12, "^")
    g.put(33, 10, "o")
    g.put(34, 10, "o")
    g.fill(36, 11, 37, 11, "=")
    g.fill(38, 9, 41, 9, "=")
    g.put(39, 8, "o")
    g.put(40, 8, "o")
    g.put(31, 12, "q")             # часы
    # гостиная
    g.put(45, 12, "c")
    g.put(47, 12, "n")
    g.fill(49, 11, 51, 11, "=")
    g.fill(53, 9, 55, 9, "=")
    g.fill(56, 7, 59, 7, "=")
    g.fill(51, 5, 54, 5, "=")
    g.put(58, 6, "k")
    g.put(50, 10, "o")
    g.put(54, 8, "o")
    g.put(57, 6, "o")
    g.put(52, 4, "o")
    g.put(61, 12, "D")
    return {
        "name": "Дом, который не помнит тебя",
        "theme": {"tile": "wood", "background": "house", "darkness": "#5a5470"},
        "music": "",
        "map": g.rows(),
        "entities": {
            "t": {"type": "trigger", "text": "Где все? Почему так тихо... и почему мне совсем не холодно?"},
            "a": {"type": "note", "id": "diary"},
            "b": {"type": "note", "id": "spellbook"},
            "n": {"type": "note", "id": "mother_note"},
            "w": {"type": "inspect", "prompt": "Окно", "text": "За окном нет улицы. Только туман и далёкий колокольный звон."},
            "m": {"type": "inspect", "prompt": "Зеркало", "text": "В зеркале пустая комната. Тебя в нём нет."},
            "q": {"type": "inspect", "prompt": "Часы", "text": "Часы остановились на 3:13."},
            "k": {"type": "item", "id": "house_key"},
            "D": {"type": "exit", "look": "door", "prompt": "Открыть дверь", "target": "level_02",
                  "requires": ["house_key"], "locked": "Дверь заперта. Где-то в доме должен быть ключ."}
        }
    }


def level_02():
    g = Grid(120, 22)
    g.fill(0, 19, 119, 21)         # земля
    g.fill(0, 0, 0, 21)
    g.fill(119, 0, 119, 21)
    # яма с шипами
    g.fill(27, 19, 29, 20, ".")
    for x in (27, 28, 29):
        g.put(x, 20, "^")
    # стена, которую не перепрыгнуть без двойного прыжка
    g.fill(58, 15, 59, 18)
    # собор
    g.fill(88, 8, 89, 15)
    g.fill(88, 8, 118, 8)
    # старт
    g.put(3, 18, "P")
    g.put(5, 18, "t")
    g.put(8, 18, "S")
    # кладбище
    g.put(17, 18, "g")
    g.put(20, 18, "E")
    g.put(24, 18, "a")
    g.put(28, 16, "o")
    g.put(13, 18, "c")
    g.put(40, 18, "E")
    g.fill(43, 16, 46, 16, "=")
    g.put(44, 15, "o")
    g.put(45, 15, "o")
    g.fill(47, 13, 49, 13, "=")
    g.put(48, 12, "o")
    g.put(50, 18, "E")
    g.put(53, 18, "S")
    g.put(55, 18, "h")
    # за стеной
    g.put(63, 18, "c")
    g.put(66, 18, "m")
    g.put(70, 18, "E")
    g.put(74, 18, "^")
    g.put(75, 18, "^")
    g.put(74, 16, "o")
    g.fill(78, 16, 80, 16, "=")
    g.fill(81, 14, 83, 14, "=")
    g.fill(78, 12, 80, 12, "=")
    g.fill(81, 10, 83, 10, "=")
    g.put(79, 11, "o")
    g.put(82, 9, "p")
    g.put(83, 9, "c")
    # собор
    g.put(91, 18, "u")
    g.put(95, 18, "b")
    g.put(100, 18, "E")
    g.put(106, 18, "c")
    g.put(114, 18, "c")
    g.put(110, 18, "X")
    g.put(97, 16, "o")
    return {
        "name": "Изнанка",
        "theme": {"tile": "stone", "background": "otherworld", "darkness": "#4a3a5e"},
        "music": "",
        "map": g.rows(),
        "entities": {
            "t": {"type": "trigger", "text": "Это не наш двор. Колокол звонит где-то впереди... Кажется, он зовёт меня."},
            "g": {"type": "inspect", "prompt": "Надгробие", "text": "«Она искала дорогу домой». Имя стёрто."},
            "a": {"type": "note", "id": "whisper"},
            "h": {"type": "note", "id": "wall_hint"},
            "b": {"type": "note", "id": "mother_voice"},
            "m": {"type": "item", "id": "medallion"},
            "p": {"type": "item", "id": "torn_page"},
            "u": {"type": "trigger", "text": "Колокол замолчал. Впереди, на алтаре, кто-то лежит..."},
            "X": {"type": "exit", "look": "altar", "prompt": "Коснуться тела", "target": "ending",
                  "requires": ["medallion", "torn_page"],
                  "locked": "На алтаре лежишь... ты. Бледная, будто спишь. Чтобы вернуться, чего-то не хватает."}
        }
    }


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, data in (("level_01", level_01()), ("level_02", level_02())):
        with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(name)
        print("\n".join(data["map"]))
