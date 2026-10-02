# -*- coding: utf-8 -*-
"""Chay reflector.exe tren 1 DLL, tra ve dict Python da parse JSON."""
import json
import subprocess

from build_reflector import build_reflector


def reflect_dll(dll_path):
    exe = build_reflector()
    result = subprocess.run([exe, dll_path], capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        raise RuntimeError(
            "[tkv-bind] reflector.exe loi tren '%s':\n%s" % (dll_path, result.stderr))
    return json.loads(result.stdout)
