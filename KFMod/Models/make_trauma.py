"""Writes the pictures and the one mesh of the trauma system (KFWound, KFCutPiece, KFTrauma):

  ../Textures/KFWoundHole.tga     a round's way in: dark hole, torn rim, bruise, a run of blood down from it (modulated:
                                  128 grey changes nothing)
  ../Textures/KFWoundExit.tga     a round's way out: a ragged star of torn flesh round a dark hole
  ../Textures/KFWoundCavity.tga   blasted open at close range: a dark cavity with ribs showing, torn edge
  ../Textures/KFWoundGash.tga     a blade's cut: a long slit with red lips
  ../Textures/KFWoundFade.tga     the wounds' depth gradient: full from just in front of the projector, gone past the end
  ../Textures/KFCutEdge.tga       where a cut body is kept (alpha), along U: kept below the middle, with a torn line
  ../Textures/KFCutMeat.tga       raw meat, tiling: what a cut body shows inside
  ../Textures/KFCutSkull.tga      a head cut down the middle: skull, brain, the lot (alpha: the head's outline)
  ../Textures/KFCutTorso.tga      a body cut across: spine, ribs, gut, fat under the skin (alpha: the outline)
  ../Textures/KFCutRing.tga       a torso cylinder seen end on (alpha 0 inside the ellipse, 255 out): limits a cut
  ../Models/KFCutCap.ase          a flat square, two units across, facing +X: the cut faces wear it

    python make_trauma.py
"""
import math
import os
import random
import struct

HERE = os.path.dirname(os.path.abspath(__file__))


def smooth(a, b, x):
    if a == b:
        return 1.0 if x >= b else 0.0
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def mix(a, b, t):
    return a + (b - a) * t


def clamp(v):
    return max(0, min(255, int(round(v))))


def tga(name, w, h, rows):
    """rows[y][x] = (r, g, b, a), y = 0 at the top of the picture"""
    head = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x08)
    px = bytearray()
    # (the importer reads rows bottom up)
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = rows[y][x]
            px += bytes((clamp(b), clamp(g), clamp(r), clamp(a)))
    with open(os.path.join(HERE, '..', 'Textures', name), 'wb') as f:
        f.write(head + bytes(px))
    print(name, w, 'x', h)


# value noise, tiling on a period
class Noise:
    def __init__(self, seed, period=16):
        rnd = random.Random(seed)
        self.p = period
        self.v = [[rnd.random() for _ in range(period)] for _ in range(period)]

    def at(self, x, y):
        p = self.p
        x0, y0 = int(math.floor(x)), int(math.floor(y))
        fx, fy = x - x0, y - y0
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)
        a = self.v[y0 % p][x0 % p]
        b = self.v[y0 % p][(x0 + 1) % p]
        c = self.v[(y0 + 1) % p][x0 % p]
        d = self.v[(y0 + 1) % p][(x0 + 1) % p]
        return mix(mix(a, b, fx), mix(c, d, fx), fy)

    def fbm(self, x, y, octaves=4):
        t, amp, tot = 0.0, 0.5, 0.0
        for i in range(octaves):
            t += amp * self.at(x * (2 ** i), y * (2 ** i))
            tot += amp
            amp *= 0.5
        return t / tot


GREY = (128, 128, 128)


def blend(base, col, t):
    return tuple(mix(base[i], col[i], t) for i in range(3))


