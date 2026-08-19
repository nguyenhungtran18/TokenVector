# -*- coding: utf-8 -*-
"""os.path co ban, anh xa THANG sang System.IO.Path (2026-07-28) - cung
mot ky thuat voi file_io.py (read_file/write_file -> System.IO.File).
TokenVector hien KHONG ho tro cu phap 'module.function()' (chi ten ham
tran), nen dat ten builtin la 'path_join'/'path_exists'/'path_basename'/
'path_dirname' (khong co tien to 'os.') - giong 'read_file' khong co
tien to 'os.'. Quy uoc dependency-injection qua `ctx` nhu cac
il_features/*.py khac."""

from il_dispatch import register_expr_builtin


def compile_path_join(args, scope, out, dtype, ctx):
    """path_join(a, b) - System.IO.Path::Combine(string, string). CHI ho
    tro dung 2 tham so (Python os.path.join nhan so luong bat ky - gioi
    han da biet, chua ho tro *args)."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: path_join(a, b) chi nhan dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[0], scope, out, 'str', ctx)
    compile_expr(args[1], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.IO.Path::Combine(string, string)')


def compile_path_exists(args, scope, out, dtype, ctx):
    """path_exists(p) - dung CA File.Exists LAN Directory.Exists (Python
    os.path.exists() dung cho CA file va thu muc, .NET Framework KHONG
    co 1 ham duy nhat lam viec nay nhu Path.Exists cua .NET 6+ - GIOI HAN
    DA BIET: 'p' duoc compile_expr HAI LAN (1 lan cho moi nhanh check) -
    an toan neu 'p' la 1 bien don (truong hop thuong gap), nhung se tinh
    toan lai (co the sai neu co side-effect) neu 'p' la 1 bieu thuc phuc
    tap - chua ho tro luu tam qua local an."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: path_exists(p) chi nhan dung 1 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call bool [mscorlib]System.IO.File::Exists(string)')
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call bool [mscorlib]System.IO.Directory::Exists(string)')
    out.append('    or')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_path_basename(args, scope, out, dtype, ctx):
    """path_basename(p) - System.IO.Path::GetFileName(string)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: path_basename(p) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.IO.Path::GetFileName(string)')


def compile_path_dirname(args, scope, out, dtype, ctx):
    """path_dirname(p) - System.IO.Path::GetDirectoryName(string)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: path_dirname(p) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.IO.Path::GetDirectoryName(string)')


def compile_path_isfile(args, scope, out, dtype, ctx):
    """path_isfile(p) -> i32 (0/1) - System.IO.File::Exists(string), khop
    ngu nghia Python os.path.isfile() (File rieng, khac path_exists() da
    co goi CA File.Exists LAN Directory.Exists)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: path_isfile(p) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call bool [mscorlib]System.IO.File::Exists(string)')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_path_isdir(args, scope, out, dtype, ctx):
    """path_isdir(p) -> i32 (0/1) - System.IO.Directory::Exists(string)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: path_isdir(p) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call bool [mscorlib]System.IO.Directory::Exists(string)')
    ctx['widen_if_needed']('i32', dtype, out)


register_expr_builtin('path_join', compile_path_join, 'str')
# return_dtype=None cho path_exists/path_isfile/path_isdir: ham tu goi
# ctx['widen_if_needed']('i32', dtype, out) o BEN TRONG minh (xem than ham
# o tren) - neu truyen return_dtype='i32' o day, dispatcher se widen THEM
# 1 lan nua ben ngoai -> double-widen bug (da xac nhan tai Task 3, tranh
# lai tai Task 4 va tai day, 2026-08-12).
register_expr_builtin('path_exists', compile_path_exists, None)
register_expr_builtin('path_basename', compile_path_basename, 'str')
register_expr_builtin('path_dirname', compile_path_dirname, 'str')
register_expr_builtin('path_isfile', compile_path_isfile, None)
register_expr_builtin('path_isdir', compile_path_isdir, None)
