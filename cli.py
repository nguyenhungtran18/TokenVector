# -*- coding: utf-8 -*-
"""CLI: `python cli.py --model model.pkl [--scaler scaler.pkl] [--labels a,b,c] --out out.exe`
Bien dich 1 sklearn MLPClassifier (joblib-saved) thanh 1 file .exe doc lap.
"""
import argparse
import sys

import joblib

from tokenvector_compile import compile_model, TokenVectorError


def main():
    ap = argparse.ArgumentParser(description="TokenVector: sklearn MLPClassifier -> .exe doc lap")
    ap.add_argument('--model', required=True, help='Duong dan file .pkl (joblib) chua MLPClassifier da train')
    ap.add_argument('--scaler', default=None, help='Duong dan file .pkl (joblib) chua MinMaxScaler (tuy chon)')
    ap.add_argument('--labels', default=None, help='Ten cac lop, cach nhau boi dau phay (tuy chon, mac dinh in chi so)')
    ap.add_argument('--out', required=True, help='Duong dan file .exe dau ra')
    args = ap.parse_args()

    model = joblib.load(args.model)
    scaler = joblib.load(args.scaler) if args.scaler else None
    labels = args.labels.split(',') if args.labels else None

    try:
        out_path = compile_model(model, args.out, scaler=scaler, class_labels=labels)
    except TokenVectorError as e:
        print(f"[TokenVector] Loi: {e}", file=sys.stderr)
        sys.exit(1)

    n_in = model.coefs_[0].shape[0]
    print(f"[TokenVector] Da bien dich: {out_path}")
    print(f"[TokenVector] Chay thu: {out_path} " + " ".join(['<f1>'] * n_in)[:60] +
          f"  ({n_in} gia tri float)")


if __name__ == '__main__':
    main()
