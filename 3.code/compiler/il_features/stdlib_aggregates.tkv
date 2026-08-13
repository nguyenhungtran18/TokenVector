# -*- coding: utf-8 -*-
"""min(a,b)/max(a,b) (2 tham so vo huong) + sum/min/max/sorted/any/all
(1 tham so: list HOAC set) - Wave 3 quick-win (2026-07-29), nang cap
2026-08-03.

min(a,b)/max(a,b): macro TEXT-LEVEL (giong for_in_list/for_enumerate) -
viet lai THANH 1 ternary co san ('a < b ? a : b') NGAY TAI VI TRI xuat
hien trong dong (khong chi toan dong nhu cac macro khac - giong f-string's
subn), nen dung duoc o BAT KY vi tri bieu thuc nao (vd 'clip = min(max(x,
lo), hi)'). Quet ngoac CAN BANG THU CONG (tu viet _find_balanced_call,
khong regex thuan) de tach dung 2 tham so ke ca khi long nhau bieu thuc
phuc tap - CHAP NHAN nhan ban VAN BAN cua a/b vi bieu thuc trong DSL nay
KHONG co tac dung phu.

sum/min/max/sorted/any/all (1 tham so): TU 2026-08-03 dang ky qua
register_expr_builtin nen goi duoc o MOI vi tri bieu thuc ('return
sum(xs) + 1', 'if max(xs) > 10:', 'f(sorted(xs))') - truoc do CHI o RHS 1
phep gan don le. Duong ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu
da BO HAN (cung nguyen tac voi Giai doan 0.2: xoa duong cu, khong them
duong moi).

Cung dip nay nhan them SET (truoc chi list): HashSet<T> khong co indexer
nen duoc chuyen sang List<T> 1 lan qua List`1::.ctor(IEnumerable`1<!0>)
roi lap nhu binh thuong - dung ky thuat cua set.to_list()/list.copy().
Nho vay 'sorted(mot_set)' chay duoc (truoc day khong co duong nao).

'sum' tra ve dtype cua PHAN TU (khong phai 1 chuoi co dinh) nen can co
che moi EXPR_BUILTIN_DTYPE_FN trong il_dispatch.py - doi xung voi
return_ta_fn cua method (nhom 5).

Tham so van phai la 1 BIEN don (khong phai bieu thuc long nhau) - giong
gioi han cua json_dumps: codegen doc TypeAnn tu scope de biet dtype phan
tu. min(lst)/max(lst) NEM ArgumentOutOfRangeException luc CHAY neu nguon
rong (list[0] tu nhien throw - KHONG gia lap ValueError cua Python)."""
import re

from il_dispatch import register_macro_expander, register_expr_builtin
from il_features.list_type import il_list_type
import il_features.int_type as _int_type

# ---------------------------------------------------------------------
# min(a,b) / max(a,b) - macro text-level, viet lai thanh ternary co san.
# ---------------------------------------------------------------------
_MINMAX_CALL_RE = re.compile(r'\b(min|max)\(')


def _find_balanced_call(text, open_paren_idx):
    """text[open_paren_idx] == '(' - quet toi ')' dong khop (dem do sau
    ngoac, bo qua dau ',' BEN TRONG chuoi "..." hoac ngoac long hon), tra
    ve (idx cua ')' dong khop, list cac tham so da strip())."""
    depth = 0
    parts = []
    part_start = open_paren_idx + 1
    in_str = False
    i = open_paren_idx
    while i < len(text):
        c = text[i]
        if in_str:
            if c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                parts.append(text[part_start:i].strip())
                return i, parts
        elif c == ',' and depth == 1:
            parts.append(text[part_start:i].strip())
            part_start = i + 1
        i += 1
    raise SyntaxError(f"il_codegen: '(' o vi tri {open_paren_idx} khong co ')' dong khop trong: {text!r}")


