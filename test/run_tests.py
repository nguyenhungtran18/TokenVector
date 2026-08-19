# -*- coding: utf-8 -*-
"""Chay toan bo test/verify/*_test.py va cho ra MOT ma thoat duy nhat.

Vi sao can file nay: truoc no, moi test la mot script roi rac tu in ket qua
roi sys.exit(0/1), va khong co gi hop chung lai. "Tat ca deu xanh" vi vay
luon la LOI NGUOI NOI, khong bao gio la su that may kiem duoc — trong khi
STATUS.md con ghi "79/79" va "91/91" tu nhung ngay so test con khac han.
Ke tu day, cau do la mot ma thoat.

Moi test chay trong TIEN TRINH RIENG: chung sua sys.path, exec file .tkv,
ghi .exe ra dia. Nhap chung vao mot tien trinh se lam chung dam nhau.

Cach dung:
    python test/run_tests.py                  # chay tat
    python test/run_tests.py --exclude net    # bo test can Internet
    python test/run_tests.py --only pytok     # loc theo ten
    python test/run_tests.py --list           # chi liet ke, khong chay

Ma thoat: 0 khi khong co test nao TRUOT. Test bi bo qua theo nhan KHONG
lam do — nhung so luong bo qua luon duoc in ra, de khong ai lang le thu hep
pham vi kiem thu roi bao la xanh.
"""
import argparse
import glob
import io
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
VERIFY = os.path.join(HERE, 'verify')
sys.path.insert(0, VERIFY)
import _manifest  # noqa: E402

RESULTS = os.path.join(VERIFY, '_results.json')
DEFAULT_TIMEOUT = 900


def discover():
    """Danh sach test, da sap xep. Bo qua file tro giup (_*.py)."""
    out = []
    for p in sorted(glob.glob(os.path.join(VERIFY, '*_test.py'))):
        name = os.path.basename(p)
        if name.startswith('_'):
            continue
        out.append((name, p))
    return out


def git_sha():
    try:
        r = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'],
                           cwd=ROOT, capture_output=True, text=True, timeout=10)
        return r.stdout.strip() if r.returncode == 0 else ''
    except Exception:
        return ''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--exclude', default='',
                    help="Bo qua test mang nhan nay (vd: net,native,repo)")
    ap.add_argument('--only', default='',
                    help="Chi chay test co chuoi nay trong ten")
    ap.add_argument('--timeout', type=int, default=DEFAULT_TIMEOUT)
    ap.add_argument('--list', action='store_true')
    args = ap.parse_args()

    excluded = {t.strip() for t in args.exclude.split(',') if t.strip()}
    tests = discover()
    if args.only:
        tests = [(n, p) for n, p in tests if args.only in n]

    if args.list:
        for name, _ in tests:
            tags = _manifest.tags_for(name)
            print('%-42s %s' % (name, ','.join(sorted(tags)) or '-'))
        print('\nTong: %d test' % len(tests))
        return 0

    if not tests:
        print("KHONG tim thay test nao — kiem lai --only/duong dan.")
        return 1

    rows = []
    n_pass = n_fail = n_skip = 0
    t0 = time.time()
    for i, (name, path) in enumerate(tests, 1):
        tags = _manifest.tags_for(name)
        hit = tags & excluded
        if hit:
            n_skip += 1
            rows.append({'name': name, 'status': 'skip', 'seconds': 0.0,
                         'tags': sorted(tags),
                         'reason': _manifest.reason_for(name),
                         'skipped_by': sorted(hit)})
            print('[%3d/%d] SKIP   %8s  %-42s (%s)'
                  % (i, len(tests), '-', name, ','.join(sorted(hit))), flush=True)
            continue

        start = time.time()
        try:
            r = subprocess.run([sys.executable, path], cwd=ROOT,
                               capture_output=True, text=True,
                               errors='replace', timeout=args.timeout)
            rc, out = r.returncode, (r.stdout + r.stderr)
            status = 'pass' if rc == 0 else 'fail'
        except subprocess.TimeoutExpired:
            rc, out, status = None, '(TIMEOUT)', 'timeout'
        secs = time.time() - start

        if status == 'pass':
            n_pass += 1
        else:
            n_fail += 1
        rows.append({'name': name, 'status': status, 'seconds': round(secs, 2),
                     'returncode': rc, 'tags': sorted(tags),
                     'stdout_tail': out[-2000:]})
        print('[%3d/%d] %-6s %7.1fs  %s%s'
              % (i, len(tests), status.upper(), secs, name,
                 '   <-- CHAM' if secs > _manifest.SLOW_SECONDS else ''),
              flush=True)

    elapsed = time.time() - t0
    summary = {'pass': n_pass, 'fail': n_fail, 'skip': n_skip,
               'total': len(tests), 'seconds': round(elapsed, 1)}
    with io.open(RESULTS, 'w', encoding='utf-8') as fh:
        json.dump({'schema': 1, 'git_sha': git_sha(),
                   'python': sys.version.split()[0],
                   'excluded_tags': sorted(excluded),
                   'summary': summary, 'tests': rows}, fh,
                  ensure_ascii=False, indent=1)

    print('\n=== PASS %d / FAIL %d / SKIP %d  (tong %d, %.1fs) ==='
          % (n_pass, n_fail, n_skip, len(tests), elapsed))
    if n_skip:
        print('Bo qua (KHONG tinh la dat):')
        for row in rows:
            if row['status'] == 'skip':
                print('  %-42s %s' % (row['name'], row['reason']))
    if n_fail:
        print('\nTRUOT:')
        for row in rows:
            if row['status'] in ('fail', 'timeout'):
                print('\n---- %s (rc=%s) ----\n%s'
                      % (row['name'], row.get('returncode'),
                         row.get('stdout_tail', '')[-1500:]))
    print('\nChi tiet: %s' % RESULTS)
    return 1 if n_fail else 0


if __name__ == '__main__':
    sys.exit(main())
