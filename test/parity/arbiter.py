# -*- coding: utf-8 -*-
"""Chay 1 chuong trinh sinh boi generator.py qua CA HAI phia va PHAN LOAI
lech - khong nem, tra du lieu de fuzz.py/reducer.py quyet dinh tiep.

KHONG ghi .exe vao %TEMP% (bai hoc dat gia 2026-08-05, xem
_tkv_arbiter.py's _run_compiled): mot PE moi tinh, khong ky so, trong
%TEMP% do python.exe ghi ra roi chay NGAY la dung khuon dropper Defender
duoc huan luyen de bat (Wacatac.B!ml). Ghi trong cay repo
(test/_fuzz_tmp/) nhu moi test khac - noi nay chua bao gio bi chan.
"""
import base64
import hashlib
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tkv_compile import compile_tkv_cli  # noqa: E402

WORKDIR = ROOT / 'test' / '_fuzz_tmp'
WORKDIR.mkdir(exist_ok=True)

# Builtin DSL CHI CO trong TokenVector, khong ton tai duoi CPython thuan -
# 'exec' thang se NameError ngay lap tuc, tuc lech "gia" 100% lan nao cung
# co. Uy nhiem 1 dong sang thu vien chuan that (khuon tkvcalc_test.py:18,
# dung y het shim cua _tkv_arbiter.py's _make_namespace).
_DSL_SHIMS = {
    'md5_hex': lambda s: hashlib.md5(s.encode('utf-8')).hexdigest(),
    'sha256_hex': lambda s: hashlib.sha256(s.encode('utf-8')).hexdigest(),
    'base64_encode': lambda s: base64.b64encode(s.encode('utf-8')).decode('ascii'),
}


def run_cpython(source, entry='run'):
    ns = dict(_DSL_SHIMS)
    try:
        exec(compile(source, '<gen>', 'exec'), ns)
        return {'ok': True, 'value': str(ns[entry]()), 'error': None}
    except Exception as e:
        return {'ok': False, 'value': None,
                'error': '%s: %s' % (type(e).__name__, e)}


def _compile_once(src_path, exe_path, entry):
    compile_tkv_cli(src_path, exe_path, entry_name=entry)


def run_compiled(source, entry='run', tag='x'):
    """Bien dich + chay ban .exe. Retry 1 lan khi ghi/xoa file that bai
    ngay sau khi chay - dau hieu AV dang giu tay vao file vua tao (cung
    bai hoc %TEMP%, it hon nhung van co the xay ra trong cay repo)."""
    src_path = WORKDIR / ('gen_%s.tkv' % tag)
    exe_path = WORKDIR / ('gen_%s.exe' % tag)
    src_path.write_text(source, encoding='utf-8')
    last_err = None
    for attempt in range(2):
        try:
            if exe_path.exists():
                exe_path.unlink()
            _compile_once(src_path, exe_path, entry)
            break
        except Exception as e:
            last_err = e
            time.sleep(0.3)
    else:
        return {'compile_ok': False,
                'compile_error': '%s: %s' % (type(last_err).__name__, last_err),
                'run_ok': None, 'value': None, 'run_error': None}

    for attempt in range(2):
        try:
            r = subprocess.run([str(exe_path)], capture_output=True,
                               text=True, errors='replace', timeout=15,
                               cwd=str(WORKDIR))
            if r.returncode == 0:
                return {'compile_ok': True, 'compile_error': None,
                        'run_ok': True, 'value': r.stdout.rstrip('\r\n'),
                        'run_error': None}
            return {'compile_ok': True, 'compile_error': None,
                    'run_ok': False, 'value': None,
                    'run_error': (r.stderr or r.stdout)[-500:]}
        except subprocess.TimeoutExpired:
            return {'compile_ok': True, 'compile_error': None,
                    'run_ok': False, 'value': None, 'run_error': '(TIMEOUT)'}
        except PermissionError:
            time.sleep(0.3)
            continue
    return {'compile_ok': True, 'compile_error': None,
            'run_ok': False, 'value': None, 'run_error': '(PermissionError, AV?)'}


def cleanup(tag='x'):
    for suffix in ('.tkv', '.exe'):
        p = WORKDIR / ('gen_%s%s' % (tag, suffix))
        try:
            if p.exists():
                p.unlink()
        except OSError:
            pass


def classify(py, tkv):
    """None neu KHONG lech; nguoc lai ('loai', 'mo ta ngan')."""
    if py['ok'] and not tkv['compile_ok']:
        return 'compile_gap', tkv['compile_error']
    if py['ok'] and tkv['compile_ok'] and not tkv['run_ok']:
        return 'runtime_crash', tkv['run_error']
    if not py['ok'] and tkv['compile_ok'] and tkv['run_ok']:
        return 'tkv_silently_succeeds', 'py=%s tkv=%r' % (py['error'], tkv['value'])
    if py['ok'] and tkv['compile_ok'] and tkv['run_ok']:
        if py['value'] != tkv['value']:
            return 'value_mismatch', 'py=%r tkv=%r' % (py['value'], tkv['value'])
    return None


def probe(source, tag='x', entry='run', cleanup_after=True):
    """1 lan chay day du: sinh -> ca hai phia -> phan loai. Tra
    (kind_or_None, detail_or_None, py, tkv)."""
    py = run_cpython(source, entry)
    tkv = run_compiled(source, entry, tag)
    kind_detail = classify(py, tkv)
    if cleanup_after:
        cleanup(tag)
    if kind_detail is None:
        return None, None, py, tkv
    kind, detail = kind_detail
    return kind, detail, py, tkv
