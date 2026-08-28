# -*- coding: utf-8 -*-
"""File I/O co ban (Phase 1 buoc 7, 2026-07-28) - doc/ghi TOAN BO noi
dung file thanh/tu 1 string, anh xa thang cac static method cua
System.IO.File (khong ho tro doc tung dong/stream). Khong co regex rieng
(read_file/write_file/append_file/file_exists deu dung cu phap call/
call_stmt chung, phan biet BANG TEN ham) - file nay so huu: 'call_stmt'
kind TRON VEN (chi gom write_file/append_file, khong con gi khac - xem
_lp_call_stmt/_CALL_STMT_RE o core), va 2 nhanh read_file/file_exists
long trong tag 'call' dung chung o core (goi lai qua ham rieng, giong
str() cua string_feature.py). Quy uoc dependency-injection qua `ctx`
nhu cac buoc truoc."""
from il_dispatch import (register_stmt_codegen, register_expr_builtin,
                          EXPR_BUILTIN_CODEGEN, EXPR_BUILTIN_DTYPE)
# logging/pickle (Phase 4 backlog, phien 5, 2026-08-11) - nhap KHONG TRE
# o day (khong phai trong ham) de dam bao register_expr_builtin ben
# trong pickle_feature.py (cho pickle_load_X) LUON chay du chuong trinh
# co dung log_X/pickle_dump_X hay khong - file_io.py duoc il_codegen.py
# nhap KHONG DIEU KIEN nen day la diem chac chan chay 1 lan luc nap module.
import il_features.logging_feature as _logging_feature
import il_features.pickle_feature as _pickle_feature
import il_features.stdlib_sys as _stdlib_sys
import il_features.stdlib_random as _stdlib_random


def compile_read_file(args, scope, out, dtype, ctx):
    """Nhanh 'read_file(path)' cua _expr_call - doc TOAN BO noi dung
    file thanh 1 string, anh xa thang System.IO.File.ReadAllText, ROI
    chuan hoa ket thuc dong giong Python.

    SUA 2026-08-04 (lech AM THAM, khong nam trong danh sach nao truoc do):
    Python `open(p, 'r')` dung "universal newlines" - moi '\\r\\n' VA moi
    '\\r' don le tren dia deu ve bo nho thanh '\\n'. ReadAllText KHONG dich
    gi ca. Cung mot file CRLF, `len(read_file(p))` cho hai so khac nhau:
    do duoc CPython 6, TokenVector 9 tren file 'a\\r\\nb\\r\\nc\\r\\n'.

    Phat hien khi dung _tkv_arbiter cho ctxpack.tkv: phia CPython bao 600
    token, phia bien dich bao 698 - dung bang so ky tu '\\r'. Moi phep dem
    dong/token/bam chuoi tren file CRLF deu lech theo, khong loi, khong
    exception. Windows sinh file CRLF theo mac dinh nen bay nay rat de gap.

    Thu tu hai phep thay THE KHONG DOI CHO: phai bo '\\r\\n' TRUOC, neu
    khong thi '\\r\\n' se thanh '\\n\\n'."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: read_file(path) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.IO.File::ReadAllText(string)')
    out.append('    ldstr "\\r\\n"')
    out.append('    ldstr "\\n"')
    out.append('    callvirt instance string [mscorlib]System.String::'
               'Replace(string, string)')
    out.append('    ldstr "\\r"')
    out.append('    ldstr "\\n"')
    out.append('    callvirt instance string [mscorlib]System.String::'
               'Replace(string, string)')


def compile_file_exists(args, scope, out, dtype, ctx):
    """Nhanh 'file_exists(path)' cua _expr_call."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: file_exists(path) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call bool [mscorlib]System.IO.File::Exists(string)')
    ctx['widen_if_needed']('i32', dtype, out)


