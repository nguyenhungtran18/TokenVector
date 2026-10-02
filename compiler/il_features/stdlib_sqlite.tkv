# -*- coding: utf-8 -*-
"""SQLite that qua P/Invoke THANG toi sqlite3.dll native (2026-07-29,
Wave 3 - DB, hang muc cuoi cung con lai cua "web/DB" - xem project-
tokenvector-wave2-status memory). KHONG dung managed wrapper assembly
(System.Data.SQLite.dll KHONG co san tren may nay, khong tai duoc qua
NuGet trong phien nay - da bao cao trung thuc). Dung dung phuong phap
"tim code that roi port": (1) file sqlite3.dll co san trong TokenNativeDB
HOA RA la ban dac thu cho _sqlite3.pyd cua Python (AccessViolationException
that khi P/Invoke truc tiep - da tu xac nhan qua C# THAT va Python ctypes
THAT, khong phai doan mo); (2) tai ban CHINH THUC tu sqlite.org/download.html
(sqlite-dll-win-x64, phien ban 3.53.4, nguoi dung xac nhan cho phep tai);
(3) viet 1 chuong trinh C# P/Invoke THAT, compile qua csc.exe, CHAY THAT
(open/create/insert/select/count deu dung); (4) tu viet + verify 1 spike
ILASM THUAN (khong co ildasm de doc pinvokeimpl truc tiep tu C# bien
dich) xac nhan cu phap '.method ... pinvokeimpl("sqlite3.dll" cdecl)'
THAT chay dung; (5) xac nhan THEM: dung 'int64' THAY 'native int' (kieu
CIL rieng cho con tro) van chay DUNG HET tren x64 (native int va int64
CUNG bit-width tren x64) - giup TAI DUNG THANG dtype 'i64' co san cua
TokenVector, KHONG can them 1 dtype/CIL-type moi nao vao he thong.

Kien truc: 5 method P/Invoke TINH (khong instance) khai bao 1 LAN duy
nhat trong class chuong trinh (xem SQLITE_PINVOKE_DECL_LINES, ghep vao
qua tkv_compile.py CHI KHI chuong trinh THAT SU dung it nhat 1 ham
db_*, xem uses_sqlite()). 4 ham nguoi dung go duoc, tat ca dtype handle/
statement la 'i64' (con tro/handle THUAN, KHONG lam tinh toan so hoc
tren no):
- db_open(path) -> i64 (handle DB, BO QUA ma loi tra ve tu sqlite3_open -
  gioi han co y thuc, don gian hoa - loi se lo ra o cac loi goi sau).
- db_exec(handle, sql) -> i32 (ma ket qua cua sqlite3_step - dung cho
  CREATE/INSERT/UPDATE/DELETE, KHONG doc hang nao).
- db_query_text(handle, sql) -> str (hang DAU TIEN, cot 0, dang text;
  chuoi RONG neu khong co hang nao khop).
- db_query_int(handle, sql) -> i64 (hang DAU TIEN, cot 0, dang so
  nguyen; 0 neu khong co hang nao khop).
- db_close(handle) -> i32 (ma ket qua sqlite3_close).

TU 2026-08-03 (Giai doan 0.2 nhom 8): ca 5 ham dang ky qua register_expr_builtin
nen goi duoc o MOI vi tri bieu thuc ('return db_query_int(h, sql)',
'db_exec(h, a) + db_exec(h, b)'), khong con gioi han "chi RHS 1 phep gan don
le"; duong ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN, va
db_close bo 2 nhanh if/elif rieng trong il_codegen.py. Kem theo do BO LUON
_split_top_level_comma_2: tham so nay do CHINH parser bieu thuc tach (dua
tren tokenizer, hieu chuoi "..." va ngoac long nhau) nen loi tach nham dau
',' BEN TRONG cau SQL - bug that da phai viet ham do de va - KHONG the tai
dien. Day la 1 duong phan tich BI XOA, khong phai them.

GIOI HAN CO Y THUC (chua ho tro, ghi ro khong giau): CHI cot 0 cua hang
DAU TIEN (khong ho tro doc nhieu cot/nhieu hang cung luc - can 1 kieu
"row"/vong lap moi, ngoai pham vi phien nay); KHONG parameterized query
(sql la 1 chuoi HOAN CHINH, nguoi dung tu ghep gia tri vao chuoi - rui ro
SQL injection neu dung voi input khong tin cay, giong nhieu ngon ngu
script don gian khac); KHONG kiem tra ma loi cua open/prepare (chi step/
close tra ve ro rang)."""
import re

