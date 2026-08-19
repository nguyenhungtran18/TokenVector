# -*- coding: utf-8 -*-
"""Noi generator + arbiter + reducer + ledger lai thanh 1 vong: sinh
chuong trinh, chay ca hai phia, rut gon ca lech, ghi so (moc 8 - "co may
trung tam" cua ke hoach - xem plan chose-and-plan-wisely-memoized-aurora.md).

Cach dung:
    python test/parity/fuzz.py --seeds 300 --start 1
    python test/parity/fuzz.py --minutes 30          # (dung cho moc 8+)

Nghiem thu moc 8: bo do TU TIM LAI duoc >= 10 lech DA BIET (BUGS_TODO.md
B1-B6 + cac gap khac da ghi trong PARITY_GAPS) MA KHONG duoc mach - tuc
khong co ca cu the nao duoc code cung vao generator, chi co VAN PHAM da
dang du de cac hinh dang do TU XUAT HIEN khi chay ngau nhien.
"""
import argparse
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
import generator as G   # noqa: E402
import arbiter as A     # noqa: E402
import reducer as R     # noqa: E402
import ledger as L      # noqa: E402

TODAY = '2026-08-05'  # phien lam viec nay - xem AGENTS/CLAUDE.md ve Date.now()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--start', type=int, default=1)
    ap.add_argument('--seeds', type=int, default=200)
    ap.add_argument('--minutes', type=float, default=None)
    ap.add_argument('--no-reduce', action='store_true')
    args = ap.parse_args()

    entries = L.load()
    n_hit = n_new = n_reduced = 0
    t0 = time.time()
    seed = args.start
    end = args.start + args.seeds

    while True:
        if args.minutes is not None:
            if (time.time() - t0) / 60.0 >= args.minutes:
                break
        elif seed >= end:
            break

        src, meta = G.generate_program(seed)
        kind, detail, py, tkv = A.probe(src, tag='fz%d' % seed)
        if kind:
            n_hit += 1
            final_src, n_chunks, tries = (
                (src, None, 0) if args.no_reduce
                else R.reduce_case(src, kind, tag='fz%d' % seed))
            if final_src is not src:
                n_reduced += 1
            entry = L.add_entry(
                entries, kind, detail, final_src, meta['templates'],
                site='fuzz.py:seed=%d' % seed, discovered=TODAY)
            if entry:
                n_new += 1
                print('[%s] MOI %s: %s  (%d chunk, seed=%d)'
                      % (entry['id'], kind, detail, n_chunks or 0, seed))
            else:
                print('  (trung lap, seed=%d, %s)' % (seed, kind))
        seed += 1
        if seed % 25 == 0:
            print('... da thu %d seed, %d lech, %d muc moi (%.0fs)'
                  % (seed - args.start, n_hit, n_new, time.time() - t0))

    L.save(entries)
    print('\n=== xong: %d seed, %d lech (%d rut gon), %d muc MOI vao so ==='
          % (seed - args.start, n_hit, n_reduced, n_new))
    by_kind = {}
    for e in entries:
        by_kind[e['kind']] = by_kind.get(e['kind'], 0) + 1
    print('tong so hien co theo loai:', by_kind)
    print('tong so muc open:', sum(1 for e in entries if e['status'] == 'open'))


if __name__ == '__main__':
    main()
