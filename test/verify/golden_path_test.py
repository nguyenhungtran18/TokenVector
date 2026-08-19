# -*- coding: utf-8 -*-
"""Golden-path test THAT: train MLPClassifier that bang sklearn tren Iris,
bien dich qua TokenVector, roi so sanh du doan cua .exe voi du doan cua
CHINH sklearn model (khong phai nhan that) tren TUNG mau test - phai
khop 100%, khong chi gan dung, vi day la kiem chung TRINH BIEN DICH
dung, khong phai kiem chung do chinh xac model."""
import subprocess
import sys
from pathlib import Path

import joblib
import numpy as np
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import MinMaxScaler

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from tokenvector_compile import compile_model

HERE = Path(__file__).parent.parent

X, y = load_iris(return_X_y=True)
class_names = load_iris().target_names.tolist()
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y)

scaler = MinMaxScaler().fit(X_train)
X_train_n = scaler.transform(X_train)

model = MLPClassifier(hidden_layer_sizes=(8,), activation='tanh',
                       max_iter=3000, random_state=0)
model.fit(X_train_n, y_train)

model_path = HERE / 'golden_iris_model.pkl'
scaler_path = HERE / 'golden_iris_scaler.pkl'
joblib.dump(model, model_path)
joblib.dump(scaler, scaler_path)

exe_path = HERE / 'golden_iris.exe'
compile_model(model, exe_path, scaler=scaler, class_labels=class_names)

sklearn_preds = model.predict(scaler.transform(X_test))

mismatches = []
for i, (row, sk_pred) in enumerate(zip(X_test, sklearn_preds)):
    args = [str(exe_path)] + [repr(float(v)) for v in row]
    result = subprocess.run(args, capture_output=True, text=True)
    exe_label = result.stdout.strip()
    sk_label = class_names[sk_pred]
    if exe_label != sk_label:
        mismatches.append((i, row.tolist(), sk_label, exe_label, result.stderr))

print(f"Tong so mau test: {len(X_test)}")
print(f"Khop (exe == sklearn): {len(X_test) - len(mismatches)}/{len(X_test)}")
if mismatches:
    print("SAI LECH:")
    for m in mismatches:
        print(f"  mau {m[0]}: x={m[1]} sklearn={m[2]} exe={m[3]} stderr={m[4]!r}")
    sys.exit(1)
else:
    print("GOLDEN PATH: PASS - .exe khop 100% voi sklearn model goc.")
