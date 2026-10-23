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
    """Склеп: Кира по очереди осваивает хлыст, бросок и крюк."""
    g = Grid(90, 16)
    g.fill(0, 13, 89, 15)          # пол
    g.fill(0, 0, 89, 0)            # потолок
    g.fill(0, 0, 0, 15)
    g.fill(89, 0, 89, 15)
    g.put(3, 12, "P")
    g.put(5, 12, "T")
    g.put(8, 12, "N")
    g.put(11, 12, "S")
    g.put(14, 12, "c")
    g.put(17, 12, "W")             # цепь-хлыст
    g.put(24, 12, "e")
    g.put(29, 12, "e")
    g.put(33, 12, "^")
    g.put(34, 12, "^")
    g.put(36, 12, "c")
    g.put(39, 12, "B")             # бросок цепи
    g.fill(44, 1, 54, 10)          # низкий коридор
    g.put(52, 12, "d")
    g.put(56, 12, "R")
    g.fill(57, 10, 60, 10, "=")
    g.put(62, 12, "G")             # цепь-крюк
    g.fill(66, 13, 73, 15, ".")    # пропасть
    g.put(69, 8, "H")
    g.put(77, 12, "M")
    g.put(80, 12, "I")
    g.put(83, 12, "c")
    g.put(87, 12, "D")
    for x, y in ((20, 11), (26, 11), (33, 10), (34, 10), (47, 12), (59, 9), (60, 9), (70, 9), (79, 11), (13, 11)):
        g.put(x, y, "o")
    return {
        "name": "Склеп",
        "theme": {"tile": "crypt", "darkness": "#46506e", "parallax": [{"image": "res://assets/backgrounds/crypt/01_far.png", "factor": 0.05}, {"image": "res://assets/backgrounds/crypt/02_mid.png", "factor": 0.3}, {"image": "res://assets/backgrounds/crypt/03_ground.png", "factor": 0.6}, {"image": "res://assets/backgrounds/crypt/04_near_top.png", "factor": 1.3, "front": True}]},
        "music": "",
        "map": g.rows(),
        "entities": {
            "T": {"type": "trigger", "text": "Холодно... Хотя нет, вообще ничего не чувствую. И почему на мне цепи?! Просто красота."},
            "N": {"type": "note", "id": "black_book"},
            "W": {"type": "item", "id": "chain_whip"},
            "B": {"type": "item", "id": "chain_throw"},
            "G": {"type": "item", "id": "chain_hook"},
            "R": {"type": "candle", "color": "#ff3550"},
            "M": {"type": "note", "id": "scratches"},
            "I": {"type": "inspect", "prompt": "Надгробная плита", "text": "«Здесь спят те, кто не знает, что спит». Бр-р. Надеюсь, это не про меня."},
            "D": {"type": "exit", "look": "gate", "prompt": "Спуститься в катакомбы", "target": "level_02",
                  "requires": ["chain_whip", "chain_throw", "chain_hook"],
                  "locked": "Сначала надо разобраться с цепями. Вдруг внизу пригодятся."}
        }
    }


def level_02():
    """Катакомбы: буквы К-И-Р-А. Каждая разбивает цепь и забирает приём."""
    g = Grid(130, 18)
    g.fill(0, 15, 129, 17)
    g.fill(0, 0, 129, 0)
    g.fill(0, 0, 0, 17)
    g.fill(129, 0, 129, 17)
    g.put(3, 14, "P")
    g.put(6, 14, "S")
    g.put(8, 14, "T")
    g.put(11, 14, "N")
    g.put(14, 14, "U")
    g.put(17, 14, "k")
    g.put(20, 14, "c")
    g.put(24, 14, "1")             # К: нет хлыста
    g.put(30, 14, "e")
    g.fill(34, 15, 41, 17, ".")
    g.put(37, 10, "H")
    g.put(43, 14, "R")
    g.put(48, 14, "d")
    g.put(54, 14, "k")
    g.put(58, 14, "2")             # И: нет броска
    g.put(60, 14, "M")
    g.put(63, 14, "S")
    g.put(70, 14, "e")
    g.fill(74, 15, 81, 17, ".")
    g.put(77, 10, "H")
    g.put(84, 14, "V")
    g.put(86, 14, "e")
    g.fill(90, 12, 95, 12, "=")
    g.put(93, 14, "d")
    g.put(100, 14, "3")            # Р: нет крюка
    g.put(102, 14, "c")
    g.put(106, 14, "k")
    g.put(110, 14, "^")
    g.put(111, 14, "^")
    g.put(116, 14, "4")            # А: цепей больше нет
    g.put(119, 14, "R")
    g.put(126, 14, "D")
    for x, y in ((12, 13), (22, 13), (37, 12), (46, 13), (65, 13), (77, 12), (92, 11), (94, 11), (104, 13), (121, 13)):
        g.put(x, y, "o")
    return {
        "name": "Катакомбы",
        "theme": {"tile": "catacombs", "darkness": "#4a4468", "parallax": [{"image": "res://assets/textures/backgrounds/catacombs_back.png", "factor": 0.03, "color": "#d9d9ff"}, {"image": "res://assets/textures/backgrounds/catacombs_far.png", "factor": 0.2, "color": "#e6d9ff"}, {"image": "res://assets/textures/backgrounds/crypt_near.png", "factor": 0.4, "color": "#d9bfff"}]},
        "music": "",
        "map": g.rows(),
        "entities": {
            "T": {"type": "trigger", "text": "Кости, кости, кости. Тут хоть кто-нибудь живой есть? Ой. Глупый вопрос."},
            "U": {"type": "trigger", "text": "Скелет в доспехах. Наверняка мальчишка. Фу."},
            "N": {"type": "note", "id": "drawing"},
            "M": {"type": "note", "id": "warning"},
            "V": {"type": "trigger", "text": "Без броска страшновато. Ничего, я быстрая. Просто обойду их."},
            "R": {"type": "candle", "color": "#a050ff"},
            "1": {"type": "item", "id": "letter_k"},
            "2": {"type": "item", "id": "letter_i"},
            "3": {"type": "item", "id": "letter_r"},
            "4": {"type": "item", "id": "letter_a"},
            "D": {"type": "exit", "look": "gate", "prompt": "Бежать наверх", "target": "level_03",
                  "requires": ["letter_k", "letter_i", "letter_r", "letter_a"],
                  "locked": "Я ещё не вспомнила своё имя целиком."}
        }
    }