from il_dispatch import register_expr_builtin

_USES_SQLITE_RE = re.compile(r'\bdb_(open|exec|query_text|query_int|close)\(')

SQLITE_PINVOKE_DECL_LINES = [
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_open" cdecl)',
    '      int32 __sqlite3_open(string filename, int64& db) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_prepare_v2" cdecl)',
    '      int32 __sqlite3_prepare_v2(int64 db, string sql, int32 nbyte, int64& stmt, int64 tail) '
    'cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_step" cdecl)',
    '      int32 __sqlite3_step(int64 stmt) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_finalize" cdecl)',
    '      int32 __sqlite3_finalize(int64 stmt) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_column_text" cdecl)',
    '      int64 __sqlite3_column_text(int64 stmt, int32 col) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_column_int64" cdecl)',
    '      int64 __sqlite3_column_int64(int64 stmt, int32 col) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("sqlite3.dll" as "sqlite3_close" cdecl)',
    '      int32 __sqlite3_close(int64 db) cil managed preservesig {}',
]


def uses_sqlite(body_lines):
    """True neu than ham (RAW, chua parse) co goi 1 trong 4 ham db_* -
    dung boi tkv_compile.py de quyet dinh co ghep SQLITE_PINVOKE_DECL_LINES
    vao class chuong trinh hay khong (CHI khi that su dung, tranh khai
    bao pinvoke thua cho chuong trinh khong dung DB)."""
    for raw in body_lines:
        if _USES_SQLITE_RE.search(raw):
            return True
    return False


def _class_name(ctx):
    return (ctx or {}).get('class_name') or 'Program'


def _check_argc(name, args, n):
    if len(args) != n:
        raise SyntaxError(f"il_codegen: {name}() can dung {n} tham so, nhan duoc {len(args)}")


def push_db_close(args, scope, out, dtype, ctx):
    """db_close(handle) - KHONG can hidden local (khong co out-param).
    TU 2026-08-03 (Giai doan 0.2 nhom 8): dang ky qua register_expr_builtin
    thay vi 1 nhanh if/elif RIENG trong _expr_call + 1 nhanh RIENG trong
    _infer_dtype cua il_codegen.py (2 noi phai sua song song moi lan them
    builtin). KHONG con tu widen o day - _expr_call widen 1 lan theo
    EXPR_BUILTIN_DTYPE, widen 2 lan la sai."""
    _check_argc('db_close', args, 1)
    ctx['compile_expr'](args[0], scope, out, 'i64', ctx)
    out.append(f'    call int32 {_class_name(ctx)}::__sqlite3_close(int64)')


def temps_db_open(node, ctx):
    """out-param 'int64& db' cua sqlite3_open can 1 dia chi THAT -> 1 hidden
    local. Khoa id(node[2]) = id(danh sach tham so): chu ky codegen cua
    builtin la (args, scope, out, dtype, ctx), KHONG co 'node', va args
    CHINH LA node[2] (cung object AST o ca 2 pass) - cung quy uoc nhom 7,
    xem stdlib_json.py."""
    ctx['declare_named'](f'__dbopen{id(node[2])}_dbout', ctx['TypeAnn']('i64', None))


def push_db_open(args, scope, out, dtype, ctx):
    _check_argc('db_open', args, 1)
    _, dbout_idx, _ = scope[f'__dbopen{id(args)}_dbout']
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    ldloca.s {dbout_idx}')
    out.append(f'    call int32 {_class_name(ctx)}::__sqlite3_open(string, int64&)')
    out.append('    pop')
    out.append(f'    ldloc.s {dbout_idx}')


def temps_db_exec(node, ctx):
    ctx['declare_named'](f'__dbexec{id(node[2])}_stmt', ctx['TypeAnn']('i64', None))


def _push_prepare_step(args, scope, out, ctx, stmt_idx):
    """handle + sql -> prepare_v2 (bo qua ma loi) -> step, de KET QUA step
    tren stack."""
    class_name = _class_name(ctx)
    ctx['compile_expr'](args[0], scope, out, 'i64', ctx)
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    out.append('    ldc.i4.m1')
    out.append(f'    ldloca.s {stmt_idx}')
    out.append('    ldc.i4.0')
    out.append('    conv.i8')
    out.append(f'    call int32 {class_name}::__sqlite3_prepare_v2(int64, string, int32, int64&, int64)')
    out.append('    pop')
    out.append(f'    ldloc.s {stmt_idx}')
    out.append(f'    call int32 {class_name}::__sqlite3_step(int64)')


