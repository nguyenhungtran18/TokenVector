# -*- coding: utf-8 -*-
"""Probe xem 1 TEN co ton tai trong TokenVector khong.

Phan biet 2 loai loi - day la mau soan:
  - `ham 'X' khong ton tai` / `khong tim thay ham`  -> X KHONG ton tai
  - loi ve SO THAM SO                              -> X TON TAI (chi sai arity)

Dung 1 build cho moi ten. `v = X("a")` chay duoc voi da so ham; ham can
khac so tham so se bao loi arity - van ket luan "co ton tai".
"""
import io
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TKVC = os.path.join(ROOT, 'dist', 'tkvc.exe')
WORK = os.path.join(os.environ.get('TEMP', r'C:\Windows\Temp'),
                    'tkv_name_probe')

# Bai loi "khong ton tai" - nhung loi này KHONG chung minh tên tồn tại
MISS_MARKERS = (
    "khong ton tai",
    "khong tim thay ham",
    "khong phai ham toan hoc",
    "khong ton tai trong compiler",
    "chua duoc khai bao",
    "khong phai builtin",
)


def probe(name):
    src = ('# -*- coding: utf-8 -*-\n'
           'def run() -> "i32":\n'
           '    v = %s("a")\n'
           '    print(str(v))\n'
           '    return 0\n' % name)
    path = os.path.join(WORK, 'p_%s.tkv' % name)
    io.open(path, 'w', encoding='utf-8', newline='\n').write(src)
    proc = subprocess.run(
        [TKVC, 'build', path, '--out', os.path.join(WORK, 'p_%s.exe' % name),
         '--entry', 'run', '--no-lint'],
        capture_output=True, text=True, errors='replace')
    if proc.returncode == 0:
        return 'EXISTS'
    blob = (proc.stdout or '') + (proc.stderr or '')
    low = blob.lower()
    for mk in MISS_MARKERS:
        if mk in low:
            return 'MISSING'
    # Khong khop loi "khong ton tai": hoac la loi arity (co ton tai), hoac la
    # loi bien dich khac do lenh goi sai. Ca hai deu khong phai "thieu ham".
    return 'OTHER'


def main():
    names = io.open(sys.argv[1], encoding='utf-8').read().split()
    os.makedirs(WORK, exist_ok=True)
    exists, missing, other = [], [], []
    for i, nm in enumerate(names, 1):
        r = probe(nm)
        (exists if r == 'EXISTS' else missing if r == 'MISSING' else other).append(nm)
        if i % 10 == 0:
            print('  ...%d/%d' % (i, len(names)), flush=True)
    def dump(title, lst):
        print('')
        print('%s (%d):' % (title, len(lst)))
        for i in range(0, len(lst), 6):
            print('   ' + '  '.join('%-14s' % n for n in lst[i:i + 6]).rstrip())
    dump('TON TAI (probe xac nhan)', exists)
    dump('THIEU - compiler bao "khong ton tai"', missing)
    dump('LOI KHAC (khong ket luan duoc - can xem tay)', other)


if __name__ == '__main__':
    main()
