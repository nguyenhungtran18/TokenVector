# -*- coding: utf-8 -*-
"""sys.argv / sys.exit(code) (Phase 5.4, 2026-08-12) - anh xa THANG sang
Environment.GetCommandLineArgs()/Environment.Exit(int32) (xac minh THAT
qua PowerShell reflection truoc khi viet: ca 2 method deu ton tai, dung
chu ky - GetCommandLineArgs() tra 'string[]', Exit() nhan 1 tham so
'int'). Quy uoc dat ten GIONG cac module 'os.path'/'re' truoc (path_*/
re_*): TokenVector KHONG co khai niem namespace object THAT (moi import
gop phang ten vao namespace hien tai) nen 'sys.argv'/'sys.exit(code)'
duoc anh xa thanh 2 ten FLAT rieng: 'sys_argv()' (goi NHU 1 HAM, tra
list[str] - KHONG phai thuoc tinh 'sys.argv' truy cap truc tiep, gioi
han co y thuc giong cach 'os.path.exists()' -> 'path_exists()') va
'sys_exit(code)' (ham VOID, dung nhu 1 lenh doc lap - giong write_file/
log_X/pickle_dump_X, xem file_io.py's codegen_call_stmt).

sys_argv(): Environment.GetCommandLineArgs() tra 1 MANG string[] CO CA
duong dan file .exe o phan tu 0 - KHOP dung quy uoc Python that
(sys.argv[0] la ten script, sys.argv[1:] la doi so nguoi dung), khac
tham so 'args' cua chinh Main(string[] args) (KHONG co ten file, chi la
doi so nguoi dung - da dung rieng cho co che CLI tu dong bind tham so
entry, xem build_generic_main trong tkv_compile.py). Boc thanh
List<string> qua .ctor(IEnumerable<string>) - array THAT SU implement
IEnumerable<T>, tien le da dung o stdlib_aggregates.py (HashSet -> List
1 lan qua cung duong nay).

sys.path: KHONG lam - chuong trinh da AOT-compile thanh .exe tinh, khong
co dynamic import runtime nao de "duong tim module" con y nghia (cung ly
do da bo qua pdb o phan chien luoc Loai 2 dau checklist)."""
from il_dispatch import register_expr_builtin
from il_features.list_type import il_list_type


def push_sys_argv(args, scope, out, dtype, ctx):
    if args:
        raise SyntaxError("il_codegen: sys_argv() khong nhan tham so nao")
    list_type = il_list_type('str', ctx.get('records'))
    out.append('    call string[] [mscorlib]System.Environment::GetCommandLineArgs()')
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


def codegen_sys_exit(call_args, scope, body, ctx):
    if len(call_args) != 1:
        raise SyntaxError("il_codegen: sys_exit(code) can dung 1 tham so")
    ctx['compile_expr'](call_args[0], scope, body, 'i32', ctx)
    body.append('    call void [mscorlib]System.Environment::Exit(int32)')


SYS_STMT_CODEGEN = {'sys_exit': codegen_sys_exit}

register_expr_builtin('sys_argv', push_sys_argv, 'str', return_shape='list')
