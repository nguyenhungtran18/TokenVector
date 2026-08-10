# -*- coding: utf-8 -*-
"""lst.count(x)/lst.index(x) (Wave 2, 2026-07-29) - soan nhap boi Gemini
(dung khop chu ky method_call ngay lan dau cho ca 2 ham), Claude tich hop:
'index()' dung THANG nhu Gemini viet (List<T>.IndexOf co san, khong can
vong lap/local an); 'count()' Gemini DUNG dung khi bao "khong the giu 4
gia tri thuan tren stack qua 1 vong lap ma khong local" va DUNG LAI thay
vi doan bua CIL - Claude viet lai rieng phan nay thanh 1 tinh nang
ASSIGN-RHS CHUYEN DUNG (giong slicing.py's 'sub = lst[i:j]'), vi 'method_call'
(EXPR_CODEGEN) khong co diem moc FIRST_PASS_WALK de cap phat local AN
khi xuat hien o BAT KY vi tri bieu thuc nao - 'count()' vi vay CHI ho tro
o vi tri RHS TRUC TIEP cua 1 phep gan don ('n = lst.count(x)'), KHONG
long trong bieu thuc khac - gioi han giong het slicing.py, ghi ro ly do
o do."""
import re

from il_core import parse_expr
from il_dispatch import register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen
from il_features.list_type import il_list_type


