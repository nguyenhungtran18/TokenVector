# -*- coding: utf-8 -*-
"""Tu dong tim csc.exe (C# compiler cua .NET Framework) tren may dich bat
ky, cung 1 kieu voi _find_ilasm() trong tokenvector_compile.py - quet ca
2 thu muc chuan (Framework64/Framework) x cac phien ban co the co, uu
tien ban moi nhat. KHONG can .NET SDK/dotnet CLI - chi can .NET
Framework 4.x, thu da la yeu cau bat buoc san co cua TokenVector."""
from pathlib import Path


def find_csc():
    roots = [
        Path(r"C:\WINDOWS\Microsoft.NET\Framework64"),
        Path(r"C:\WINDOWS\Microsoft.NET\Framework"),
    ]
    candidates = []
    for root in roots:
        if root.exists():
            for sub in root.iterdir():
                exe = sub / "csc.exe"
                if exe.exists():
                    candidates.append(exe)
    if not candidates:
        raise RuntimeError(
            "\n[tkv-bind] KHONG tim thay csc.exe (C# compiler) tren may nay.\n"
            "  can .NET Framework 4.x (cung yeu cau TokenVector da can de\n"
            "  bien dich/chay .tkv) - tai tai:\n"
            "  https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48\n")
    candidates.sort(key=lambda p: p.parent.name, reverse=True)
    return str(candidates[0])
