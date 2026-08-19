# -*- coding: utf-8 -*-
"""So lech test/parity/ledger.toml phai GHIM DUOC HAI CHIEU (moc 8, buoc
1.3): moi muc 'open' chay lai VAN phai lech, va lech DUNG LOAI da ghi.

- Tu nhien het lech (da sua that) -> test nay DO, bao "co ve da sua, hay
  doi status thanh 'fixed'" - dung y muon, KHONG duoc coi la thanh cong
  im lang.
- Lech SANG LOAI KHAC (vd tu compile_gap thanh value_mismatch) cung DO -
  nghia la hanh vi da doi nhung chua ai xac nhan lai dung sai.

Day la BAI TEST DUY NHAT trong test/verify chay tren CHINH CAC CA LOI DA
BIET cua TokenVector - no se CHAY QUA CHUONG TRINH BIEN DICH THAT (nhu
moi test khac dung compile_tkv_cli), khong phai gia lap.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'test' / 'parity'))
import ledger as L  # noqa: E402


def main():
    entries = L.load()
    if not entries:
        print('ledger_test: KHONG co muc nao trong so - bo qua')
        return 0

    open_entries = [e for e in entries if e['status'] == 'open']
    fails = []
    for e in open_entries:
        still, actual_kind = L.verify_entry(e)
        if not still:
            fails.append(
                "%s: GHI 'kind'=%r nhung chay lai duoc %r — hoac da sua "
                "that (doi status='fixed') hoac hanh vi da doi khac di, "
                "can xac nhan lai." % (e['id'], e['kind'], actual_kind))

    if fails:
        print('ledger_test: TRUOT (%d/%d muc open khong con ghim duoc)'
              % (len(fails), len(open_entries)))
        for f in fails:
            print('  -', f)
        return 1
    print('ledger_test: dat (%d muc open, tat ca van lech DUNG loai da ghi; '
          '%d muc tong cong trong so)' % (len(open_entries), len(entries)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
