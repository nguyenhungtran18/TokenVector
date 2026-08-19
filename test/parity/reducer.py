# -*- coding: utf-8 -*-
"""Rut gon 1 ca loi ve dang NHO NHAT con GIU DUOC cung mot loai lech
(moc 8, buoc 1.2 cua ke hoach). Delta-debug TAT DINH, khong dung
hypothesis (hoan lai giai doan 1b khi van pham on dinh hon - xem ghi
chu trong plan).

Chien luoc: cau lenh dinh nghia trong `run()` la mot DAY CHUNK (mot cau
lenh top-level, ke ca cac dong long ben trong neu la if/for/while). Rut
gon = xoa dan tung chunk (1-minimal, lap den diem co dinh), roi thu co
hang so nguyen ve 0/1. KHONG doi lai LOAI lech giua cac lan thu - lech
kieu khac di nghia la da rut qua tay, phai lui lai.
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import arbiter as A  # noqa: E402


def _split_chunks(body_lines):
    """Body da o MUC THUT CO SO 4 khoang trang (moi dong, ke ca dong dau
    moi cau lenh top-level, deu co it nhat 4 khoang trang). Vi vay
    startswith('    ') KHONG phan biet duoc "dong moi" voi "dong long
    ben trong" - phai so DO SAU thut: > 4 la long, == 4 la cau lenh moi."""
    chunks = []
    cur = []
    for line in body_lines:
        indent = len(line) - len(line.lstrip(' '))
        stripped = line.strip()
        is_continuation_clause = stripped.startswith(('except', 'else', 'elif'))
        if (indent > 4 or is_continuation_clause) and cur:
            # 'except:'/'else:'/'elif ...:' o CUNG do sau 4 van la mot
            # PHAN cua cau lenh truoc (try/if), khong phai cau lenh moi -
            # xoa rieng no se pha cu phap (try khong except).
            cur.append(line)
        else:
            if cur:
                chunks.append(cur)
            cur = [line]
    if cur:
        chunks.append(cur)
    return chunks


def _assemble(helpers_src, chunks):
    body = []
    for c in chunks:
        body.extend(c)
    if not any('_out.append' in ln for c in chunks for ln in c):
        body += ['    try:', '        _out.append(str("end"))',
                 '    except:', '        _out.append("ERR")']
    lines = ['def run() -> "str":', '    _out = []'] + body
    lines.append('    return "|".join(_out)')
    src = helpers_src + '\n'.join(lines) + '\n'
    return src


def _used_helper_names(helpers_src):
    return re.findall(r'^def (\w+)\(', helpers_src, flags=re.M)


def _strip_unused_helpers(helpers_src, chunks):
    body_text = '\n'.join(ln for c in chunks for ln in c)
    names = _used_helper_names(helpers_src)
    blocks = helpers_src.split('\n\n\n') if helpers_src else []
    kept = []
    for name, block in zip(names, blocks):
        if re.search(r'\b%s\s*\(' % re.escape(name), body_text):
            kept.append(block)
    return ('\n\n\n'.join(kept) + '\n\n\n') if kept else ''


def reduce_case(source, expected_kind, tag='reduce', max_rounds=30):
    """source: chuong trinh day du (helpers + run()). Tra (nguon rut gon,
    so chunk con lai, so lan thu). Neu khong rut duoc gi (VAN lech ngay
    tu dau nhung khong the xoa bot), tra lai NGUYEN VAN."""
    lines = source.split('\n')
    def_run_idx = next(i for i, ln in enumerate(lines)
                        if ln.startswith('def run('))
    helpers_src = '\n'.join(lines[:def_run_idx])
    if helpers_src.strip():
        helpers_src = helpers_src.rstrip('\n') + '\n\n\n'
    else:
        helpers_src = ''
    body_lines = [ln for ln in lines[def_run_idx + 1:]
                  if ln.strip() and ln.strip() != '_out = []'
                  and not ln.strip().startswith('return "|".join')]
    chunks = _split_chunks(body_lines)

    tries = 0

    def still_fails(candidate_chunks):
        nonlocal tries
        if not candidate_chunks:
            return False
        tries += 1
        hs = _strip_unused_helpers(helpers_src, candidate_chunks)
        src = _assemble(hs, candidate_chunks)
        kind, detail, py, tkv = A.probe(src, tag='%s_%d' % (tag, tries))
        return kind == expected_kind

    changed = True
    rounds = 0
    while changed and rounds < max_rounds and len(chunks) > 1:
        changed = False
        rounds += 1
        i = 0
        while i < len(chunks):
            trial = chunks[:i] + chunks[i + 1:]
            if still_fails(trial):
                chunks = trial
                changed = True
            else:
                i += 1

    hs = _strip_unused_helpers(helpers_src, chunks)
    final_src = _assemble(hs, chunks)
    return final_src, len(chunks), tries


if __name__ == '__main__':
    sys.path.insert(0, str(Path(__file__).parent))
    import generator as G
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    src, meta = G.generate_program(seed)
    kind, detail, py, tkv = A.probe(src, tag='rmain')
    if not kind:
        print('seed %d: khong lech' % seed)
        sys.exit(0)
    print('lech ban dau:', kind, detail)
    reduced, n_chunks, tries = reduce_case(src, kind, tag='rmain')
    print('rut gon con %d chunk, %d lan thu:' % (n_chunks, tries))
    print(reduced)