def try_expand_minmax_2arg(line):
    m = _MINMAX_CALL_RE.search(line)
    if not m:
        return None
    name = m.group(1)
    open_idx = m.end() - 1
    close_idx, parts = _find_balanced_call(line, open_idx)
    if len(parts) < 2:
        # min(lst)/max(lst) 1 tham so (aggregate) - KHONG phai viec cua
        # macro nay, de builtin ben duoi xu ly.
        return None
    op = '<' if name == 'min' else '>'
    # N-ary (2026-08-12, Phase 5 uu tien "sum/min/max variadic"): gap
    # trai qua tung cap theo thu tu TRAI->PHAI, giong min(a, min(b,c))
    # nhung viet phang thanh 1 ternary long nhau - van CHAP NHAN nhan
    # ban VAN BAN (khong tac dung phu, xem docstring dau file).
    expr = parts[0]
    for p in parts[1:]:
        expr = f'({expr} {op} {p} ? {expr} : {p})'
    return line[:m.start()] + expr + line[close_idx + 1:]


# ---------------------------------------------------------------------
# sum/min/max/sorted/any/all (1 tham so: list HOAC set) - expr builtin.
# ---------------------------------------------------------------------
_NUMERIC_DTYPES = {'i32', 'i64', 'f32', 'f64', 'int'}


def _agg_arg_ta(args, scope, fname, max_args=1):
    """TypeAnn cua tham so + kiem tra no la 1 BIEN list/set. max_args>1
    cho phep them tham so phu (vd sum(xs, start)) - CHI args[0] duoc xet
    o day, cac tham so sau do caller tu xu ly rieng."""
    if not (1 <= len(args) <= max_args) or args[0][0] != 'var':
        extra = f" (toi da {max_args} tham so)" if max_args > 1 else ""
        raise SyntaxError(
            f"il_codegen: {fname}() can 1 tham so DAU la 1 BIEN list/set (vd {fname}(xs)){extra} "
            f"- bieu thuc long nhau chua ho tro, gan ra 1 bien truoc")
    name = args[0][1]
    try:
        ta = scope[name][2]
    except KeyError:
        raise SyntaxError(f"il_codegen: {fname}({name}) - '{name}' chua duoc khai bao")
    if ta.shape not in ('list', 'set', 'frozenset'):
        raise SyntaxError(
            f"il_codegen: {fname}({name}) can '{name}' la list, set hoac frozenset (dang co "
            f"shape={ta.shape!r})")
    return name, ta


def _agg_elem_dtype(args, scope):
    """EXPR_BUILTIN_DTYPE_FN: sum/min/max/sorted deu mang dtype PHAN TU cua
    nguon. Tra None khi chua suy duoc (caller tu fallback). sum(xs, start)
    (2026-08-12): args[1:] (start) khong anh huong dtype ket qua - VAN
    LAY tu args[0] (nguon list), chi noi long check do dai tu ==1 sang
    >=1 - BUG THAT tung phat hien: thieu nhanh nay khien infer_dtype tra
    None cho 'sum(xs, start)', keo theo compile_str_builtin() khai bao
    sai dtype cho local __strtmp (mismatch voi ket qua i32 THAT tren
    stack), gay NullReferenceException luc chay."""
    if len(args) < 1 or args[0][0] != 'var':
        return None
    try:
        return scope[args[0][1]][2].dtype
    except KeyError:
        return None


def _require_numeric(ta, fname):
    if ta.dtype not in _NUMERIC_DTYPES:
        raise SyntaxError(
            f"il_codegen: {fname}() chi ap dung cho list/set SO (i32/i64/f32/f64), "
            f"phan tu dang la {ta.dtype!r}")


def _temps_agg(node, ctx, prefix, res_dtype_fn):
    """3 bien an: nguon (List<T> - CAN ca khi tham so von la list, vi trong
    bieu thuc khong 'load lai' duoc 1 gia tri tam), chi so, va ket qua."""
    args = node[2]
    if len(args) < 1 or args[0][0] != 'var':
        return
    try:
        ta = ctx['infer_scope'][args[0][1]][2]
    except KeyError:
        return
    if ta.shape not in ('list', 'set', 'frozenset'):
        return
    TypeAnn = ctx['TypeAnn']
    ctx['declare_named'](f'__{prefix}{id(args)}_src', TypeAnn(ta.dtype, 'list'))
    ctx['declare_named'](f'__{prefix}{id(args)}_idx', TypeAnn('i32', None))
    ctx['declare_named'](f'__{prefix}{id(args)}_res', TypeAnn(res_dtype_fn(ta), None))