def wound_hole(n=128):
    nz = Noise(11)
    nz2 = Noise(12, 32)
    rnd = random.Random(5)
    drips = [(rnd.uniform(-0.05, 0.05), rnd.uniform(0.55, 0.85), rnd.uniform(0.012, 0.026)) for _ in range(3)]
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            r = math.hypot(u, v)
            ang = math.atan2(v, u)
            wob = 0.035 * (nz.at(math.cos(ang) * 2 + 8, math.sin(ang) * 2 + 8) - 0.5) * 2
            c = GREY
            # bruise
            c = blend(c, (104, 88, 96), smooth(0.62, 0.30, r) * 0.9)
            # blood smeared round it, and a run down from it (V grows downward in the picture)
            run = 0.0
            for (dx, length, width) in drips:
                if v > 0:
                    along = v / length
                    w = width * (1.0 - 0.6 * min(along, 1.0))
                    run = max(run, smooth(w * 1.6, w * 0.6, abs(u - dx - 0.02 * math.sin(v * 14))) * smooth(1.05, 0.75, along))
            run *= smooth(0.08, 0.18, r)
            c = blend(c, (72, 22, 20), 0.85 * run)
            # torn rim of raw flesh
            rim = smooth(0.30 + wob, 0.20 + wob, r)
            fl = nz2.fbm(u * 6 + 3, v * 6 + 3)
            c = blend(c, (150 + 40 * fl, 40 + 18 * fl, 36 + 12 * fl), rim)
            # the hole
            core = smooth(0.17 + wob, 0.10 + wob, r)
            c = blend(c, (22, 7, 7), core)
            # wet glint on the rim's inner edge
            gl = smooth(0.05, 0.0, abs(r - (0.16 + wob))) * (0.3 + 0.7 * smooth(-0.2, 0.6, -v))
            c = blend(c, (175, 80, 70), 0.5 * gl)
            # border left exactly neutral
            edge = min(x, y, n - 1 - x, n - 1 - y)
            if edge < 2:
                c = GREY
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFWoundHole.tga', n, n, rows)


def wound_exit(n=128):
    nz = Noise(21)
    nz2 = Noise(22, 32)
    rnd = random.Random(9)
    petals = rnd.randint(6, 8)
    phase = rnd.random() * 6.28
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            r = math.hypot(u, v)
            ang = math.atan2(v, u)
            star = 0.10 * max(0.0, math.cos(petals * ang + phase + 1.5 * (nz.at(math.cos(ang) * 1.5 + 4, math.sin(ang) * 1.5 + 4) - 0.5))) ** 2
            wob = 0.05 * (nz.at(math.cos(ang) * 2 + 2, math.sin(ang) * 2 + 7) - 0.5) * 2
            edge_r = 0.40 + star + wob
            c = GREY
            c = blend(c, (98, 80, 88), smooth(0.85, 0.45, r) * 0.85)
            # torn flesh flaps
            fl = nz2.fbm(u * 7 + 1, v * 7 + 9)
            flap = smooth(edge_r, edge_r - 0.10, r)
            c = blend(c, (165 + 50 * fl, 48 + 22 * fl, 40 + 14 * fl), flap)
            # white fat and bone flecks in the torn ring
            if 0.18 < r < edge_r - 0.04 and nz2.at(u * 22 + 5, v * 22 + 5) > 0.78:
                c = blend(c, (225, 205, 175), 0.7)
            core = smooth(0.24 + wob, 0.14 + wob, r)
            c = blend(c, (18, 5, 5), core)
            edge = min(x, y, n - 1 - x, n - 1 - y)
            if edge < 2:
                c = GREY
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFWoundExit.tga', n, n, rows)


def wound_cavity(n=256):
    nz = Noise(31)
    nz2 = Noise(32, 32)
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            r = math.hypot(u, v * 1.1)
            ang = math.atan2(v, u)
            wob = 0.08 * (nz.at(math.cos(ang) * 2 + 1, math.sin(ang) * 2 + 2) - 0.5) * 2 + 0.03 * (nz.at(math.cos(ang) * 6 + 7, math.sin(ang) * 6 + 5) - 0.5)
            edge_r = 0.66 + wob
            c = GREY
            c = blend(c, (95, 78, 86), smooth(0.98, 0.62, r) * 0.8)
            fl = nz2.fbm(u * 5 + 2, v * 5 + 2)
            # torn edge of meat
            c = blend(c, (150 + 50 * fl, 42 + 20 * fl, 36 + 12 * fl), smooth(edge_r, edge_r - 0.08, r))
            # deep inside: dark meat, ribs across it
            inner = smooth(edge_r - 0.06, edge_r - 0.20, r)
            deep = (55 + 40 * fl, 14 + 10 * fl, 12 + 8 * fl)
            c = blend(c, deep, inner)
            # ribs: bands across the cavity, curving
            rib = 0.0
            for k in range(-2, 3):
                cy = 0.22 * k + 0.05 * u * u
                rib = max(rib, smooth(0.05, 0.02, abs(v - cy)))
            rib *= inner * smooth(0.95, 0.4, abs(u) / max(0.01, edge_r))
            c = blend(c, (215, 196, 170), 0.85 * rib)
            # darkest where it goes in deepest
            c = blend(c, (20, 6, 6), smooth(0.34, 0.06, r) * (1 - rib))
            edge = min(x, y, n - 1 - x, n - 1 - y)
            if edge < 2:
                c = GREY
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFWoundCavity.tga', n, n, rows)