def _extern_void_builtin_names():
    """Fix Critical (2026-08-17, review Task 3 __tkv_extern_pinvoke__) - tra
    ve EXTERN_VOID_BUILTIN_NAMES (tkv_compile.py), tap ten builtin THAT SU
    void. Import LUC GOI (khong o dau file) vi tkv_compile.py -> il_codegen.py
    -> file_io.py (module nay) o CAP MODULE, import nguoc tkv_compile ngay
    dau file_io.py se circular. Khi ham nay duoc goi (codegen_call_stmt chay
    trong luc compile_tkv_cli dang thuc thi, SAU khi toan bo chuoi import da
    xong), tkv_compile da co san TRON VEN trong sys.modules nen import lazy
    o day an toan (giong quy uoc 'import il_features.print_feature' o duoi)."""
    import tkv_compile
    return tkv_compile.EXTERN_VOID_BUILTIN_NAMES


def codegen_call_stmt(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry TRON VEN cho kind 'call_stmt' - CHI gom
    write_file/append_file (goi ham nhu 1 LENH DOC LAP, khong gan bien) -
    goi ham do nguoi dung dinh nghia theo cach nay CHUA duoc ho tro (xem
    nhanh else, tranh im lang bo qua return value)."""
    name, call_args = stmt['call_node'][1], stmt['call_node'][2]
    compile_expr = ctx['compile_expr']
    if name == 'print':
        # moc 7 (2026-08-05) - xem il_features/print_feature.py.
        import il_features.print_feature as _print_feature
        return _print_feature.compile_print(stmt['call_node'], scope, body, ctx)
    if name == 'write_file':
        if len(call_args) != 2:
            raise SyntaxError("il_codegen: write_file(path, content) can dung 2 tham so")
        compile_expr(call_args[0], scope, body, 'str', ctx)
        compile_expr(call_args[1], scope, body, 'str', ctx)
        body.append('    call void [mscorlib]System.IO.File::WriteAllText(string, string)')
    elif name == 'append_file':
        if len(call_args) != 2:
            raise SyntaxError("il_codegen: append_file(path, content) can dung 2 tham so")
        compile_expr(call_args[0], scope, body, 'str', ctx)
        compile_expr(call_args[1], scope, body, 'str', ctx)
        body.append('    call void [mscorlib]System.IO.File::AppendAllText(string, string)')
    elif name in _logging_feature.LOG_STMT_CODEGEN:
        # logging (Phase 4 backlog, phien 5, 2026-08-11) - xem
        # il_features/logging_feature.py. Ham VOID (log_debug/.../
        # log_set_level) - khong dang qua register_expr_builtin (do
        # khong tra gia tri) nen dispatch qua day, giong write_file.
        _logging_feature.LOG_STMT_CODEGEN[name](call_args, scope, body, ctx)
    elif name in _pickle_feature.DUMP_STMT_CODEGEN:
        # pickle_dump_X (Phase 4 backlog, phien 5, 2026-08-11) - xem
        # il_features/pickle_feature.py. Cung la ham VOID, dispatch qua
        # day giong log_X o tren.
        _pickle_feature.DUMP_STMT_CODEGEN[name](call_args, scope, body, ctx)
    elif name in _stdlib_sys.SYS_STMT_CODEGEN:
        # sys_exit(code) (Phase 5.4, 2026-08-12) - xem il_features/
        # stdlib_sys.py. Cung la ham VOID, dispatch qua day giong log_X/
        # pickle_dump_X o tren.
        _stdlib_sys.SYS_STMT_CODEGEN[name](call_args, scope, body, ctx)
    elif name in _stdlib_random.RANDOM_STMT_CODEGEN:
        # seed(n) (batch 5.5, 2026-08-12) - xem il_features/stdlib_random.py.
        # Ham VOID, dispatch qua day giong log_X/pickle_dump_X/sys_exit.
        _stdlib_random.RANDOM_STMT_CODEGEN[name](call_args, scope, body, ctx)
    elif name in EXPR_BUILTIN_CODEGEN and name in _extern_void_builtin_names():
        # Task 3 (2026-08-17, __tkv_extern_pinvoke__) - sua tan goc gioi han
        # cu: builtin dang ky qua register_expr_builtin (Phase 1/2 cac pragma
        # extern) truoc day CHI goi duoc trong BIEU THUC, khong goi duoc
        # DANG LENH DOC LAP (vd ham __tkv_extern_pinvoke__ tra ve 'void').
        # Nhanh nay dat SAU 4 bang builtin void rieng o tren, TRUOC nhanh
        # else (goi ham nguoi dung) - de builtin dang ky dong duoc uu tien
        # tra TRUOC khi roi vao loi "khong tim thay ham nay".
        #
        # SUA CRITICAL (2026-08-17, review): TRUOC DAY dieu kien nhanh nay
        # la don thuan 'name in EXPR_BUILTIN_CODEGEN', va dtype None duoc
        # coi la "void". SAI: ~27 builtin co san (pow/sorted/random/sum/min/
        # max/...) CUNG dang ky return_dtype=None trong EXPR_BUILTIN_DTYPE
        # nhung vi ly do "khong suy duoc dtype tinh TU CHINH NO" (dtype phu
        # thuoc ngu canh/tham so goi), KHONG PHAI vi ham void - chung VAN
        # day gia tri THAT len stack. Heuristic cu khi gap builtin nay goi
        # DOC LAP se KHONG pop -> lech ngan xep IL (crash luc chay) hoac
        # KeyError luc compile (builtin can dtype that de tu suy, vd pow).
        # Nay dung EXTERN_VOID_BUILTIN_NAMES (tkv_compile.py) - tap RIENG,
        # TUONG MINH, chi chua ten builtin THAT SU void (hien tai: extern
        # pinvoke voi returns='void') - xem _extern_void_builtin_names() duoi.
        codegen_fn = EXPR_BUILTIN_CODEGEN[name]
        return_dtype = EXPR_BUILTIN_DTYPE.get(name)
        codegen_fn(call_args, scope, body, return_dtype, ctx)
        # Khong pop: nhanh nay CHI chay cho builtin void that (khong tra
        # gia tri gi), nen khong con logic pop co dieu kien nhu truoc.
    else:
        # 2026-08-03: goi 1 ham NGUOI DUNG nhu 1 lenh doc lap ('luu(x)',
        # 'stack.push(...)') la cach viet BINH THUONG cua Python - truoc
        # day bao loi. Bien dich nhu 1 bieu thuc roi 'pop' gia tri tra ve
        # (neu co) de ngan xep can bang; ham void thi khong pop.
        func_table = (ctx or {}).get('func_table') or {}
        sig = func_table.get(name)
        if sig is None:
            raise SyntaxError(
                f"il_codegen: '{name}(...)' dung o dang lenh doc lap (khong gan bien) - "
                f"khong tim thay ham nay trong chuong trinh (goi sai ten?)")
        ret_dtype = sig.return_type.dtype if sig.return_type is not None else None
        compile_expr(stmt['call_node'], scope, body, ret_dtype, ctx)
        if sig.return_type is not None:
            body.append('    pop')


# Dang ky vao il_dispatch NGAY LUC MODULE NAP.
register_stmt_codegen('call_stmt', codegen_call_stmt)

# Migrate tu co che if/elif cu trong il_codegen.py's _expr_call sang
# register_expr_builtin (2026-08-12, Phase "tach tkvc.exe thanh plugin")
# - gia CHUAN de goi thu vien tu ben ngoai duoc, khong can il_codegen.py
# import thang ten ham. Hanh vi IL sinh ra KHONG DOI, chi doi CO CHE
# DANG KY.
register_expr_builtin('read_file', compile_read_file, 'str')
register_expr_builtin('file_exists', compile_file_exists, 'i32')
