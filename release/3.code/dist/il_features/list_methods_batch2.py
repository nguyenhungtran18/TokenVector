# -*- coding: utf-8 -*-
"""list.sort()/list.extend() (2026-07-29) - soan nhap boi Gemini, Claude
sua lai chu ky LINE_PARSERS/STMT_CODEGEN/FIRST_PASS_WALK cho khop dung
khuon that cua il_dispatch.py (draft goc dung sai chu ky kieu offset-scan
tu viet, khong phai khuon dang ky that cua he thong - xem list_type.py
lam mau chuan) truoc khi noi vao. Logic nghiep vu (Sort()/AddRange(),
kiem tra dtype khop nhau khi extend) giu nguyen y het draft, chi sua
phan "khung" tich hop.

key=/reverse= (2026-08-12, Phase 5 uu tien "list.sort key/reverse"):
- reverse=True/False: re, chi Sort() roi Reverse() (co san, xac minh THAT
  qua reflection - xem list_methods_batch3.py's list.reverse()).
- key=g: 'g' PHAI la 1 bien kieu 'func' da khai bao HOAC 1 ham top-level
  (dung LAI ha tang first-class function value cua map/filter/reduce -
  xem _resolve_func_ta/compile_funcref_arg trong stdlib_functional.py/
  il_codegen.py). Thuat toan "decorate-sort-undecorate": xay
  List<ValueTuple<K,T>> pairs = [(g(x), x) for x in lst], goi
  pairs.Sort() (dung Comparer<ValueTuple<K,T>>.Default CO SAN - so sanh
  Item1 truoc, Item2 sau - CHI dung duoc vi moi dtype DSL nay ho tro deu
  da IComparable: i32/i64/f32/f64/str qua CLR native, 'int' qua TkvInt
  (them rieng cho sorted(list[int]), xem int_type.py) - KHONG can dung
  Comparison<T> delegate tuy bien nao ca, tai dung nguyen co che
  list[(K,V)] da co (tien le most_common(c,n) trong counter_type.py)),
  roi ghi lai lst[i] = pairs[i].Item2. GIOI HAN CO Y THUC: sap xep KHONG
  ON DINH (not stable) khi co PHAN TU TRUNG KEY - Python that giu nguyen
  thu tu ban dau cho cac phan tu trung key, o day thu tu cac phan tu
  trung key co the bi DAO LAI vi tie-break qua Item2 (gia tri THAT, khong
  phai chi so goc) - danh doi de tranh viet 1 delegate Comparison<T> moi
  hoan toan, ghi ro trong docstring codegen_list_sort ben duoi."""
import re

from il_core import parse_expr
from il_dispatch import register_line_parser, register_stmt_codegen, register_first_pass_walk
from il_features.list_type import il_list_type
from il_features.tuple_type import il_tupleN_type
from il_features.stdlib_functional import _resolve_func_ta

_LIST_SORT_RE = re.compile(r'^(\w+)\.sort\(\s*(.*?)\s*\)\s*$')
_LIST_EXTEND_RE = re.compile(r'^(\w+)\.extend\((\w+)\)\s*$')


def _parse_sort_kwargs(args_text, lst_name):
    """'key=g, reverse=True' -> (key_name hoac None, reverse bool). CHI
    ho tro dung 2 kwarg nay, moi cai toi da 1 lan, 'reverse' phai la hang
    'True'/'False', 'key' phai la 1 TEN (khong bieu thuc phuc tap - xem
    _resolve_func_ta cho ly do)."""
    key_name = None
    reverse = False
    if not args_text:
        return key_name, reverse
    for part in args_text.split(','):
        part = part.strip()
        if not part:
            continue
        if '=' not in part:
            raise SyntaxError(
                f"il_codegen: '{lst_name}.sort(...)' chi nhan dang 'key=...'/'reverse=...' "
                f"(kwargs), khong nhan tham so vi tri")
        k, v = (s.strip() for s in part.split('=', 1))
        if k == 'key':
            if key_name is not None:
                raise SyntaxError(f"il_codegen: '{lst_name}.sort(...)' 'key=' xuat hien 2 lan")
            if not re.fullmatch(r'\w+', v):
                raise SyntaxError(
                    f"il_codegen: '{lst_name}.sort(key=...)' 'key' chi nhan TEN 1 bien kieu "
                    f"'func' da khai bao hoac TEN 1 ham top-level - khong nhan lambda/bieu "
                    f"thuc phuc tap tai cho")
            key_name = v
        elif k == 'reverse':
            if v not in ('True', 'False'):
                raise SyntaxError(
                    f"il_codegen: '{lst_name}.sort(reverse=...)' chi nhan hang 'True'/'False'")
            reverse = (v == 'True')
        else:
            raise SyntaxError(
                f"il_codegen: '{lst_name}.sort(...)' khong nhan tham so '{k}' (chi ho tro "
                f"key=/reverse=)")
    return key_name, reverse


