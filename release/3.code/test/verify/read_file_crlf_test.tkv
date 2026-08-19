# -*- coding: utf-8 -*-
"""Doi chieu THAT: read_file() phai chuan hoa ket thuc dong nhu Python.

Lech AM THAM, KHONG nam trong bat ky danh sach loi nao truoc do. Tim ra
2026-08-04 khi chuyen ctxpack_test sang _tkv_arbiter: phia CPython bao
600 token, phia bien dich bao 698 - dung bang so ky tu '\\r'.

Python `open(p, 'r')` dung "universal newlines": '\\r\\n' VA '\\r' don le
tren dia deu ve bo nho thanh '\\n'. TokenVector anh xa read_file thang
sang System.IO.File::ReadAllText, khong dich gi ca. Do duoc tren file
'a\\r\\nb\\r\\nc\\r\\n': CPython len()=6, TokenVector len()=9.

Vi sao dang so: Windows sinh file CRLF THEO MAC DINH, nen bat ky cong cu
.tkv nao dem dong / dem token / bam chuoi tren file doc tu dia deu lech,
ma khong loi, khong exception. Ba trong bon cong cu CodeGraph dau tien
duoc bien dich that deu di qua duong nay.

Trong tai la CPython doc chinh file do (che do van ban, mac dinh)."""
import io
import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_read_file_crlf.tkv'

# Ba dang ket thuc dong. 'CR don le' la dang co (Mac cu) nhung Python VAN
# chuan hoa, nen de day de ban sua khong chi lam moi truong hop CRLF.
CASES = [
    ('CRLF', b'a\r\nb\r\nc\r\n'),
    ('LF', b'a\nb\nc\n'),
    ('CR-don-le', b'a\rb\rc\r'),
    ('tron-lan', b'a\r\nb\nc\rd'),
    ('khong-co-dong-cuoi', b'a\r\nb'),
]


def main():
    exe = HERE / 'sample_read_file_crlf.exe'
    if exe.exists():
        exe.unlink()
    compile_tkv_cli(SRC, exe, entry_name='char_count')

    tmp = tempfile.mkdtemp(prefix='tkv_crlf_')
    bad = []
    for label, data in CASES:
        p = os.path.join(tmp, label + '.txt')
        with open(p, 'wb') as fh:
            fh.write(data)
        want = len(io.open(p, encoding='utf-8').read())
        r = subprocess.run([str(exe), p], capture_output=True, text=True,
                           errors='replace')
        got = r.stdout.strip()
        if r.returncode != 0 or got != str(want):
            bad.append((label, data, want, got, r.returncode))

    print("So mau doi chieu voi CPython: %d" % len(CASES))
    print("Khop: %d/%d" % (len(CASES) - len(bad), len(CASES)))
    if bad:
        print("SAI LECH:")
        for label, data, want, got, rc in bad:
            print("  %-18s tren dia=%r CPython=%s TokenVector=%r rc=%s"
                  % (label, data, want, got, rc))
        return 1
    print("PASS: read_file chuan hoa CRLF va CR don le thanh LF giong "
          "universal newlines cua Python")
    return 0


if __name__ == '__main__':
    sys.exit(main())