def level_03():
    """Глубины: без цепей, погоня тьмы, прыжки от стен, в конце тело Киры."""
    g = Grid(150, 20)
    g.fill(0, 17, 149, 19)
    g.fill(0, 0, 149, 0)
    g.fill(0, 0, 0, 19)
    g.fill(149, 0, 149, 19)
    g.put(4, 16, "P")
    g.put(1, 16, "C")
    g.put(6, 16, "T")
    g.put(9, 16, "R")
    for x in (14, 15, 22, 23):
        g.put(x, 16, "^")
    g.put(27, 16, "d")
    g.put(31, 16, "W")
    # первая шахта: заходим под левую стену и прыгаем от стен вверх
    g.fill(34, 5, 34, 14)
    g.fill(38, 7, 38, 16)
    g.put(45, 16, "S")
    g.put(52, 16, "e")
    g.fill(55, 14, 58, 14, "=")
    g.fill(61, 12, 64, 12, "=")
    g.put(60, 16, "e")
    g.fill(66, 17, 68, 19, ".")    # пропасть
    g.put(70, 16, "R")
    # вторая шахта, повыше
    g.fill(74, 3, 74, 14)
    g.fill(78, 5, 78, 16)
    g.put(86, 16, "k")
    g.put(90, 16, "^")
    g.put(91, 16, "^")
    g.put(96, 16, "S")
    g.put(98, 16, "N")
    g.put(104, 16, "d")
    g.fill(107, 17, 109, 19, ".")
    g.fill(113, 14, 116, 14, "=")
    g.put(115, 13, "e")
    g.put(120, 16, "^")
    g.put(121, 16, "^")
    g.put(126, 16, "R")
    g.put(132, 16, "c")
    g.put(140, 16, "c")
    g.put(144, 16, "X")
    for x, y in ((18, 15), (36, 8), (36, 12), (57, 13), (63, 11), (67, 14), (76, 6), (76, 10), (108, 14), (118, 15)):
        g.put(x, y, "o")
    return {
        "name": "Глубины",
        "theme": {"tile": "crypt", "darkness": "#5a3a4e", "fog_color": "#ffa0b4b3", "parallax": [{"image": "res://assets/textures/backgrounds/depths_back.png", "factor": 0.03, "color": "#ffe6f2"}, {"image": "res://assets/textures/backgrounds/depths_far.png", "factor": 0.2, "color": "#ffd9e6"}]},
        "music": "",
        "map": g.rows(),
        "entities": {
            "T": {"type": "trigger", "text": "Пол дрожит. Сзади что-то ползёт... Не оглядываться. БЕЖАТЬ!"},
            "W": {"type": "trigger", "text": "Стена! Без цепей я такая лёгкая... Может, получится отталкиваться от стен? Прыжок, прыжок!"},
            "R": {"type": "candle", "color": "#ff3550"},
            "N": {"type": "note", "id": "heartbeat"},
            "X": {"type": "exit", "look": "body", "prompt": "Подойти к телу", "target": "ending"}
        }
    }


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, data in (("level_01", level_01()), ("level_02", level_02()), ("level_03", level_03())):
        with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(name)
        print("\n".join(data["map"]))
