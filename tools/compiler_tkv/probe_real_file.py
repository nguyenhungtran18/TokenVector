"""So lexer TokenVector voi Python tren MOT file .tkv THAT cua repo.

Khong dung `expected()` cua probe_bridge.py: ham do tach bang regex don gian,
va regex KHONG doc het nguon (string nhieu dong, comment, escape...). Dung
`tokenize` cua CPython lam chuan, roi so sanh tung token de BIET lexer
TokenVector con THIEU gi - do chinh la danh sach vi cong can lam tiep.
"""
import io
import os
import subprocess
import sys
import tempfile
import token as py_token
import tokenize as py_tok

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TKVC = os.path.join(ROOT, 'dist', 'tkvc.exe')
LEXER = os.path.join(HERE, 'lexer_lib.tkv')
TMP = tempfile.gettempdir()


def py_tokens(src):
    """Token CPython, rut ve cung dang chuoi ma lexer TokenVector phat ra."""
    out = []
    for t in py_tok.generate_tokens(io.StringIO(src).readline):
        if t.type in (py_token.ENCODING,):
            continue
        s = t.string
        if t.type == py_token.NAME:
            out.append('ID:' + s)
        elif t.type == py_token.NUMBER:
            out.append('NUM:' + s)
        elif t.type in (py_token.NEWLINE,):
            out.append('NL')
        elif t.type == py_token.STRING:
            out.append('STR:' + s)
        elif t.type in (py_token.COMMENT, py_token.NL):
            continue          # lexer chua xu ly comment - bo qua o chan chuan
        elif t.type in (py_token.INDENT, py_token.DEDENT, py_token.ENDMARKER):
            continue
        else:
            out.append('PUNCT:' + s)
    out.append('EOF')
    return out




def read_tokens(path):
    """Doc file ket qua cua lexer: moi dong `<do-dai>:<token>`.

    KHONG tach theo dau phan cach nao ca - chi `\\n` het token. Mot token chua
    xuong dong se lam moi dong, va do dai o dau dong la noi dung bat dau.
    Do la ly do khong dung duoc ky tu escape thay the xuong dong: mot chuoi
    nguon that chua ky tu do se bi bien doi (gap o projects/tour.tkv).
    """
    raw = io.open(path, encoding='utf-8').read()
    out = []
    i = 0
    n = len(raw)
    while i < n:
        j = raw.find(':', i)
        if j < 0:
            break
        k = int(raw[i:j])
        out.append(raw[j + 1:j + 1 + k])
        i = j + 1 + k + 1
    return out


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'tkv_compile.tkv')
    exe = os.path.join(TMP, 'tkv_lexer.exe')
    # LUON build lai. Dung exe cache se test mot ban cu - mot sai lam
    # da lam trong chinh probe nay: sua lexer xong va van thay ket qua y het.
    r = subprocess.run([TKVC, 'build', LEXER, '--out', exe, '--entry', 'main'],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stdout + r.stderr)
        return 1

    src = io.open(target, encoding='utf-8').read()
    src_in = os.path.join(TMP, 'real.tkv')
    out = os.path.join(TMP, 'real.tokens')
    io.open(src_in, 'w', encoding='utf-8', newline='').write(src)
    if os.path.exists(out):
        os.remove(out)
    p = subprocess.run([exe, src_in, out], capture_output=True, text=True)
    if p.returncode != 0:
        print('FAIL lexer chay khong duoc rc=%d' % p.returncode)
        return 1
    got_all = read_tokens(out)
    got = [t for t in got_all if t != 'NL']
    want_all = py_tokens(src)
    want = [t for t in want_all if t != 'NL']

    print('file  : %s' % os.path.basename(target))
    print('TokenVector: %d token' % len(got))
    print('CPython     : %d token' % len(want))

    # So sanh theo chuoi: token nao lech truoc tien moi la thu toi.
    bad = 0
    for i in range(min(len(got), len(want))):
        if got[i] != want[i]:
            bad += 1
            if bad <= 5:
                print('  lech tai #%d: tv=%r  py=%r' % (i, got[i], want[i]))
    if bad or len(got) != len(want):
        print('')
        print('KET LUA: lexer CHUA duoc cho file that (>=%d token lech).' % bad)
        print('Nguyen nhan du kien: chua xu ly STRING (ke ca nhieu dong),')
        print('COMMENT, va escape. Day la phan con lai cua lexer.')
        return 1
    print('')
    print('KET LUA: lexer TokenVector khop CPython tren file nay.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
