# -*- coding: utf-8 -*-
"""CLI tkv-bind: doc 1 file .dll .NET, sinh file .tkv chua pragma
__tkv_extern_class__/__tkv_extern_method__ cho phan bind duoc, in bao
cao bo qua ra stderr.

Vi du:
    python tools/tkv_bind/main.py --dll System.dll --out bindings.tkv
"""
import argparse
import sys

from run_reflector import reflect_dll
from generator import generate


def main(argv=None):
    parser = argparse.ArgumentParser(description="tkv-bind: sinh pragma extern-class/-method tu 1 file .dll .NET")
    parser.add_argument("--dll", required=True, help="Duong dan file .dll can phan xa")
    parser.add_argument("--out", required=True, help="Duong dan file .tkv se ghi ra")
    args = parser.parse_args(argv)

    data = reflect_dll(args.dll)
    pragma_text, skips = generate(data)

    for line in skips:
        print("[tkv-bind] " + line, file=sys.stderr)
    print("[tkv-bind] tong: %d muc bo qua" % len(skips), file=sys.stderr)

    if not pragma_text:
        print("[tkv-bind] khong co gi bind duoc tu '%s' - khong ghi file." % args.dll, file=sys.stderr)
        return 1

    with open(args.out, "w", encoding="utf-8") as f:
        f.write(pragma_text + "\n")
    print("[tkv-bind] da ghi '%s'." % args.out, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
