# -*- coding: utf-8 -*-
"""Phan nhom module `compiler/il_features/` cho `build_tkvc.ps1`.

FILE NAY LA NGUON SU THAT, KHONG duoc sinh lai tu build_tkvc.ps1. Truoc day
no la mot heredoc trong .ps1, bi ghi de moi lan build - nen fix 1 module phai
sua trong .ps1 va kiem tra bang mat. Mot file that trong git de sua va xem
duoc.

## VAN DE THAT (2026-09-30) - doc truoc khi sua gi

Hai nhom:

- **CORE** - PyInstaller bien dich vao `tkvc.exe`. Module o nhom nay KHONG
  the `import il_features.<ten>` tu module LIBRARY luc chay: CORE da duoc
  dong goi duoi duong dan khac, nen ten do khong ton tai voi LIBRARY.
- **LIBRARY** - nap `dist/il_features/*.tkv` luc chay qua `plugin_loader.py`.

Phan nhom CU ghi: chi lay cac dong `from il_features.X import` trong
`il_codegen.tkv`. Sai o 2 cho:

1. `record_feature.tkv` import `control_flow`, nhung `record_feature` khong
   duoc `il_codegen.tkv` import truc tiep -> no rơi vao LIBRARY, lai import
   CORE. Loi luc chay: `No module named 'il_features.control_flow'`.
2. **Chiều nguoc lai cung sai**: module CORE import LIBRARY thi cung hong.

Ban `xoa staging roi build lai` lai hong ca compiler (gate 0/113). No chay
duoc truoc do **chi do may**: staging cu con giu module sai nhom tu lan phan
loai truoc.

## QUY TAC DUNG

Hai module bat buoc cung nhom **neu co import truc tiep hoac gian tiep** qua
nhau. Nen day la **thanh phan lien thong** cu do thi import, khong phai "import
cai gi tu il_codegen".

CORE = moi thanh phan lien thong co chua it nhat 1 module ma `il_codegen.tkv`
import truc tiep. Phan con lai = LIBRARY.

## CO CHE DANG KY (manifest) - `build/il_features_manifest.txt`

Neu can ep module vao nhom (vi du module moi ma khong ai import), them dong:

    core     module_a, module_b
    library  module_c

Dong nay CO TIEN do doc dat. Module co trong manifest khong bi tu dong suy.
Khong co manifest thi moi thu suy nhu tren.

## KIEM TRA - build FAIL som thay vi sinh exe hong

Sau khi phan nhom, script kiem tra lai:
- module nao bi thieu trong `compiler/il_features/` (import mot ten khong
  ton tai) -> FAIL, in ten;
- manifest co dong khong parse duoc -> FAIL;
- file nao khong thuoc nhom nao -> FAIL (khong bao gio "so sot im lang").
"""
import io
import os
import re
import sys

CORE = 'core'
LIBRARY = 'library'

_DEP_RE = re.compile(r'il_features\.(\w+)')
_DIRECT_RE = re.compile(r'(?m)^\s*from il_features\.(\w+) import')
_ONLY = re.compile(r'^\s*(\w+)\s*=\s*\{?\s*$|^\s*\{?\s*$|^\s*\}\s*$')


def read(path):
    with io.open(path, encoding='utf-8') as fh:
        return fh.read()


def all_modules(feat_dir):
    return sorted(f[:-4] for f in os.listdir(feat_dir) if f.endswith('.tkv'))


def deps_of(module, feat_dir, cache):
    """Tap module ma `module` tham chieu - BAT ky cho nao, khong chi dong
    dau. dung moi tham chieu vi do la mat; dong dau thi bo sot (dang gap:
    `file_io` -> `stdlib_sys` chi xuat hien trong comment)."""
    if module in cache:
        return cache[module]
    path = os.path.join(feat_dir, module + '.tkv')
    if not os.path.exists(path):
        cache[module] = set()
        return cache[module]
    body = read(path)
    found = set(_DEP_RE.findall(body))
    found.discard(module)
    cache[module] = found
    return found


def load_manifest(path, modules):
    """Doc `core`/`library` khai bao. Tra (pins, loi)."""
    pins, errs = {}, []
    if not os.path.exists(path):
        return pins, errs
    for lineno, raw in enumerate(read(path).split('\n'), 1):
        line = raw.split('#', 1)[0].strip()
        if not line:
            continue
        parts = line.split(None, 1)
        if len(parts) != 2 or parts[0] not in (CORE, LIBRARY):
            errs.append('dong %d: khong parse duoc %r (can "core a, b" hoac '
                        '"library c")' % (lineno, raw.strip()))
            continue
        group = parts[0]
        for name in re.split(r'[,\s]+', parts[1].strip()):
            name = name.strip()
            if not name:
                continue
            if name not in modules:
                errs.append('dong %d: module %r khong ton tai trong '
                            'compiler/il_features/' % (lineno, name))
                continue
            if name in pins and pins[name] != group:
                errs.append('dang %d: module %r bi khai bao 2 lan (%s va %s)'
                            % (lineno, name, pins[name], group))
            pins[name] = group
    return pins, errs