def wound_gash(w=256, h=64):
    nz = Noise(41)
    nz2 = Noise(42, 32)
    rows = []
    for y in range(h):
        row = []
        for x in range(w):
            u, v = (x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1
            # tapering at both ends
            half = 0.62 * (1 - u * u) ** 0.7 + 0.04
            wob = 0.10 * (nz.at(u * 6 + 3, 0.5) - 0.5)
            d = abs(v - wob) / max(half, 0.01)
            c = GREY
            c = blend(c, (104, 86, 94), smooth(1.9, 1.0, d) * smooth(1.0, 0.85, abs(u)) * 0.8)
            fl = nz2.fbm(u * 9 + 4, v * 3 + 4)
            c = blend(c, (165 + 45 * fl, 46 + 20 * fl, 40 + 12 * fl), smooth(1.0, 0.75, d) * smooth(1.0, 0.92, abs(u)))
            c = blend(c, (24, 7, 7), smooth(0.45, 0.15, d) * smooth(0.98, 0.8, abs(u)))
            edge = min(x, y, w - 1 - x, h - 1 - y)
            if edge < 2:
                c = GREY
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFWoundGash.tga', w, h, rows)


def wound_fade(w=4, h=64):
    # V is depth along the projector: row 0 behind it, 1..62 along MaxTraceDistance, 63 past the end
    rows = []
    for y in range(h):
        if y == 0 or y >= 63:
            a = 0
        else:
            t = y / 62.0
            a = 255 * smooth(0.0, 0.06, t) * smooth(1.0, 0.70, t)
        rows.append([(255, 255, 255, a)] * w)
    tga('KFWoundFade.tga', w, h, rows)


def cut_edge(w=64, h=256):
    # U across the cut (kept where U < 0.5), V along it: the torn line wanders a little
    nz = Noise(51, 64)
    rows = []
    for y in range(h):
        row = []
        line = 0.5 + 0.10 * (nz.fbm(y / h * 16, 3.3, 3) - 0.5)
        for x in range(w):
            u = (x + 0.5) / w
            a = 255 if u < line else 0
            row.append((255, 255, 255, a))
        rows.append(row)
    tga('KFCutEdge.tga', w, h, rows)


def meat(n=128):
    nz = Noise(61, 16)
    nz2 = Noise(62, 32)
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = x / n * 16, y / n * 16
            f = nz.fbm(u, v, 4)
            g = nz2.fbm(x / n * 32, y / n * 32, 3)
            c = (95 + 70 * f, 18 + 22 * f, 16 + 16 * f)
            # marbling of fat
            fat = smooth(0.70, 0.78, g)
            c = blend(c, (205, 170, 140), 0.55 * fat)
            # wet dark blood in the low parts
            c = blend(c, (40, 6, 6), smooth(0.40, 0.25, f) * 0.8)
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFCutMeat.tga', n, n, rows)


def skull(n=256):
    # a head cut through: the outline an oval, skin and scalp, the skull's bone, then brain; the face side (U < 0)
    # has the jaw and the hollows
    nz = Noise(71, 32)
    nz2 = Noise(72, 32)
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            ang = math.atan2(v, u)
            wob = 0.035 * (nz.at(math.cos(ang) * 2 + 5, math.sin(ang) * 2 + 5) - 0.5) * 2
            r = math.hypot(u / 0.98, v / 0.92)
            out = 0.94 + wob
            if r > out:
                row.append((0, 0, 0, 0))
                continue
            c = (120, 30, 26)
            depth = out - r
            # skin and scalp
            c = blend(c, (165, 70, 60), smooth(0.05, 0.0, depth))
            # bone
            bone = smooth(0.04, 0.07, depth) * smooth(0.16, 0.12, depth)
            c = blend(c, (222, 206, 180), bone)
            # brain inside the bone, upper part; below it the face's meat and the dark of the nose and mouth
            brain = smooth(0.13, 0.17, depth) * smooth(0.30, 0.10, v + 0.12 * math.sin(u * 4.0) + 0.25 * u)
            fold = nz2.fbm(u * 9 + 2, v * 9 + 2, 3)
            sulci = smooth(0.06, 0.0, abs(math.sin(fold * 18.0)))
            bc = blend((205, 150, 150), (120, 60, 66), 0.6 * sulci)
            c = blend(c, bc, brain)
            low = smooth(0.13, 0.20, depth) * smooth(0.10, 0.30, v + 0.12 * math.sin(u * 4.0) + 0.25 * u)
            c = blend(c, (110, 24, 22), low)
            hollow = smooth(0.12, 0.0, math.hypot(u + 0.55, v - 0.15)) + smooth(0.10, 0.0, math.hypot(u + 0.45, v - 0.5))
            c = blend(c, (30, 6, 6), min(1.0, hollow))
            # blood running over it
            c = blend(c, (70, 8, 8), 0.35 * smooth(0.55, 0.75, nz.fbm(u * 4 + 9, v * 4 + 1, 3)))
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFCutSkull.tga', n, n, rows)


def torso(n=256):
    # a body cut across: oval, U across the body (left to right), V front (V < 0) to back (V > 0)
    nz = Noise(81, 32)
    nz2 = Noise(82, 32)
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            ang = math.atan2(v, u)
            wob = 0.04 * (nz.at(math.cos(ang) * 2.5 + 3, math.sin(ang) * 2.5 + 3) - 0.5) * 2
            r = math.hypot(u / 0.98, v / 0.80)
            out = 0.95 + wob
            if r > out:
                row.append((0, 0, 0, 0))
                continue
            depth = out - r
            f = nz2.fbm(u * 6 + 1, v * 6 + 1, 4)
            c = (115 + 45 * f, 26 + 16 * f, 22 + 12 * f)
            # skin, then yellow fat under it
            c = blend(c, (160, 72, 62), smooth(0.04, 0.0, depth))
            c = blend(c, (215, 182, 120), smooth(0.03, 0.05, depth) * smooth(0.11, 0.08, depth))
            # gut coils in the front half
            if v < 0.2:
                g = nz.fbm(u * 7 + 11, v * 7 + 3, 3)
                coil = smooth(0.08, 0.0, abs(math.sin(g * 20.0)))
                gut = blend((185, 105, 100), (120, 50, 52), coil)
                c = blend(c, gut, smooth(0.12, 0.22, depth) * smooth(0.2, -0.1, v))
            # the spine at the back: a round vertebra, its canal, the muscle either side
            sp = math.hypot(u / 0.16, (v - 0.48) / 0.14)
            c = blend(c, (225, 210, 185), smooth(1.0, 0.85, sp))
            c = blend(c, (60, 20, 20), smooth(0.35, 0.2, math.hypot(u / 0.05, (v - 0.62) / 0.05)))
            # ribs cut across, at the sides
            for sx in (-1, 1):
                rb = math.hypot((u - sx * 0.72) / 0.07, (v - 0.05) / 0.05)
                c = blend(c, (220, 200, 175), smooth(1.0, 0.7, rb))
            # dark blood pooled in it
            c = blend(c, (45, 6, 6), 0.45 * smooth(0.6, 0.8, nz.fbm(u * 3 + 5, v * 3 + 7, 3)))
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFCutTorso.tga', n, n, rows)


def sagittal(w=128, h=256):
    # a trunk cut down the middle, seen side on: U front (U < 0) to back (U > 0), V top (neck) to bottom (hips); the spine
    # a column of bones down the back, ribs cut along the chest, gut coils in the belly, the pelvis's bone low down
    nz = Noise(91, 32)
    nz2 = Noise(92, 32)
    rows = []
    for y in range(h):
        row = []
        for x in range(w):
            u, v = (x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1
            ang = math.atan2(v, u)
            wob = 0.05 * (nz.at(math.cos(ang) * 2 + 3, math.sin(ang) * 2 + 3) - 0.5) * 2
            r = math.hypot(u / 0.97, v / 0.97)
            out = 0.95 + wob
            if r > out:
                row.append((0, 0, 0, 0))
                continue
            depth = out - r
            f = nz2.fbm(u * 5 + 1, v * 9 + 1, 4)
            c = (110 + 45 * f, 24 + 16 * f, 20 + 12 * f)
            c = blend(c, (160, 72, 62), smooth(0.04, 0.0, depth))
            c = blend(c, (215, 182, 120), smooth(0.03, 0.05, depth) * smooth(0.10, 0.07, depth))
            # the spine down the back: blocks of bone with dark discs between
            sp = smooth(0.13, 0.09, abs(u - 0.62)) * smooth(0.98, 0.85, abs(v))
            disc = smooth(0.25, 0.0, abs(math.sin(v * 22.0)))
            c = blend(c, blend((225, 210, 185), (90, 40, 40), 0.6 * disc), sp)
            c = blend(c, (60, 20, 20), smooth(0.03, 0.0, abs(u - 0.48)) * smooth(0.95, 0.8, abs(v)))
            # ribs cut along the upper front, each a pale band slanting down to the front
            if v < 0.15 and u < 0.45:
                rb = smooth(0.06, 0.02, abs(math.sin((v + 0.35 * u) * 16.0)))
                c = blend(c, (220, 200, 175), 0.8 * rb * smooth(0.95, 0.6, -v + 0.2))
            # gut coils in the belly
            if v > 0.05:
                g = nz.fbm(u * 6 + 11, v * 6 + 3, 3)
                coil = smooth(0.08, 0.0, abs(math.sin(g * 20.0)))
                gut = blend((185, 105, 100), (120, 50, 52), coil)
                c = blend(c, gut, smooth(0.10, 0.20, depth) * smooth(0.05, 0.3, v) * smooth(0.5, 0.2, u))
            # pelvis bone low down
            c = blend(c, (215, 195, 170), smooth(0.08, 0.04, math.hypot((u - 0.25) / 1.6, v - 0.80)))
            c = blend(c, (45, 6, 6), 0.4 * smooth(0.6, 0.8, nz.fbm(u * 3 + 5, v * 3 + 7, 3)))
            row.append((c[0], c[1], c[2], 255))
        rows.append(row)
    tga('KFCutSagittal.tga', w, h, rows)


# ---- alpha-blended wounds (drawn unlit by the projector pass: kept dark so they never glow)
def wound_alpha(name, n, seed, core, rim, flaps, bruise, runs, ribs=False, gash=False, w=None, h=None):
    nz = Noise(seed)
    nz2 = Noise(seed + 1, 32)
    rnd = random.Random(seed)
    W = w or n
    H = h or n
    drips = [(rnd.uniform(-0.06, 0.06), rnd.uniform(0.55, 0.9), rnd.uniform(0.014, 0.03)) for _ in range(runs)]
    petals = rnd.randint(6, 8)
    phase = rnd.random() * 6.28
    rows = []
    for y in range(H):
        row = []
        for x in range(W):
            u, v = (x + 0.5) / W * 2 - 1, (y + 0.5) / H * 2 - 1
            if gash:
                half = 0.62 * max(0.0, 1 - u * u) ** 0.7 + 0.04
                wob = 0.10 * (nz.at(u * 6 + 3, 0.5) - 0.5)
                r = abs(v - wob) / max(half, 0.01) * 0.5 + 0.5 * smooth(0.85, 1.0, abs(u))
                ang = 0.0
            else:
                r = math.hypot(u, v)
                ang = math.atan2(v, u)
                r = r - 0.06 * (nz.at(math.cos(ang) * 2 + 8, math.sin(ang) * 2 + 8) - 0.5) * 2 - 0.025 * (nz2.at(math.cos(ang) * 5 + 2, math.sin(ang) * 5 + 2) - 0.5) * 2
                if flaps:
                    r = r - 0.09 * max(0.0, math.cos(petals * ang + phase + 1.5 * (nz.at(math.cos(ang) * 1.5 + 4, math.sin(ang) * 1.5 + 4) - 0.5))) ** 2
            fl = nz2.fbm(u * 6 + 3, v * 6 + 3)
            col = (0, 0, 0)
            a = 0.0
            # bruise: a faint dark stain
            b = smooth(bruise, bruise * 0.55, r)
            col = blend(col, (30, 10, 12), 1.0)
            a = max(a, 0.55 * b)
            # runs of blood down from it
            run = 0.0
            if not gash:
                for (dx, length, width) in drips:
                    if v > 0:
                        along = v / length
                        ww = width * (1.0 - 0.6 * min(along, 1.0))
                        run = max(run, smooth(ww * 1.6, ww * 0.6, abs(u - dx - 0.02 * math.sin(v * 14))) * smooth(1.05, 0.7, along))
                run *= smooth(core * 0.5, rim, r + 0.05)
            if run > 0.01:
                col = blend(col, (62, 8, 7), min(1.0, run * 1.4))
                a = max(a, 0.85 * run)
            # torn rim of meat
            m = smooth(rim, rim - 0.06, r)
            if m > 0.0:
                c2 = (46 + 34 * fl, 8 + 8 * fl, 7 + 5 * fl)
                if flaps and nz2.at(u * 22 + 5, v * 22 + 5) > 0.8 and r > core:
                    c2 = (150, 130, 105)
                col = blend(col, c2, m) if a < 0.05 else blend(col, c2, m)
                a = max(a, m)
            # ribs across a cavity
            if ribs:
                rib = 0.0
                for k in range(-2, 3):
                    cy = 0.2 * k + 0.05 * u * u
                    rib = max(rib, smooth(0.045, 0.018, abs(v - cy)))
                rib *= smooth(rim - 0.05, rim - 0.18, r)
                col = blend(col, (150, 132, 108), 0.9 * rib)
            # the hole
            k = smooth(core, core * 0.8, r)
            col = blend(col, (8, 2, 2), k * (0.0 if ribs and rib > 0.3 else 1.0))
            edge = min(x, y, W - 1 - x, H - 1 - y)
            if edge < 2:
                a = 0.0
            row.append((col[0], col[1], col[2], 255 * min(1.0, a)))
        rows.append(row)
    tga(name, W, H, rows)


def wound_rim(n=128, seed=101):
    # a hole's torn edge: clear inside half the radius (the hole itself, KFHoleBody), a ragged ring of raw meat and
    # bone flecks round it, a faint bruise beyond
    nz = Noise(seed)
    nz2 = Noise(seed + 1, 32)
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            r = math.hypot(u, v)
            ang = math.atan2(v, u)
            wob = 0.07 * (nz.at(math.cos(ang) * 2 + 3, math.sin(ang) * 2 + 3) - 0.5) * 2
            fl = nz2.fbm(u * 7 + 2, v * 7 + 2)
            a = 0.0
            col = (30, 10, 12)
            a = max(a, 0.45 * smooth(0.90, 0.64, r))
            ring = smooth(0.66 + wob * 0.6, 0.58 + wob * 0.6, r)
            if ring > 0:
                c2 = (52 + 36 * fl, 9 + 9 * fl, 8 + 6 * fl)
                if nz2.at(u * 30 + 5, v * 30 + 5) > 0.86:
                    c2 = (120, 105, 85)
                col = blend(col, c2, ring)
                a = max(a, ring)
            # darkest right at the hole's lip
            col = blend(col, (14, 3, 3), smooth(0.62, 0.52, r))
            if r < 0.5:
                a = 0.0
            edge = min(x, y, n - 1 - x, n - 1 - y)
            if edge < 2:
                a = 0.0
            row.append((col[0], col[1], col[2], 255 * min(1.0, a)))
        rows.append(row)
    tga('KFWoundRim.tga', n, n, rows)


def ring(n=128):
    # 0 inside the ellipse (U and V within half the picture's width of its middle), 255 outside
    rows = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            a = 0 if math.hypot(u, v) < 0.5 else 255
            row.append((255, 255, 255, a))
        rows.append(row)
    tga('KFCutRing.tga', n, n, rows)


def cap_ase():
    # a square in the YZ plane facing +X, two units across; the importer mirrors X and flips V
    path = os.path.join(HERE, 'KFCutCap.ase')
    verts = [(0, -1, -1), (0, 1, -1), (0, 1, 1), (0, -1, 1)]
    uvs = [(0, 0), (1, 0), (1, 1), (0, 1)]
    faces = [(0, 1, 2), (0, 2, 3)]
    out = []
    out.append('*3DSMAX_ASCIIEXPORT\t200')
    out.append('*COMMENT "KFCutCap, written by make_trauma.py"')
    out.append('*MATERIAL_LIST {')
    out.append('	*MATERIAL_COUNT 1')
    out.append('	*MATERIAL 0 {')
    out.append('		*MATERIAL_NAME "KFCutCap"')
    out.append('		*MAP_DIFFUSE {')
    out.append('			*BITMAP "C:\KFCutCapPic.bmp"')
    out.append('			*UVW_U_TILING 1.0')
    out.append('			*UVW_V_TILING 1.0')
    out.append('		}')
    out.append('	}')
    out.append('}')
    out.append('*GEOMOBJECT {')
    out.append('\t*NODE_NAME "KFCutCap"')
    out.append('\t*MESH {')
    out.append('\t\t*MESH_NUMVERTEX %d' % len(verts))
    out.append('\t\t*MESH_NUMFACES %d' % len(faces))
    out.append('\t\t*MESH_VERTEX_LIST {')
    for i, (x, y, z) in enumerate(verts):
        out.append('\t\t\t*MESH_VERTEX %d\t%.4f\t%.4f\t%.4f' % (i, x, y, z))
    out.append('\t\t}')
    out.append('\t\t*MESH_FACE_LIST {')
    for i, (a, b, c) in enumerate(faces):
        out.append('			*MESH_FACE %d:    A: %d B: %d C: %d AB:    1 BC:    1 CA:    1	 *MESH_SMOOTHING 1 	*MESH_MTLID 0' % (i, a, b, c))
    out.append('\t\t}')
    out.append('\t\t*MESH_NUMTVERTEX %d' % len(uvs))
    out.append('\t\t*MESH_TVERTLIST {')
    for i, (u, v) in enumerate(uvs):
        out.append('\t\t\t*MESH_TVERT %d\t%.4f\t%.4f\t0.0000' % (i, u, v))
    out.append('\t\t}')
    out.append('\t\t*MESH_NUMTVFACES %d' % len(faces))
    out.append('\t\t*MESH_TFACELIST {')
    for i, (a, b, c) in enumerate(faces):
        out.append('\t\t\t*MESH_TFACE %d\t%d\t%d\t%d' % (i, a, b, c))
    out.append('\t\t}')
    out.append('\t}')
    out.append('\t*MATERIAL_REF 0')
    out.append('}')
    with open(path, 'w', newline='\r\n') as f:
        f.write('\n'.join(out) + '\n')
    print('KFCutCap.ase')


if __name__ == '__main__':
    wound_alpha('KFWoundHole.tga', 128, 11, 0.27, 0.36, False, 0.66, 3)
    wound_alpha('KFWoundExit.tga', 128, 21, 0.30, 0.46, True, 0.88, 2)
    wound_alpha('KFWoundCavity.tga', 256, 31, 0.40, 0.70, True, 0.95, 4, ribs=True)
    wound_alpha('KFWoundGash.tga', 0, 41, 0.45, 0.85, False, 1.6, 0, gash=True, w=256, h=64)
    wound_fade()
    cut_edge()
    meat()
    skull()
    torso()
    sagittal()
    wound_rim()
    ring()
    cap_ase()