def try_parse_list_sort(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'lst.sort()'/'lst.sort(key=g)'/'lst.sort(reverse=True)'/
    'lst.sort(key=g, reverse=True)' - PHAI dang ky TRUOC method_call_stmt."""
    m = _LIST_SORT_RE.match(line)
    if not m:
        return None
    name, args_text = m.groups()
    key_name, reverse = _parse_sort_kwargs(args_text, name)
    return {'kind': 'list_sort', 'name': name, 'key_name': key_name, 'reverse': reverse}, pos + 1


def try_parse_list_extend(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'lst.extend(other)' - `other` PHAI la 1 TEN
    BIEN don (khong ho tro bieu thuc phuc tap - can doc scope['other']
    de doi chieu dtype phan tu luc codegen, ma parse_expr tren 1 bieu
    thuc bat ky khong dam bao chi la 1 ten bien)."""
    m = _LIST_EXTEND_RE.match(line)
    if not m:
        return None
    name, other_name = m.groups()
    return {'kind': 'list_extend', 'name': name, 'other_name': other_name}, pos + 1


def codegen_list_sort(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst.sort()'/'lst.sort(key=g, reverse=...)'.

    GIOI HAN DA BIET (ke thua ban khong key): List<T>.Sort() dung
    Comparer<T>.Default - voi T la dtype so (i32/i64/f32/f64/'int' qua
    TkvInt) sap xep TANG DAN dung nhu Python list.sort() mac dinh; voi T
    la 1 class dang record se NEM InvalidOperationException luc CHAY
    (record chua implement IComparable) - danh doi thiet ke, khong phai
    bug, KHONG tu them IComparable cho record (ngoai pham vi).

    key=g (2026-08-12): xem docstring dau file cho thuat toan decorate-
    sort-undecorate qua List<ValueTuple<K,T>> - GIOI HAN THEM: khong on
    dinh (not stable) khi trung key, khac Python that (giu thu tu goc)."""
    name = stmt['name']
    _, _, ta = scope[name]
    list_type = il_list_type(ta.dtype, ctx.get('records'))
    if not stmt.get('key_name'):
        ctx['load_var_ref'](name, scope, body)
        body.append(f'    callvirt instance void {list_type}::Sort()')
        if stmt.get('reverse'):
            ctx['load_var_ref'](name, scope, body)
            body.append(f'    callvirt instance void {list_type}::Reverse()')
        return

    key_node = ('var', stmt['key_name'])
    f_ta = _resolve_func_ta(key_node, scope, ctx['func_table'], 'sort')
    if list(f_ta.func_params) != [ta.dtype]:
        raise SyntaxError(
            f"il_codegen: '{name}.sort(key={stmt['key_name']}, ...)' - chu ky key "
            f"(({', '.join(f_ta.func_params)}) -> {f_ta.dtype}) khong khop dtype phan tu "
            f"cua '{name}' ({ta.dtype!r})")
    key = id(stmt)
    try:
        _, f_idx, _ = scope[f'__sortkey{key}_f']
        _, pairs_idx, _ = scope[f'__sortkey{key}_pairs']
        _, idx_idx, _ = scope[f'__sortkey{key}_idx']
    except KeyError:
        raise SyntaxError(
            f"il_codegen: '{name}.sort(key=...)' - khong cap phat duoc local an (co the do "
            f"'{name}' chua duoc khai bao la list truoc dong nay)")
    tuple_dtypes = [f_ta.dtype, ta.dtype]
    tuple_type = il_tupleN_type(tuple_dtypes)
    pairs_list_type = f'class [mscorlib]System.Collections.Generic.List`1<{tuple_type}>'
    func_il = ctx['il_type_str'](f_ta, ctx.get('records'))
    n_params = len(f_ta.func_params)
    invoke_params = ', '.join(f'!{i}' for i in range(n_params))

    ctx['compile_funcref_arg'](('var', stmt['key_name']), f_ta, scope, body, ctx)
    body.append(f'    stloc.s {f_idx}')
    body.append(f'    newobj instance void {pairs_list_type}::.ctor()')
    body.append(f'    stloc.s {pairs_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    build_start = f"{ctx['prefix']}_sortkey{n}_build_start"
    build_end = f"{ctx['prefix']}_sortkey{n}_build_end"
    wb_start = f"{ctx['prefix']}_sortkey{n}_wb_start"
    wb_end = f"{ctx['prefix']}_sortkey{n}_wb_end"

    # pairs.Add((g(lst[i]), lst[i])) voi i = 0..len(lst)-1
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'  {build_start}:')
    body.append(f'    ldloc.s {idx_idx}')
    ctx['load_var_ref'](name, scope, body)
    body.append(f'    callvirt instance int32 {list_type}::get_Count()')
    body.append(f'    bge {build_end}')
    body.append(f'    ldloc.s {pairs_idx}')
    body.append(f'    ldloc.s {f_idx}')
    ctx['load_var_ref'](name, scope, body)
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    body.append(f'    callvirt instance !{n_params} {func_il}::Invoke({invoke_params})')
    ctx['load_var_ref'](name, scope, body)
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    body.append(f'    newobj instance void {tuple_type}::.ctor(!0, !1)')
    body.append(f'    callvirt instance void {pairs_list_type}::Add(!0)')
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {build_start}')
    body.append(f'  {build_end}:')

    # pairs.Sort() (Comparer<ValueTuple<K,T>>.Default - so sanh Item1 truoc)
    body.append(f'    ldloc.s {pairs_idx}')
    body.append(f'    callvirt instance void {pairs_list_type}::Sort()')

    # ghi lai lst[i] = pairs[i].Item2
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'  {wb_start}:')
    body.append(f'    ldloc.s {idx_idx}')
    ctx['load_var_ref'](name, scope, body)
    body.append(f'    callvirt instance int32 {list_type}::get_Count()')
    body.append(f'    bge {wb_end}')
    ctx['load_var_ref'](name, scope, body)
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    ldloc.s {pairs_idx}')
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    callvirt instance !0 {pairs_list_type}::get_Item(int32)')
    body.append(f'    ldfld !1 {tuple_type}::Item2')
    body.append(f'    callvirt instance void {list_type}::set_Item(int32, !0)')
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {wb_start}')
    body.append(f'  {wb_end}:')

    if stmt.get('reverse'):
        ctx['load_var_ref'](name, scope, body)
        body.append(f'    callvirt instance void {list_type}::Reverse()')


def codegen_list_extend(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst.extend(other)' - List<T>.AddRange(IEnumerable<T>).
    List<T> chinh no da implement IEnumerable<T> nen truyen thang duoc."""
    name, other_name = stmt['name'], stmt['other_name']
    _, _, ta = scope[name]
    _, _, ta_other = scope[other_name]
    if ta_other.shape != 'list':
        raise SyntaxError(f"il_codegen: '{name}.extend({other_name})' can '{other_name}' la list")
    if ta_other.dtype != ta.dtype:
        raise SyntaxError(
            f"il_codegen: '{name}.extend({other_name})' - dtype phan tu khac nhau "
            f"({ta.dtype!r} vs {ta_other.dtype!r})")
    list_type = il_list_type(ta.dtype, ctx.get("records"))
    ctx['load_var_ref'](name, scope, body)
    ctx['load_var_ref'](other_name, scope, body)
    body.append(
        f'    callvirt instance void {list_type}::AddRange(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


def fpw_list_sort(stmt, ctx):
    """FIRST_PASS_WALK entry: khi co 'key=g', cap phat 3 local an (delegate
    'f', List<ValueTuple<K,T>> 'pairs', chi so vong lap dung chung cho ca
    2 vong build/write-back) - giong cau truc _temps_map trong
    stdlib_functional.py."""
    key_name = stmt.get('key_name')
    if not key_name:
        return
    infer_scope = ctx['infer_scope']
    func_table = ctx['func_table']
    name = stmt['name']
    try:
        lst_ta = infer_scope[name][2]
    except KeyError:
        return
    if lst_ta.shape != 'list':
        return
    try:
        f_ta = _resolve_func_ta(('var', key_name), infer_scope, func_table, 'sort')
    except SyntaxError:
        return
    if list(f_ta.func_params) != [lst_ta.dtype]:
        return
    TypeAnn = ctx['TypeAnn']
    key = id(stmt)
    ctx['declare_named'](f'__sortkey{key}_f', f_ta)
    ctx['declare_named'](f'__sortkey{key}_pairs', TypeAnn(
        f_ta.dtype, 'list', elem_ta=TypeAnn(lst_ta.dtype, 'tuple', tuple_dtypes=[f_ta.dtype, lst_ta.dtype])))
    ctx['declare_named'](f'__sortkey{key}_idx', TypeAnn('i32', None))


def fpw_list_extend(stmt, ctx):
    pass


register_line_parser('list_sort', try_parse_list_sort)
register_line_parser('list_extend', try_parse_list_extend)
register_stmt_codegen('list_sort', codegen_list_sort)
register_stmt_codegen('list_extend', codegen_list_extend)
register_first_pass_walk('list_sort', fpw_list_sort)
register_first_pass_walk('list_extend', fpw_list_extend)
