# -*- coding: utf-8 -*-
"""stdlib_zipfile.py - Plug-and-Play module cho ZipFile creation & extraction

Cung cap:
- zip_create(folder_path, zip_path) -> i32
- zip_extract(zip_path, dest_folder) -> i32

TU 2026-08-03 (Giai doan 0.2 nhom 8): dang ky qua register_expr_builtin nen
goi duoc o MOI vi tri bieu thuc ('return zip_create(a, b)'); duong
ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN. Regex cu tach
tham so bang 1 regex '[^,]+' - tach NHAM khi duong dan/bieu thuc dau tien
tu chua dau ','; nay tham so do CHINH parser bieu thuc tach nen het loi do.

zip_create GHI DE file .zip da ton tai (sua 2026-08-03, Giai doan 1):
ZipFile.CreateFromDirectory NEM IOException neu file dich da co, trong khi
Python's zipfile.ZipFile(path, 'w') ghi de - khac biet nay tung lam
test_office_db.tkv crash khi chay lan 2 tren cung thu muc (bug THAT do
stdlib_regression_test.py moi phat hien; bo test cu khong he chay toi
module do). Nay xoa file dich truoc qua File::Delete - File.Delete KHONG
nem loi neu file chua ton tai, nen khong can kiem tra Exists.

Ca hai ham deu tra ve 1 (khong co ma loi that): CreateFromDirectory/
ExtractToDirectory tra void va NEM exception khi loi - gioi han co y thuc,
ghi ro khong giau (DSL chua co try/except).

VAN CON KHAC Python, CO Y KHONG SUA: zip_extract nem loi neu file dich da
ton tai trong thu muc giai nen (Python's extractall ghi de). Sua "dung"
o day nghia la TU XOA file/thu muc cua nguoi dung - viec pha huy du lieu,
khong lam am tham. Muon ghi de thi tu xoa truoc bang shutil."""

from il_dispatch import register_expr_builtin


def temps_zip_create(node, ctx):
    """1 bien an giu duong dan .zip: can dung gia tri do HAI lan (File::
    Delete roi CreateFromDirectory) ma bieu thuc chi tinh 1 lan."""
    ctx['declare_named'](f'__zipc{id(node[2])}_path', ctx['TypeAnn']('str', None))


def push_zip_create(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: zip_create(folder_path, zip_path) can dung 2 tham so")
    _, path_idx, _ = scope[f'__zipc{id(args)}_path']
    # Tham so 2 (duong dan .zip) tinh TRUOC tham so 1 - khac thu tu trai
    # sang phai cua Python. Trong pham vi DSL nay bieu thuc duong dan
    # khong co tac dung phu (khong co ++/gan long nhau), nen khong quan
    # sat duoc su khac biet; ghi ra day de nguoi doc sau khong bat ngo.
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    out.append(f'    stloc.s {path_idx}')
    out.append(f'    ldloc.s {path_idx}')
    out.append('    call void [mscorlib]System.IO.File::Delete(string)')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    ldloc.s {path_idx}')
    out.append('    call void [System.IO.Compression.FileSystem]'
               'System.IO.Compression.ZipFile::CreateFromDirectory(string, string)')
    out.append('    ldc.i4.1')


def push_zip_extract(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: zip_extract(zip_path, dest_folder) can dung 2 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    out.append('    call void [System.IO.Compression.FileSystem]'
               'System.IO.Compression.ZipFile::ExtractToDirectory(string, string)')
    out.append('    ldc.i4.1')


register_expr_builtin('zip_create', push_zip_create, 'i32', temps_fn=temps_zip_create)
register_expr_builtin('zip_extract', push_zip_extract, 'i32')