def compile_list_method_index(node, scope, out, dtype, ctx):
    """lst.index(x) -> i32 - List<T>.IndexOf(!0), thang, khong can vong
    lap/local an. GIOI HAN DA BIET: Python nem ValueError neu khong tim
    thay; .NET IndexOf tra -1 - DSL nay chap nhan hanh vi -1 (khong gia
    lap exception, giong list.remove() da chap nhan Remove() tra bool
    truoc do)."""
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: lst.index(x) can dung 1 tham so")
    _, _, ta = scope[obj_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: '{obj_name}.index(...)' can '{obj_name}' la list")
    list_type = il_list_type(ta.dtype, (ctx or {}).get('records'))
    ctx['load_var_ref'](obj_name, scope, out)
    ctx['compile_expr'](args[0], scope, out, ta.dtype, ctx)
    out.append(f'    callvirt instance int32 {list_type}::IndexOf(!0)')
    ctx['widen_if_needed']('i32', dtype, out)


_LIST_COUNT_RE = re.compile(r'^(\w+)\.count\((.+)\)$')


def try_rhs_list_count(rhs, name, known_shapes):
    """ASSIGN_RHS_PARSERS entry: 'n = lst.count(x)' CHI khi 'lst' DA BIET
    la list (giong try_rhs_list_slice) - cu phap giong y het 1 method_call
    binh thuong nhung dinh tuyen RIENG (khong qua record_feature.py's
    compile_method_call) vi can vong lap + 3 local AN (target/idx/counter,
    xem fpw_assign_list_count)."""
    m = _LIST_COUNT_RE.match(rhs.strip())
    if not m or known_shapes.get(m.group(1)) != 'list':
        return None
    list_name, arg_expr = m.groups()
    return {'kind': 'assign_list_count', 'name': name, 'list_name': list_name,
            'target_node': parse_expr(arg_expr)}


def fpw_assign_list_count(stmt, ctx):
    _, _, list_ta = ctx['infer_scope'][stmt['list_name']]
    if list_ta.shape != 'list':
        raise SyntaxError(f"il_codegen: '{stmt['list_name']}.count(...)' can '{stmt['list_name']}' la list")
    ctx['declare_named'](stmt['name'], ctx['TypeAnn']('i32', None))
    ctx['declare_named'](f'__count{id(stmt)}_target', ctx['TypeAnn'](list_ta.dtype, None))
    ctx['declare_named'](f'__count{id(stmt)}_idx', ctx['TypeAnn']('i32', None))
    ctx['collect_ternary_temps'](stmt['target_node'])


def codegen_assign_list_count(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """Vong lap CIL that (idx tu 0 den Count-1, so sanh list[idx] voi
    target_val da luu san, tang counter khi khop) - dung 2 local AN
    (target_val/idx), KHONG can local rieng cho counter: 'name' (bien
    dich cua chinh cau lenh gan, da co san 1 memory slot) dung LUON lam
    counter, khoi tao 0 va cong don truc tiep - tiet kiem 1 local, van
    an toan (khong ai doc 'name' truoc khi vong lap ket thuc)."""
    _, _, list_ta = scope[stmt['list_name']]
    list_type = il_list_type(list_ta.dtype, ctx.get('records'))
    compile_expr = ctx['compile_expr']
    load_var_ref = ctx['load_var_ref']
    store_var = ctx['store_var']

    _, target_idx, _ = scope[f'__count{id(stmt)}_target']
    _, idx_idx, _ = scope[f'__count{id(stmt)}_idx']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_lcnt{n}_start"
    next_lbl = f"{ctx['prefix']}_lcnt{n}_next"
    end_lbl = f"{ctx['prefix']}_lcnt{n}_end"

    # target_val = <bieu thuc x>  (tinh 1 LAN duy nhat)
    compile_expr(stmt['target_node'], scope, body, list_ta.dtype, ctx)
    body.append(f'    stloc.s {target_idx}')
    # idx = 0
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')
    # counter (chinh la bien 'name') = 0
    body.append('    ldc.i4.0')
    store_var(stmt['name'], scope, body)

    body.append(f'  {start_lbl}:')
    # if (idx >= list.Count) goto end
    body.append(f'    ldloc.s {idx_idx}')
    load_var_ref(stmt['list_name'], scope, body)
    body.append(f'    callvirt instance int32 {list_type}::get_Count()')
    body.append(f'    bge {end_lbl}')
    # if (list[idx] != target_val) goto next
    load_var_ref(stmt['list_name'], scope, body)
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    body.append(f'    ldloc.s {target_idx}')
    if list_ta.dtype == 'str':
        # BUG THAT (phat hien 2026-08-03 qua test nhom 6, CO SAN tu truoc -
        # khong phai do 0.2 gay ra): 'ceq' tren 2 tham chieu string la so
        # sanh DANH TINH, khong phai GIA TRI. No TINH CO dung khi ca 2 ben
        # la hang so chu ('xs.append("a")' + 'xs.count("a")' - .NET NOI SUY
        # chung 1 tham chieu) nen bug bi AN, nhung SAI ngay khi phan tu la
        # chuoi tao luc chay (vd tu s.split(",")) -> dem ra 0. Dung
        # String::Equals nhu compile_compare_str da lam (string_feature.py) -
        # du an DA biet van de nay, chi rieng cho nay bi sot.
        body.append('    call bool [mscorlib]System.String::Equals(string, string)')
    elif list_ta.dtype == 'int':
        # Kieu 'int' (2026-08-05): 'ceq' khong so sanh duoc hai struct -
        # IL sai kieu ma ilasm van nuot, chuong trinh nem
        # BadImageFormatException luc CHAY (loi THAT: list_batch3_test).
        body.append('    call int32 TkvInt::Cmp(valuetype TkvInt, valuetype TkvInt)')
        body.append('    ldc.i4.0')
        body.append('    ceq')
    else:
        body.append('    ceq')
    body.append(f'    brfalse {next_lbl}')
    # counter += 1
    load_var_ref(stmt['name'], scope, body)
    body.append('    ldc.i4.1')
    body.append('    add')
    store_var(stmt['name'], scope, body)
    # idx += 1; loop
    body.append(f'  {next_lbl}:')
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')


register_assign_rhs_parser('list_count', try_rhs_list_count)
register_first_pass_walk('assign_list_count', fpw_assign_list_count)
register_stmt_codegen('assign_list_count', codegen_assign_list_count)