def _push_finalize(out, ctx, stmt_idx):
    """finalize CHAY SAU khi gia tri ket qua da nam tren stack - hop le vi
    gia tri do da duoc SAO CHEP ra khoi vung nho cua statement (PtrToStringAnsi
    tao chuoi .NET moi; column_int64 tra ve gia tri). ILASM chap nhan: 3 lenh
    nay day roi bo dung 1 gia tri, do sau stack truoc/sau khong doi."""
    out.append(f'    ldloc.s {stmt_idx}')
    out.append(f'    call int32 {_class_name(ctx)}::__sqlite3_finalize(int64)')
    out.append('    pop')


def push_db_exec(args, scope, out, dtype, ctx):
    _check_argc('db_exec', args, 2)
    _, stmt_idx, _ = scope[f'__dbexec{id(args)}_stmt']
    _push_prepare_step(args, scope, out, ctx, stmt_idx)
    _push_finalize(out, ctx, stmt_idx)


def temps_db_query_text(node, ctx):
    ctx['declare_named'](f'__dbqt{id(node[2])}_stmt', ctx['TypeAnn']('i64', None))
    ctx['declare_named'](f'__dbqt{id(node[2])}_rc', ctx['TypeAnn']('i32', None))


def push_db_query_text(args, scope, out, dtype, ctx):
    _check_argc('db_query_text', args, 2)
    _, stmt_idx, _ = scope[f'__dbqt{id(args)}_stmt']
    _, rc_idx, _ = scope[f'__dbqt{id(args)}_rc']
    _push_prepare_step(args, scope, out, ctx, stmt_idx)
    out.append(f'    stloc.s {rc_idx}')

    # Nhan DUY NHAT moi lan goi (giong nhom 2) - builtin nay gio goi duoc
    # NHIEU LAN trong cung 1 ham.
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    norow_lbl = f"{ctx['prefix']}_dbqt{n}_norow"
    end_lbl = f"{ctx['prefix']}_dbqt{n}_end"

    out.append(f'    ldloc.s {rc_idx}')
    out.append('    ldc.i4 100')
    out.append(f'    bne.un {norow_lbl}')
    out.append(f'    ldloc.s {stmt_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    call int64 {_class_name(ctx)}::__sqlite3_column_text(int64, int32)')
    out.append('    conv.i')
    out.append('    call string [mscorlib]System.Runtime.InteropServices.Marshal::PtrToStringAnsi(native int)')
    out.append(f'    br {end_lbl}')
    out.append(f'  {norow_lbl}:')
    out.append('    ldstr ""')
    out.append(f'  {end_lbl}:')
    _push_finalize(out, ctx, stmt_idx)


def temps_db_query_int(node, ctx):
    ctx['declare_named'](f'__dbqi{id(node[2])}_stmt', ctx['TypeAnn']('i64', None))
    ctx['declare_named'](f'__dbqi{id(node[2])}_rc', ctx['TypeAnn']('i32', None))


def push_db_query_int(args, scope, out, dtype, ctx):
    _check_argc('db_query_int', args, 2)
    _, stmt_idx, _ = scope[f'__dbqi{id(args)}_stmt']
    _, rc_idx, _ = scope[f'__dbqi{id(args)}_rc']
    _push_prepare_step(args, scope, out, ctx, stmt_idx)
    out.append(f'    stloc.s {rc_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    norow_lbl = f"{ctx['prefix']}_dbqi{n}_norow"
    end_lbl = f"{ctx['prefix']}_dbqi{n}_end"

    out.append(f'    ldloc.s {rc_idx}')
    out.append('    ldc.i4 100')
    out.append(f'    bne.un {norow_lbl}')
    out.append(f'    ldloc.s {stmt_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    call int64 {_class_name(ctx)}::__sqlite3_column_int64(int64, int32)')
    out.append(f'    br {end_lbl}')
    out.append(f'  {norow_lbl}:')
    out.append('    ldc.i8 0')
    out.append(f'  {end_lbl}:')
    _push_finalize(out, ctx, stmt_idx)


register_expr_builtin('db_open', push_db_open, 'i64', temps_fn=temps_db_open)
register_expr_builtin('db_exec', push_db_exec, 'i32', temps_fn=temps_db_exec)
register_expr_builtin('db_query_text', push_db_query_text, 'str',
                       temps_fn=temps_db_query_text)
register_expr_builtin('db_query_int', push_db_query_int, 'i64',
                       temps_fn=temps_db_query_int)
register_expr_builtin('db_close', push_db_close, 'i32')
