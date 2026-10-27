"""Writes the pictures the Void Executioner's blink lays over its wielder's view (HUDKillingFloor.DrawVoidWarp):

  ../Textures/KFWarpLines.tga     streaks rushing out from the middle: bright where a streak is, clear in the middle and
                                  at the rim; drawn added and tinted, grown as it fades
  ../Textures/KFWarpVignette.tga  a dark violet edge, clear in the middle
  ../Textures/KFWarpEdge.tga      the Executioner cut's air warp (KFAxeSlashWarp) shown only along the band it bends,
                                  fading out on either side (its picture is never quite the scene: a box showed)
  ../Textures/KFLensEdge.tga      the BFG lens (KFBFGLens) shown only in its strongly bent middle, round

    python make_warp.py
"""
import math
import os
import random
import struct

HERE = os.path.dirname(os.path.abspath(__file__))


def smooth(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def tga(name, w, h, px):
    head = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x08)
    with open(os.path.join(HERE, '..', 'Textures', name), 'wb') as f:
        f.write(head + bytes(px))
    print(name, w, 'x', h)


def lines(n=512, bins=140):
    random.seed(27)
    power = [0.0] * bins
    reach = [0.0] * bins
    for i in range(bins):
        if random.random() < 0.55:
            power[i] = 0.35 + 0.65 * random.random() ** 0.6
            reach[i] = 0.30 + 0.35 * random.random()
    px = bytearray()
    for y in range(n - 1, -1, -1):
        for x in range(n):
            dx, dy = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            r = math.hypot(dx, dy)
            a = (math.atan2(dy, dx) / (2 * math.pi) + 1.0) % 1.0
            f = a * bins
            i = int(f) % bins
            # (thin in the middle of each bin)
            across = 1.0 - abs((f - int(f)) - 0.5) * 2
            v = power[i] * across ** 1.6 * smooth(reach[i], reach[i] + 0.25, r) * (1 - smooth(0.95, 1.15, r))
            c = max(0, min(255, int(255 * v)))
            px += bytes((c, c, c, c))
    tga('KFWarpLines.tga', n, n, px)


def vignette(n=256):
    px = bytearray()
    for y in range(n - 1, -1, -1):
        for x in range(n):
            dx, dy = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            r = math.hypot(dx, dy)
            a = int(235 * smooth(0.45, 1.05, r))
            px += bytes((70, 0, 40, a))
    tga('KFWarpVignette.tga', n, n, px)


def edges(n=128):
    # the warp's picture only where it bends the view: a band along the blade's curve (KFAxeSlashWarp's disc: y across
    # it, 1.35 each way; z, 0.6 each way; the bend lies within about 0.3 of z = 0.05 - 0.12 y^2), the same both ways
    # in z so that it fits however the picture is turned; the lens's only in its strongly bent middle
    rect = bytearray()
    round_ = bytearray()
    for y in range(n - 1, -1, -1):
        for x in range(n):
            u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
            wy, wz = u * 1.35, v * 0.6
            reach = 0.22 + 0.12 * wy * wy
            a = (1 - smooth(0.9, 1.3, abs(wy))) * (1 - smooth(reach, reach + 0.16, abs(wz)))
            rect += bytes((255, 255, 255, int(255 * a)))
            r = math.hypot(u, v)
            round_ += bytes((255, 255, 255, int(255 * (1 - smooth(0.30, 0.62, r)))))
    tga('KFWarpEdge.tga', n, n, rect)
    tga('KFLensEdge.tga', n, n, round_)


if __name__ == '__main__':
    lines()
    vignette()
    edges()
