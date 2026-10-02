"""BUOC 2.1 - cau noi giua compiler va ma TokenVector da bien dich.

TINH HUONG: compiler hien tai la chuong trinh CPython nen no KHONG the chua
truc tiep ma CIL trong mot file exe. Nhung no co the GOI mot chuong trinh
TokenVector da bien dich - va TokenVector da chung minh chay duoc (BUOC 0:
`system()` + P/Invoke khoi dong tien trinh khac, nhan exit code).

Cong nay CHI kiem CAU NOI. Dinh chinh xac cua lexer do `probe_many_files.py`
va `probe_real_file.py` lo - o day KHONG con ban tokenizer tham chieu thu hai
(da co va no da TRO LE khi lexer giu them chuoi/comment/toan tu/so thuc, bien
thanh mot nguon lech mau thu hai phai sua theo).

Kiem 4 thu:
  1. Bien dich `lexer_lib.tkv` thanh exe.
  2. Chay no voi 2 tham so (file vao / file ra).
  3. File ket qua doc duoc theo dinh dang `<do-dai>:<token>` va het bang EOF.
  4. Token cuoi cung la EOF, va co it nhat mot token that.

Chay: python tools\\compiler_tkv\\probe_bridge.py
"""
import io
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TKVC = os.path.join(ROOT, 'dist', 'tkvc.exe')
LEXER = os.path.join(HERE, 'lexer_lib.tkv')
TMP = tempfile.gettempdir()

sys.path.insert(0, HERE)
from probe_real_file import read_tokens  # noqa: E402


def main():
    if not os.path.exists(TKVC):
        sys.stderr.write('thieu %s - build tkvc truoc\n' % TKVC)
        return 2

    exe = os.path.join(TMP, 'tkv_lexer.exe')
    if os.path.exists(exe):
        os.remove(exe)
    r = subprocess.run([TKVC, 'build', LEXER, '--out', exe, '--entry', 'main'],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(exe):
        sys.stderr.write('build that bai:\n%s\n%s\n' % (r.stdout, r.stderr))
        return 1
    print('ok   build lexer.exe (%d KB)' % (os.path.getsize(exe) // 1024))

    src_in = os.path.join(TMP, 'lexer_sample.tkv')
    out = os.path.join(TMP, 'lexer_sample.tokens')
    sample = '# -*- coding: utf-8 -*-\ndef add(a: "i32", b: "i32") -> "i32":\n' \
             '    c = a + b\n    return c\n'
    io.open(src_in, 'w', encoding='utf-8', newline='').write(sample)
    if os.path.exists(out):
        os.remove(out)

    p = subprocess.run([exe, src_in, out], capture_output=True, text=True)
    if p.returncode != 0:
        print('FAIL lexer chay khong duoc: rc=%d %s' % (p.returncode, p.stderr))
        return 1
    print('ok   lexer chay voi 2 tham so, rc=0')

    if not os.path.exists(out):
        print('FAIL khong co file ket qua')
        return 1
    toks = read_tokens(out)
    print('ok   doc duoc %d token theo dinh dang <do-dai>:<token>' % len(toks))

    if not toks or toks[-1] != 'EOF':
        print('FAIL token cuoi khong phai EOF: %r' % (toks[-1] if toks else None))
        return 1
    print('ok   token cuoi la EOF')

    real = [t for t in toks if not t.startswith('PUNCT:') and t != 'EOF']
    if len(real) < 10:
        print('FAIL chi %d token that - lexer co ve khong chay' % len(real))
        return 1
    print('ok   %d token that' % len(real))

    print('')
    print('=== compiler_tkv bridge: 4/4 PASS ===')
    print('=> TokenVector da bien dich chay duoc TRONG QUA TRINH COMPILER.')
    print('   Do chinh xac: xem probe_many_files.py')
    return 0


if __name__ == '__main__':
    sys.exit(main())
