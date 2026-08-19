# -*- coding: utf-8 -*-
"""Doi chieu THAT: truyen dict[str,i32] lam THAM SO ham (2026-08-04).

Truoc ban va nay: bien dich THANH CONG, chay -> 0xC0000005 (access
violation / segfault), khong loi bien dich, khong exception .NET. Day la
muc 6 trong PARITY_GAPS_2026-08-04.md va la kieu hong TE NHAT trong ca
danh sach: moi thu khac deu bao mot cach nao do, rieng cai nay chet im.

Nguyen nhan: 'counts = {}' trong ham GOI khong co dong 'counts[k] = v' nao
nen declare_dict roi ve 'body_dtype' - kieu TRA VE cua chinh ham dang bien
dich - cho ca khoa lan gia tri, dung Dictionary<string,string> roi truyen
cho ham nhan Dictionary<string,int32>.

Da DO truoc khi sua: r_len va r_sum deu rc=3221225477 (0xC0000005);
r_str_dict (dict[str,str]) van chay dung -> khoanh dung vao dtype gia tri.

Trong tai la CPython chay chinh sample_dict_param.tkv."""
import runpy
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tkv_compile import compile_tkv_cli

HERE = Path(__file__).parent.parent
SRC = HERE / 'sample_dict_param.tkv'
py = runpy.run_path(str(SRC))

# r_str_dict la DOI CHUNG: no vent chay dung ca truoc ban va, nen neu no
# do thi loi nam o cho khac chu khong phai suy kieu gia tri dict.
ENTRIES = ['r_len', 'r_sum', 'r_str_dict']


def main():
    bad = []
    for entry in ENTRIES:
        exe = HERE / ('sample_dict_param_%s.exe' % entry)
        compile_tkv_cli(SRC, exe, entry_name=entry)
        want = py[entry]('x')
        r = subprocess.run([str(exe), 'x'], capture_output=True, text=True,
                           errors='replace')
        got = r.stdout.rstrip('\r\n')
        if r.returncode != 0 or got != str(want):
            bad.append((entry, str(want), got, r.returncode,
                        r.stderr.strip()[:160]))

    print("So mau doi chieu voi CPython: %d" % len(ENTRIES))
    print("Khop: %d/%d" % (len(ENTRIES) - len(bad), len(ENTRIES)))
    if bad:
        print("SAI LECH:")
        for b in bad:
            print("  entry=%s mong doi=%r duoc=%r rc=%s %s" % b)
        return 1
    print("PASS: dict[str,i32] truyen lam tham so chay dung, khong con "
          "hong bo nho")
    return 0


if __name__ == '__main__':
    sys.exit(main())
