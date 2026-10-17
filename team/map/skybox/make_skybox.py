"""Equirectangular panorama -> six Roblox Sky faces (1024 px), with a crisp procedural star layer on top.
usage: python -I make_skybox.py <panorama> <outdir> [prefix]
Faces (verified in Studio with labelled test faces): Ft -Z, Bk +Z, Lf +X, Rt -X, none mirrored;
Up: image top -> +X, image right -> -Z; Dn: image top -> -X, image right -> -Z.
"""
import sys, os
import numpy as np
from PIL import Image

src, outdir = sys.argv[1], sys.argv[2]
prefix = sys.argv[3] if len(sys.argv) > 3 else "void"
N = 1024
os.makedirs(outdir, exist_ok=True)
pano = np.asarray(Image.open(src).convert("RGB"), dtype=np.float32) / 255.0
H, W, _ = pano.shape

def sample(dirs):
    x, y, z = dirs[..., 0], dirs[..., 1], dirs[..., 2]
    lon = np.arctan2(x, -z)               # 0 at -Z (front), increasing toward +X
    lat = np.arctan2(y, np.sqrt(x * x + z * z))
    u = (lon / (2 * np.pi) + 0.5) * W - 0.5
    v = (0.5 - lat / np.pi) * H - 0.5
    u0 = np.floor(u).astype(int); v0 = np.floor(v).astype(int)
    du = (u - u0)[..., None]; dv = (v - v0)[..., None]
    u1 = (u0 + 1) % W; u0 %= W
    v0c = np.clip(v0, 0, H - 1); v1c = np.clip(v0 + 1, 0, H - 1)
    a = pano[v0c, u0]; b = pano[v0c, u1]; c = pano[v1c, u0]; d = pano[v1c, u1]
    return (a * (1 - du) + b * du) * (1 - dv) + (c * (1 - du) + d * du) * dv

s = (np.arange(N) + 0.5) / N * 2 - 1
U, V = np.meshgrid(s, s)  # U: left->right, V: top->bottom
one = np.ones_like(U)
FACES = {
    "Ft": np.stack([U, -V, -one], -1),
    "Bk": np.stack([-U, -V, one], -1),
    "Lf": np.stack([one, -V, U], -1),
    "Rt": np.stack([-one, -V, -U], -1),
    "Up": np.stack([-V, one, -U], -1),
    "Dn": np.stack([V, -one, -U], -1),
}
rng = np.random.default_rng(1984)
for name, d in FACES.items():
    d = d / np.linalg.norm(d, axis=-1, keepdims=True)
    img = sample(d)
    # gentle grade: keep the nebula's violet/magenta, lift the darkest values a touch toward deep violet
    img = img * 1.05 + np.array([0.012, 0.006, 0.028], dtype=np.float32)
    # crisp stars: many faint 1px points, some brighter 2px ones with a soft halo, a few tinted warm or blue
    stars = np.zeros((N, N, 3), dtype=np.float32)
    n = 2600
    ys = rng.integers(0, N, n); xs = rng.integers(0, N, n)
    br = rng.power(4, n) * 0.9 + 0.1
    tint = rng.choice(3, n, p=[0.8, 0.12, 0.08])
    cols = np.array([[1, 1, 1], [1.0, 0.85, 0.7], [0.75, 0.85, 1.0]], dtype=np.float32)[tint]
    for y, x, b, c in zip(ys, xs, br, cols):
        stars[y, x] = np.maximum(stars[y, x], c * b)
        if b > 0.75:
            for dy, dx, k in ((0, 1, .45), (1, 0, .45), (0, -1, .45), (-1, 0, .45), (1, 1, .2), (-1, -1, .2), (1, -1, .2), (-1, 1, .2)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < N and 0 <= xx < N:
                    stars[yy, xx] = np.maximum(stars[yy, xx], c * b * k)
    img = 1 - (1 - np.clip(img, 0, 1)) * (1 - stars)  # screen blend
    out = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))
    path = os.path.join(outdir, f"{prefix}_{name}.png")
    out.save(path, optimize=True)
    print(path, os.path.getsize(path) // 1024, "KB")
