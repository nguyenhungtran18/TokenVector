# -*- coding: utf-8 -*-
"""Quet mot cay TokenVector va liet ke record nao khai field container
CHUA duoc gan trong __init__ (2026-09-29).

Dung khi compiler bao loi:
    class 'X': field 'y' kieu container ('list[str]') CHUA duoc gan trong __init__

Dung thu muc voi tham so nguon, KHONG gan thu muc mac dinh - de khong quet
nham vao file khong lien quan.

    python r'.\tools\scan_uninit_container_fields.py' r'D:\TokenVector.Inference'

Tai sao can cong cu: loi nay chi lo ra MOT truong hop moi lan build, ma
Inference co 19 truong hop, Data co 31. Quet het mot luc de biet het pham vi
thay vi sua tung cai mot.
""""""Quet Inference: record nao khai field container nhung __init__ khong gan.

Dung chinh quy tac moi cua compiler, nen ket qua nay la danh sach day du
phai sua - khong nen phat hien tung cai mot khi build.
"""
import ast
import io
import os
import re
import sys

base = sys.argv[1] if len(sys.argv) > 1 else r'D:\TokenVector.Inference'
CONTAINER = ('list[', 'dict[', 'set[')

rows = []
for root, dirs, fs in os.walk(base):
    dirs[:] = [x for x in dirs if x not in ('.git', 'build', 'dist', '__pycache__')]
    for f in sorted(fs):
        if not f.endswith('.tkv'):
            continue
        p = os.path.join(root, f)
        try:
            src = io.open(p, encoding='utf-8').read()
            tree = ast.parse(src)
        except Exception:
            continue
        for cls in [n for n in ast.walk(tree) if isinstance(n, ast.ClassDef)]:
            assigned = set()
            for st in cls.body:
                if isinstance(st, (ast.FunctionDef, ast.AsyncFunctionDef)) \
                        and st.name == '__init__':
                    for node in ast.walk(st):
                        tgt = None
                        if isinstance(node, ast.Assign) and node.targets:
                            tgt = node.targets[0]
                        elif isinstance(node, ast.AnnAssign):
                            tgt = node.target
                        if isinstance(tgt, ast.Attribute) \
                                and isinstance(tgt.value, ast.Name) \
                                and tgt.value.id == 'self':
                            assigned.add(tgt.attr)
            for st in cls.body:
                if not isinstance(st, ast.AnnAssign) or not isinstance(st.target, ast.Name):
                    continue
                ann = st.annotation
                if not isinstance(ann, ast.Constant) or not isinstance(ann.value, str):
                    continue
                dt = ann.value
                if not dt.startswith(CONTAINER):
                    continue
                if st.target.id in assigned:
                    continue
                rows.append((cls.name, st.target.id, dt,
                             p.replace(base + '\\', '')))

seen = set()
uniq = []
for r in rows:
    k = (r[0], r[1])
    if k in seen:
        continue
    seen.add(k)
    uniq.append(r)

print('  %d field container CHUA duoc gan trong __init__ (%d ban sao)'
      % (len(uniq), len(rows)))
by_class = {}
for c, fld, dt, p in uniq:
    by_class.setdefault((c, fld), dt)
for (c, fld), dt in sorted(by_class.items()):
    print('   %-22s .%-18s %s' % (c, fld, dt))
