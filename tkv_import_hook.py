# -*- coding: utf-8 -*-
"""Cho phep CPython THAT 'import X' tim duoc file 'X.tkv' (khong chi
'X.py') tren sys.path - dang ky 1 FileFinder path_hook nhan dien duoi
'.tkv' bang SourceFileLoader co san (Phase 6.2, 2026-08-11).

Ly do can file nay: 'from X import a, b' (cu phap Python CHUAN, xem
tkv_compile.py's _parse_program_ast) muon CHAY DUNG duoi CPython that (
khong chi luc bien dich qua tkvc.exe) thi CPython phai TU tim ra
'X.tkv' - mac dinh CPython chi biet '.py'/'.pyc'/extension module, KHONG
biet '.tkv'. Dang ky hook nay 1 LAN (idempotent) truoc moi 'from X
import ...' trong 1 file .tkv can dung tinh nang cross-file THAT ('import
tkv_import_hook' o dau file - dong nay bi trinh bien dich TokenVector BO
QUA nhu moi 'import' thuong khac vi 'tkv_import_hook.tkv' khong ton tai
canh file nguon, xem _parse_program_ast's rule 'chi merge neu <ten>.tkv
ton tai canh file')."""
import sys
import importlib.machinery


def install():
    """Idempotent - goi nhieu lan khong sao (kiem tra da co hook chua qua
    1 marker rieng, tranh chen trung nhieu FileFinder giong nhau)."""
    if getattr(sys, '_tkv_import_hook_installed', False):
        return
    loader_details = (importlib.machinery.SourceFileLoader, ['.tkv'])
    sys.path_hooks.insert(0, importlib.machinery.FileFinder.path_hook(loader_details))
    sys.path_importer_cache.clear()
    sys._tkv_import_hook_installed = True


install()
