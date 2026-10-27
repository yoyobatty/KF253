"""Writes what the Executioner's flying cut is drawn with (KFAxeSlash):

  KFAxeSlashBlade.ase   the blade: a curved ribbon standing up, its middle leading and its tips trailing back, 182
                        units across and 18 high (the game scales it to the cut's width). U runs along it, V across it.
  KFAxeSlashWarp.ase    the air bent along it (KFAxeSlashWarp): a flat disc facing the eye, in units of half the cut's
                        width (10 model units each, as the BFG lens), whose texture coordinates are where the light
                        seen there came from: drawn in toward a band along the blade's curve, so the view behind
                        the blade is stretched across it, with a shimmer along it; nothing moves at the rim.
  ../Textures/KFAxeSlashGlow.tga   the blade's glow, added: a white-hot edge in a crimson halo, fading to the tips.

    python make_axeslash.py
"""
import math
import os
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
FAR = 400.0


def write_ase(name, verts, uvs, faces, comment):
    L = ['*3DSMAX_ASCIIEXPORT\t200', '*COMMENT "%s"' % comment,
         '*MATERIAL_LIST {', '\t*MATERIAL_COUNT 1', '\t*MATERIAL 0 {', '\t\t*MATERIAL_NAME "%s"' % name,
         '\t\t*MAP_DIFFUSE {', '\t\t\t*BITMAP "C:\\%s.bmp"' % name, '\t\t\t*UVW_U_TILING 1.0', '\t\t\t*UVW_V_TILING 1.0',
         '\t\t}', '\t}', '}',
         '*GEOMOBJECT {', '\t*NODE_NAME "%s"' % name, '\t*MESH {',
         '\t\t*MESH_NUMVERTEX %d' % len(verts), '\t\t*MESH_NUMFACES %d' % len(faces), '\t\t*MESH_VERTEX_LIST {']
    for n, (x, y, z) in enumerate(verts):
        # (the game's importer mirrors X)
        L.append('\t\t\t*MESH_VERTEX    %d\t%.5f\t%.5f\t%.5f' % (n, -x, y, z))
    L += ['\t\t}', '\t\t*MESH_FACE_LIST {']
    for n, (a, b, c) in enumerate(faces):
        L.append('\t\t\t*MESH_FACE %4d:    A: %4d B: %4d C: %4d AB:    1 BC:    1 CA:    1\t *MESH_SMOOTHING 1 \t*MESH_MTLID 0'
                 % (n, a, b, c))
    L += ['\t\t}', '\t\t*MESH_NUMTVERTEX %d' % len(uvs), '\t\t*MESH_TVERTLIST {']
    for n, (u, v) in enumerate(uvs):
        # (and takes V as 1 - v)
        L.append('\t\t\t*MESH_TVERT %d\t%.6f\t%.6f\t0.0000' % (n, u, 1.0 - v))
    L += ['\t\t}', '\t\t*MESH_NUMTVFACES %d' % len(faces), '\t\t*MESH_TFACELIST {']
    for n, (a, b, c) in enumerate(faces):
        L.append('\t\t\t*MESH_TFACE %d\t%d\t%d\t%d' % (n, a, b, c))
    L += ['\t\t}', '\t}', '\t*MATERIAL_REF 0', '}']
    with open(os.path.join(HERE, name + '.ase'), 'w', newline='\r\n') as f:
        f.write('\n'.join(L) + '\n')
    print(name, len(verts), 'vertices,', len(faces), 'faces')


def grid_faces(cols, rows, base=0):
    faces = []
    for r in range(rows - 1):
        for c in range(cols - 1):
            p = base + r * cols + c
            faces.append((p, p + cols, p + cols + 1))
            faces.append((p, p + cols + 1, p + 1))
    return faces


def blade():
    R, A, H, SEG = 105.0, math.radians(60.0), 9.0, 40
    rows = (H, 0.0, -H)
    verts, uvs = [], []
    for r, z in enumerate(rows):
        for i in range(SEG + 1):
            a = -A + 2 * A * i / SEG
            verts.append((R * math.cos(a) - R, R * math.sin(a), z))
            uvs.append((i / SEG, r / 2.0))
    write_ase('KFAxeSlashBlade', verts, uvs, grid_faces(SEG + 1, 3), 'KFMod254 Executioner cut, by make_axeslash.py')


def warp():
    UNIT = 10.0
    YS, ZS = 1.35, 0.6
    COLS, ROWS = 81, 41
    BAND, MAG = 0.30, 0.80

    def centre(y):
        return 0.05 - 0.12 * y * y

    def taper(y):
        t = min(1.0, max(0.0, (1.25 - abs(y)) / 0.35))
        return t * t * (3 - 2 * t)

    verts, uvs = [], []
    for r in range(ROWS):
        z = -ZS + 2 * ZS * r / (ROWS - 1)
        for c in range(COLS):
            y = -YS + 2 * YS * c / (COLS - 1)
            fy, fz = y, z
            d = z - centre(y)
            if abs(d) < BAND:
                p = (1 - (d / BAND) ** 2) ** 2
                m = MAG * p * taper(y)
                fz = centre(y) + d * (1 - m)
                fy = y + 0.10 * m * math.sin(9.0 * y)
            verts.append((0.0, UNIT * y, UNIT * z))
            uvs.append((fy, fz))
    faces = grid_faces(COLS, ROWS)
    k = len(verts)
    verts += [(FAR, 0.0, 0.0), (FAR, 0.5, 0.0), (FAR, 0.0, 0.5)]
    uvs += [(0.0, 0.0)] * 3
    faces.append((k, k + 1, k + 2))
    write_ase('KFAxeSlashWarp', verts, uvs, faces, 'KFMod254 Executioner cut warp, by make_axeslash.py')


def glow(w=256, h=64):
    body = bytearray()
    for yy in range(h - 1, -1, -1):
        v = (yy + 0.5) / h
        core = math.exp(-((v - 0.5) / 0.07) ** 2)
        halo = math.exp(-((v - 0.5) / 0.26) ** 2)
        for xx in range(w):
            u = (xx + 0.5) / w
            tip = math.sin(math.pi * u) ** 0.7
            c = core * tip
            g = halo * tip
            r = min(255, int(255 * (0.95 * c + 0.75 * g)))
            gg = min(255, int(255 * (0.92 * c + 0.10 * g)))
            b = min(255, int(255 * (0.88 * c + 0.08 * g)))
            body += bytes((b, gg, r))
    head = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, w, h, 24, 0x00)
    out = os.path.join(HERE, '..', 'Textures', 'KFAxeSlashGlow.tga')
    with open(out, 'wb') as f:
        f.write(head + bytes(body))
    print('KFAxeSlashGlow', w, 'x', h)


if __name__ == '__main__':
    blade()
    warp()
    glow()