def _loop_prelude(args, scope, out, ctx, prefix, fname, max_args=1):
    """src = <list/set nguon> (set duoc chuyen sang List 1 lan), tra ve
    (list_type, ta, cac chi so local, 3 nhan) - dung chung cho
    sum/min/max/any/all."""
    name, ta = _agg_arg_ta(args, scope, fname, max_args=max_args)
    if ta.dtype == 'int':
        # Ham co the KHONG dung phep so hoc 'int' nao khac ngoai sum(xs)
        # - luc do khong ai khac goi ensure_class va .class TkvInt se
        # thieu han khoi file IL.
        _int_type.ensure_class(ctx)
    list_type = il_list_type(ta.dtype, ctx.get('records'))
    ctx['load_var_ref'](name, scope, out)
    if ta.shape in ('set', 'frozenset'):
        out.append(
            f'    newobj instance void {list_type}::.ctor(class '
            f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    _, src_idx, _ = scope[f'__{prefix}{id(args)}_src']
    _, idx_idx, _ = scope[f'__{prefix}{id(args)}_idx']
    _, res_idx, _ = scope[f'__{prefix}{id(args)}_res']
    out.append(f'    stloc.s {src_idx}')
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    labels = (f"{ctx['prefix']}_{prefix}{n}_start", f"{ctx['prefix']}_{prefix}{n}_skip",
              f"{ctx['prefix']}_{prefix}{n}_end")
    return list_type, ta, src_idx, idx_idx, res_idx, labels


def _emit_loop_head(out, list_type, src_idx, idx_idx, start_lbl, end_lbl):
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append(f'    bge {end_lbl}')


def _emit_loop_tail(out, idx_idx, start_lbl, end_lbl, res_idx):
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {res_idx}')


def _emit_get_item(out, list_type, src_idx, idx_idx):
    out.append(f'    ldloc.s {src_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')


def push_sum(args, scope, out, dtype, ctx):
    """sum(xs) hoac sum(xs, start) (2026-08-12, Phase 5 uu tien "sum
    variadic") - tham so thu 2 la GIA TRI KHOI TAO (bieu thuc bat ky,
    khong bat buoc la bien), thay cho hang so 0 mac dinh - dung ngu
    nghia Python that."""
    list_type, ta, src_idx, idx_idx, res_idx, (start_lbl, _skip, end_lbl) = \
        _loop_prelude(args, scope, out, ctx, 'sum', 'sum', max_args=2)
    _require_numeric(ta, 'sum')
    if len(args) == 2:
        ctx['compile_expr'](args[1], scope, out, ta.dtype, ctx)
    else:
        ctx['compile_expr'](('num', '0'), scope, out, ta.dtype, ctx)
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    _emit_loop_head(out, list_type, src_idx, idx_idx, start_lbl, end_lbl)
    out.append(f'    ldloc.s {res_idx}')
    _emit_get_item(out, list_type, src_idx, idx_idx)
    if ta.dtype == 'int':
        # Kieu 'int': 'add' cua CIL khong cong duoc hai struct. Goi
        # TkvInt::Add (duong nhanh int64 + duong BigInteger khi tran).
        _int_type.emit_add(out)
    else:
        out.append('    add')
    out.append(f'    stloc.s {res_idx}')
    _emit_loop_tail(out, idx_idx, start_lbl, end_lbl, res_idx)


def _push_minmax(args, scope, out, ctx, cmp_opcode, fname):
    list_type, ta, src_idx, idx_idx, res_idx, (start_lbl, skip_lbl, end_lbl) = \
        _loop_prelude(args, scope, out, ctx, 'agg', fname)
    _require_numeric(ta, fname)
    # res = src[0] (nguon rong -> ArgumentOutOfRangeException luc chay)
    out.append(f'    ldloc.s {src_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.1')
    out.append(f'    stloc.s {idx_idx}')
    _emit_loop_head(out, list_type, src_idx, idx_idx, start_lbl, end_lbl)
    _emit_get_item(out, list_type, src_idx, idx_idx)
    out.append(f'    ldloc.s {res_idx}')
    if ta.dtype == 'int':
        # 'clt'/'cgt' khong so sanh duoc hai struct - qua TkvInt::Cmp.
        _int_type.emit_cmp(out, cmp_opcode)
    else:
        out.append(f'    {cmp_opcode}')
    out.append(f'    brfalse {skip_lbl}')
    _emit_get_item(out, list_type, src_idx, idx_idx)
    out.append(f'    stloc.s {res_idx}')
    out.append(f'  {skip_lbl}:')
    _emit_loop_tail(out, idx_idx, start_lbl, end_lbl, res_idx)


def push_min_list(args, scope, out, dtype, ctx):
    _push_minmax(args, scope, out, ctx, 'clt', 'min')


def push_max_list(args, scope, out, dtype, ctx):
    _push_minmax(args, scope, out, ctx, 'cgt', 'max')


def _push_any_all(args, scope, out, ctx, init_val, flip_val, skip_when_zero, fname):
    list_type, ta, src_idx, idx_idx, res_idx, (start_lbl, skip_lbl, end_lbl) = \
        _loop_prelude(args, scope, out, ctx, 'anyall', fname)
    _require_numeric(ta, fname)
    out.append(f'    ldc.i4.{init_val}')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')
    _emit_loop_head(out, list_type, src_idx, idx_idx, start_lbl, end_lbl)
    _emit_get_item(out, list_type, src_idx, idx_idx)
    if ta.dtype == 'int':
        # 'ceq' khong so sanh duoc struct - TkvInt::IsZero tra thang 0/1,
        # dung y nghia "phan tu nay co falsy khong".
        _int_type.emit_is_zero(out)
    else:
        ctx['compile_expr'](('num', '0'), scope, out, ta.dtype, ctx)
        out.append('    ceq')
    # 'ceq' = 1 khi phan tu BANG 0 (falsy). any(): bo qua khi falsy. all():
    # bo qua khi TRUTHY -> lat nguoc ket qua ceq.
    if not skip_when_zero:
        out.append('    ldc.i4.0')
        out.append('    ceq')
    out.append(f'    brtrue {skip_lbl}')
    out.append(f'    ldc.i4.{flip_val}')
    out.append(f'    stloc.s {res_idx}')
    out.append(f'  {skip_lbl}:')
    _emit_loop_tail(out, idx_idx, start_lbl, end_lbl, res_idx)


def push_any_list(args, scope, out, dtype, ctx):
    _push_any_all(args, scope, out, ctx, 0, 1, True, 'any')


def push_all_list(args, scope, out, dtype, ctx):
    _push_any_all(args, scope, out, ctx, 1, 0, False, 'all')


def push_sorted(args, scope, out, dtype, ctx):
    """KHONG can bien an nao: List moi nam san tren stack, 'dup' de goi
    Sort() (tra void) roi van con chinh no lam ket qua bieu thuc."""
    name, ta = _agg_arg_ta(args, scope, 'sorted')
    list_type = il_list_type(ta.dtype, ctx.get('records'))
    ctx['load_var_ref'](name, scope, out)
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append('    dup')
    out.append(f'    callvirt instance void {list_type}::Sort()')


def _make_temps(prefix, res_dtype_fn):
    def temps_fn(node, ctx):
        _temps_agg(node, ctx, prefix, res_dtype_fn)
    return temps_fn


register_macro_expander('minmax_2arg', try_expand_minmax_2arg)

register_expr_builtin('sum', push_sum, None, temps_fn=_make_temps('sum', lambda ta: ta.dtype),
                       return_dtype_fn=_agg_elem_dtype)
register_expr_builtin('min', push_min_list, None, temps_fn=_make_temps('agg', lambda ta: ta.dtype),
                       return_dtype_fn=_agg_elem_dtype)
register_expr_builtin('max', push_max_list, None, temps_fn=_make_temps('agg', lambda ta: ta.dtype),
                       return_dtype_fn=_agg_elem_dtype)
register_expr_builtin('any', push_any_list, 'i32', temps_fn=_make_temps('anyall', lambda ta: 'i32'))
register_expr_builtin('all', push_all_list, 'i32', temps_fn=_make_temps('anyall', lambda ta: 'i32'))
# sorted() tra ve 1 CONTAINER -> return_shape de bien nhan ket qua duoc
# khai bao dung hinh dang VA tang parser giu duoc kenh known_shapes.
register_expr_builtin('sorted', push_sorted, None, return_shape='list',
                       return_dtype_fn=_agg_elem_dtype)
