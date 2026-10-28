"""Writes the lockdown arena's wall (KFLockdownWall):

  KFLockdownWall.ase              an open tube, radius 100, height 100 from its foot, 48 sides, U round it 8 times, V up
  ../Textures/KFLockdownWall.tga  red energy: rising streaks and a lattice, bright at the foot and fading up (added)

    python make_lockdown.py
"""
import math
import os
import random
import struct

HERE = os.path.dirname(os.path.abspath(__file__))


def smooth(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def tga(name, w, h, rows):
    head = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x08)
    px = bytearray()
    for y in range(h - 1, -1, -1):
        for x in range(w):
            r, g, b, a = rows[y][x]
            px += bytes((max(0, min(255, int(b))), max(0, min(255, int(g))), max(0, min(255, int(r))), max(0, min(255, int(a)))))
    with open(os.path.join(HERE, '..', 'Textures', name), 'wb') as f:
        f.write(head + bytes(px))
    print(name, w, 'x', h)


def wall(w=128, h=256):
    rnd = random.Random(7)
    streaks = [(rnd.random(), 0.004 + 0.012 * rnd.random(), 0.4 + 0.6 * rnd.random()) for _ in range(26)]
    rows = []
    for y in range(h):
        row = []
        up = 1.0 - y / (h - 1)          # 0 at the foot (bottom of the picture), 1 at the top
        for x in range(w):
            u = x / w
            v = 0.0
            for (c, wd, p) in streaks:
                d = min(abs(u - c), 1 - abs(u - c))
                v = max(v, p * smooth(wd * 2.5, wd * 0.3, d))
            # a lattice of thin lines
            lat = max(smooth(0.012, 0.0, abs(((u * 8) % 1.0) - 0.5) / 8),
                      smooth(0.008, 0.0, abs(((up * 6 + 0.5 * (u * 8 % 1.0)) % 1.0) - 0.5) / 6))
            k = 0.25 + 0.75 * v + 0.35 * lat
            k *= (1.0 - smooth(0.0, 1.0, up)) ** 1.4      # fading up
            k += 0.9 * smooth(0.06, 0.0, up)              # bright foot
            r = 255 * min(1.0, k * 1.05)
            g = 255 * min(1.0, k * 0.30)
            b = 255 * min(1.0, k * 0.12)
            row.append((r, g, b, 255))
        rows.append(row)
    tga('KFLockdownWall.tga', w, h, rows)


def tube():
    n = 48
    verts, uvs, faces, tfaces = [], [], [], []
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        x, y = 100 * math.cos(a), 100 * math.sin(a)
        verts.append((x, y, 0.0))
        verts.append((x, y, 100.0))
        uvs.append((8.0 * i / n, 0.0))
        uvs.append((8.0 * i / n, 1.0))
    for i in range(n):
        a, b, c, d = 2 * i, 2 * i + 1, 2 * i + 2, 2 * i + 3
        faces += [(a, c, d), (a, d, b)]
        tfaces += [(a, c, d), (a, d, b)]
    out = ['*3DSMAX_ASCIIEXPORT\t200', '*COMMENT "KFLockdownWall, written by make_lockdown.py"', '*MATERIAL_LIST {',
           '\t*MATERIAL_COUNT 1', '\t*MATERIAL 0 {', '\t\t*MATERIAL_NAME "KFLockdownWall"', '\t\t*MAP_DIFFUSE {',
           '\t\t\t*BITMAP "C:\KFLockdownWallPic.bmp"', '\t\t\t*UVW_U_TILING 1.0', '\t\t\t*UVW_V_TILING 1.0', '\t\t}', '\t}', '}',
           '*GEOMOBJECT {', '\t*NODE_NAME "KFLockdownWall"', '\t*MESH {',
           '\t\t*MESH_NUMVERTEX %d' % len(verts), '\t\t*MESH_NUMFACES %d' % len(faces), '\t\t*MESH_VERTEX_LIST {']
    for i, (x, y, z) in enumerate(verts):
        out.append('\t\t\t*MESH_VERTEX %d\t%.4f\t%.4f\t%.4f' % (i, x, y, z))
    out.append('\t\t}')
    out.append('\t\t*MESH_FACE_LIST {')
    for i, (a, b, c) in enumerate(faces):
        out.append('\t\t\t*MESH_FACE %d:    A: %d B: %d C: %d AB:    1 BC:    1 CA:    1\t *MESH_SMOOTHING 1 \t*MESH_MTLID 0' % (i, a, b, c))
    out.append('\t\t}')
    out.append('\t\t*MESH_NUMTVERTEX %d' % len(uvs))
    out.append('\t\t*MESH_TVERTLIST {')
    for i, (u, v) in enumerate(uvs):
        out.append('\t\t\t*MESH_TVERT %d\t%.4f\t%.4f\t0.0000' % (i, u, v))
    out.append('\t\t}')
    out.append('\t\t*MESH_NUMTVFACES %d' % len(tfaces))
    out.append('\t\t*MESH_TFACELIST {')
    for i, (a, b, c) in enumerate(tfaces):
        out.append('\t\t\t*MESH_TFACE %d\t%d\t%d\t%d' % (i, a, b, c))
    out.append('\t\t}')
    out.append('\t}')
    out.append('\t*MATERIAL_REF 0')
    out.append('}')
    with open(os.path.join(HERE, 'KFLockdownWall.ase'), 'w', newline='\r\n') as f:
        f.write('\n'.join(out) + '\n')
    print('KFLockdownWall.ase')


if __name__ == '__main__':
    wall()
    tube()
