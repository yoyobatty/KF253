"""Writes KFBFGLens.ase, the disc the BFG ball's gravity lens is drawn on (KFBFGLens). From Vanilla Extract's lens
(VXDemo Tools/lens.py), made smaller: a bubble round the ball, not the whole view.

A flat disc of rings in the YZ plane, facing +X, with the ball thought of at its middle. Where a point of it is, is
where the eye sees something; its texture coordinates are where that light came from, had there been no mass:

    from = seen - 1 / seen          (both in Einstein radii, along the same line out from the middle)

Outside the ring (seen = 1) things are pushed outward, on the ring is the one point straight behind the ball, drawn out
all the way round, and inside it is the far side, the other way up. An Einstein radius is 10 units of the model (the
game sizes it). From 4 to 8 radii the bending is brought to nothing, so the disc's rim cannot be seen. One small
triangle stands off at X = 400: the renderer sorts by the middle of a model's box, and by stretching the model along X
the game says how far away the lens is to count as being (the disc, at X = 0, stays where it is).

    python make_bfglens.py
"""
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))

RING = 10.0                     # model units to an Einstein radius
T_IN, T_FULL, T_OUT = 0.14, 4.0, 8.0
RINGS, AROUND = 56, 56
FAR = 400.0


def came_from(t):
    w = 1.0
    if t > T_FULL:
        s = max(0.0, (T_OUT - t) / (T_OUT - T_FULL))
        w = s * s * (3 - 2 * s)
    return t - w / t


def lens():
    verts, uvs, faces = [], [], []
    for i in range(RINGS + 1):
        t = T_IN * (T_OUT / T_IN) ** (i / RINGS)
        b = came_from(t)
        for j in range(AROUND):
            a = 2 * math.pi * j / AROUND
            verts.append((0.0, RING * t * math.cos(a), RING * t * math.sin(a)))
            uvs.append((b * math.cos(a), b * math.sin(a)))
    for i in range(RINGS):
        for j in range(AROUND):
            p = i * AROUND + j
            q = i * AROUND + (j + 1) % AROUND
            faces.append((p, p + AROUND, q + AROUND))
            faces.append((p, q + AROUND, q))
    mid = len(verts)
    verts.append((0.0, 0.0, 0.0))
    uvs.append((0.0, 0.0))
    for j in range(AROUND):
        faces.append((mid, j, (j + 1) % AROUND))
    k = len(verts)
    verts += [(FAR, 0.0, 0.0), (FAR, 0.5, 0.0), (FAR, 0.0, 0.5)]
    uvs += [(0.0, 0.0)] * 3
    faces.append((k, k + 1, k + 2))

    L = ['*3DSMAX_ASCIIEXPORT\t200',
         '*COMMENT "KFMod254 BFG gravity lens, written by make_bfglens.py"',
         '*MATERIAL_LIST {', '\t*MATERIAL_COUNT 1', '\t*MATERIAL 0 {', '\t\t*MATERIAL_NAME "Lens"',
         '\t\t*MAP_DIFFUSE {', '\t\t\t*BITMAP "C:\\KFBFGLens.bmp"', '\t\t\t*UVW_U_TILING 1.0', '\t\t\t*UVW_V_TILING 1.0',
         '\t\t}', '\t}', '}',
         '*GEOMOBJECT {', '\t*NODE_NAME "Lens"', '\t*MESH {',
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
    with open(os.path.join(HERE, 'KFBFGLens.ase'), 'w', newline='\r\n') as f:
        f.write('\n'.join(L) + '\n')
    print('KFBFGLens', len(verts), 'vertices,', len(faces), 'faces')


if __name__ == '__main__':
    lens()