def resolve(root, feat_dir, il_codegen, manifest, verbose):
    modules = all_modules(feat_dir)
    known = set(modules)
    pins, errs = load_manifest(manifest, known)
    if errs:
        return None, None, errs

    cache = {}

    # 1) module ma il_codegen import truc tiep = hat nhat CORE
    seeds = set(_DIRECT_RE.findall(read(il_codegen)))

    # 1b) MANIFEST CO QUYEN TUYET DOI khi no khai bao it nhat 1 module CORE.
    # Ly do: lan toa thanh phan lien thong rat "logic", nhung SAI voi PyInstaller
    # - `tkv.py` nam o goc staging, CORE lai o `staging/compiler/il_features/`,
    # nen exe chi import duoc DUNG tap module il_codegen tro toi. Thu mo rong
    # CORE theo lien thong lam exe that `No module named 'il_features.X'`.
    # Vi vay khi nguoi da KHAI BAO tay trong manifest, tin no.
    pinned_core = set(n for n, g in pins.items() if g == CORE)
    pinned_lib = set(n for n, g in pins.items() if g == LIBRARY)

    # 2) thanh phan lien thong (hop nhat duong - vo huong)
    parent = dict((m, m) for m in modules)

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    for m in modules:
        for d in deps_of(m, feat_dir, cache):
            if d in known:          # import ten khong ton tai -> bao loi o buoc 3
                union(m, d)

    # 3) module import 1 ten KHONG ton tai -> loi that, phai bi bat
    for m in modules:
        for d in sorted(deps_of(m, feat_dir, cache)):
            if d not in known:
                errs.append('module %s.tkv import il_features.%s - file '
                            'khong ton tai (sot file?)' % (m, d))
    for d in sorted(seeds):
        if d not in known:
            errs.append('il_codegen.tkv import il_features.%s - file khong '
                        'ton tai (sot file?)' % d)
    if errs:
        return None, None, errs

    if pinned_core:
        # Da khai bao tay -> dung DUNG tap do, KHONG lan toa them.
        core_names = pinned_core
        core_names -= pinned_lib
    else:
        core_roots = set(find(s) for s in seeds)
        core_names = set(m for m in modules if find(m) in core_roots)
        core_names -= pinned_lib

    core_mods = sorted(m for m in modules if m in core_names)
    core = [m + '.tkv' for m in core_mods]
    library = sorted(m + '.tkv' for m in modules if m not in core_names)

    # THU TU TOPOLOGICAL (2026-09-30): build_tkvc.ps1 sinh file bootstrap
    # `import il_features.<module>` cho TUNG module CORE, va thu tu trong file
    # do la thu tu NAP. Module nao import module nao phai NAP TRUOC, vi khi
    # nap mot module, no chay `register_*` va mot so module (record_feature)
    # DUNG bang tra o THOI DIEM NAP. Import alphabet thi `record_feature` (r)
    # nap truoc `set_methods_batch2` (s) -> bang tra rong -> 5 test set/list/
    # record BUILDFAIL voi loi "chi dung duoc tren bien kieu record, string".
    # `dfs` sau day in module TRUOC moi module no phu thuoc.
    ordered, seen = [], set()

    def dfs(m, stack=()):
        if m in seen or m not in core_names or m in stack:
            return
        for d in sorted(deps_of(m, feat_dir, cache)):
            dfs(d, stack + (m,))
        seen.add(m)
        ordered.append(m)

    for m in core_mods:
        dfs(m)
    core = [m + '.tkv' for m in ordered]

    # 6) KIEM TRA: module nao bi THIEU / import ten khong ton tai -> FAIL (xac
    #    kiem o buoc 3).
    #
    #    KHONG con kiem "LIBRARY import CORE" (2026-09-30). Kiem do dung truoc
    #    khi co BOOTSTRAP. Bay gio build_tkvc.ps1 sinh
    #    `_il_features_bootstrap.py` noi `import il_features.X` cho TUNG module
    #    CORE, nen PyInstaller bien dich chung vao exe - CORE TRONG nhin thay
    #    duoc luc chay, va module LIBRARY import CORE binh thuong.
    #    Hinh thuc phai dung la: mot module LIBRARY ma KHONG import gi ca - no
    #    chi dua vao CORE qua bien dich truc tiep roi se chay, nhung lenh
    #    `register_*` cua no se KHONG chay (module chua duoc nap) - xem muc
    #    "BOOTSTRAP" trong ghi chu dau file va trong build_tkvc.ps1.
    return core, library, errs


def main():
    root = sys.argv[1]
    verbose = '--verbose' in sys.argv
    feat_dir = os.path.join(root, 'compiler', 'il_features')
    il_codegen = os.path.join(root, 'compiler', 'il_codegen.tkv')
    manifest = os.path.join(root, 'tools', 'il_features_manifest.txt')

    core, library, errs = resolve(root, feat_dir, il_codegen, manifest, verbose)
    if errs:
        sys.stderr.write('PHAI LOI PHAN NHOM (build dung lai, KHONG duoc bo qua):\n')
        for e in errs:
            sys.stderr.write('  - %s\n' % e)
        return 2
    sys.stdout.write('\n'.join(core))
    sys.stdout.write('\n---\n')
    sys.stdout.write('\n'.join(library))
    return 0


if __name__ == '__main__':
    sys.exit(main())
