# -*- coding: utf-8 -*-
"""json_dumps(x) (Wave 2, 2026-07-29) - CHI ho tro bien vo huong (i32/i64/
f32/f64/str) hoac list cac gia tri vo huong (khong long nhau, khong dict/
set/record) - dict/JSON-object CHUA duoc ho tro (khoa dict trong DSL nay
CHUA the gioi han kieu str khi can - ngoai pham vi Wave 2, de danh sau
neu can).

TU 2026-08-03 (Giai doan 0.2 nhom 7): dang ky qua register_expr_builtin
nen chay duoc o MOI vi tri bieu thuc ('return json_dumps(lst)',
'json_dumps(lst) + "!"'), KHONG con gioi han "chi RHS truc tiep 1 phep
gan"; duong ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN.
Day la builtin dang HAM DAU TIEN can bien cuc bo an (list can vong lap
noi chuoi) - vi vay nhom 7 phai them EXPR_BUILTIN_TEMPS, doi xung voi
EXPR_METHOD_TEMPS da co tu nhom 3 (xem il_dispatch.py).

DA HET GIOI HAN (2026-08-03): string GIO CO duoc escape - xem
_emit_escape_json_string() ben duoi, va test/verify/json_dumps_test.py doi
chieu json.dumps THAT tren nhay kep/backslash/xuong dong/tab.

Ghi chu 2026-08-04: docstring nay TRUOC DAY con ghi "string KHONG duoc
escape" mot thoi gian dai sau khi ma da sua, va PARITY_GAPS chep lai dieu
do. Mot "gioi han da biet" SAI cung la mot dang false-green: no khien
nguoi ta ne tranh thu von dang chay tot. Sua tai lieu CUNG LUC voi ma.

GIOI HAN CON LAI: thu tu khoa theo .NET Dictionary<K,V> (khong bao dam gi),
trong khi Python bao dam thu tu CHEN tu 3.7 - xem ke hoach 'thu tu chen
cua dict'."""
from il_core import IL_SCALAR
from il_dispatch import register_expr_builtin
from il_features.list_type import il_list_type, reject_if_handle_type_elem


# Cap (ky tu THAT, dang da thoat trong JSON) - THU TU QUAN TRONG: dau
# backslash phai thay TRUOC, neu khong nhung backslash do chinh cac buoc
# sau sinh ra se bi thay them 1 lan nua (bug kinh dien).
_JSON_ESCAPES = [
    (chr(92) * 2, chr(92) * 4),          # IL: ldstr "\\" -> ldstr "\\\\"
    (chr(92) + '"', chr(92)*2 + chr(92) + '"'),   # IL: ldstr "\"" -> ldstr "\\\""
    (chr(92) + 'n', chr(92)*2 + 'n'),
    (chr(92) + 'r', chr(92)*2 + 'r'),
    (chr(92) + 't', chr(92)*2 + 't'),
    (chr(92) + 'b', chr(92)*2 + 'b'),
    (chr(92) + 'f', chr(92)*2 + 'f'),
]


def _emit_escape_json_string(out):
    """Stack VAO: [string]. Stack RA: [string da thoat] - chuoi ky tu dac
    biet thanh dang hop le trong JSON (2026-08-03). Truoc do json_dumps
    KHONG thoat gi ca: 1 dau nhay kep hoac xuong dong trong du lieu la
    sinh ra JSON HONG - loi am tham, chi lo ra khi ben nhan parse.

    Dung String::Replace noi tiep (7 lan) thay vi 1 vong lap tren tung ky
    tu: it lenh IL hon, va Replace la ham BCL da toi uu.

    GIOI HAN con lai (ghi ro): cac ky tu dieu khien KHAC (U+0000..U+001F
    ngoai xuong dong / ve dau dong / tab / backspace / form-feed) KHONG
    duoc doi sang dang u-4-chu-so nhu json.dumps cua Python - hiem gap
    trong van ban that, va se can 1 vong lap tren tung ky tu (dat hon
    han 7 lan Replace)."""
    for raw, escaped in _JSON_ESCAPES:
        out.append(f'    ldstr "{raw}"')
        out.append(f'    ldstr "{escaped}"')
        out.append('    callvirt instance string [mscorlib]System.String::Replace(string, string)')


def _emit_scalar_as_json_token(dtype, kind, idx, out, ctx):
    """Day 1 chuoi JSON THAT cua 1 gia tri vo huong (dtype i32/i64/f32/f64/
    str) da co san 1 memory slot (arg/local, (kind, idx) tu scope[name])
    len stack - str duoc BOC ngoac kep (KHONG escape noi dung, xem gioi
    han o dau file), so dung LAI logic str()'s ToString+".0" fix
    (string_feature.py's compile_str_builtin) vi ToString() la instance
    method tren value type, can DIA CHI (ldarga/ldloca) - '(kind, idx)'
    hoat dong CHUNG cho ca 1 tham so/bien THAT (json_dumps(x)) LAN 1
    local AN (phan tu list trong vong lap, xem codegen ben duoi)."""
    int_dtypes, float_dtypes = ctx['int_dtypes'], ctx['float_dtypes']
    if dtype == 'str':
        ref_op = 'ldarg.s' if kind == 'arg' else 'ldloc.s'
        out.append('    ldstr "\\""')
        out.append(f'    {ref_op} {idx}')
        _emit_escape_json_string(out)
        out.append('    ldstr "\\""')
        out.append('    call string [mscorlib]System.String::Concat(string, string, string)')
        return
    if dtype == 'int':
        # Kieu 'int' (vo han chu so): ToString cua TkvInt la STATIC va da
        # xu ly ca hai duong (int64/BigInteger) - json khong co gioi han
        # do lon nen in NGUYEN gia tri, dung nhu json.dumps cua Python.
        ref_op = 'ldarg.s' if kind == 'arg' else 'ldloc.s'
        out.append(f'    {ref_op} {idx}')
        out.append('    call string TkvInt::Str(valuetype TkvInt)')
        return
    if dtype not in (int_dtypes | float_dtypes):
        raise SyntaxError(
            f"il_codegen: json_dumps() chi ho tro gia tri vo huong so/chuoi, dtype "
            f"'{dtype}' khong hop le")
    addr_op = 'ldarga.s' if kind == 'arg' else 'ldloca.s'
    out.append(f'    {addr_op} {idx}')
    out.append('    call class [mscorlib]System.Globalization.CultureInfo '
                '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
    out.append(f'    call instance string {IL_SCALAR[dtype]}::ToString(class [mscorlib]System.IFormatProvider)')
    if dtype in float_dtypes:
        # Giong het fix trong compile_str_builtin: .NET bo dau '.0' cho so
        # tron, Python/JSON json.dumps(1.0) van la "1.0" - them lai neu
        # thieu (chi xet dau '.', khong dung ky hieu khoa hoc trong pham
        # vi thuong gap).
        ctx['label_counter'][0] += 1
        n = ctx['label_counter'][0]
        has_dot_lbl = f"{ctx['prefix']}_jtokfix{n}_hasdot"
        end_lbl = f"{ctx['prefix']}_jtokfix{n}_end"
        out.append('    dup')
        out.append('    ldstr "."')
        out.append('    callvirt instance bool [mscorlib]System.String::Contains(string)')
        out.append(f'    brtrue {has_dot_lbl}')
        out.append('    ldstr ".0"')
        out.append('    call string [mscorlib]System.String::Concat(string, string)')
        out.append(f'    br {end_lbl}')
        out.append(f'  {has_dot_lbl}:')
        out.append(f'  {end_lbl}:')


def _json_arg_name(args):
    """json_dumps() nhan DUNG 1 BIEN (khong phai bieu thuc long nhau) -
    giu nguyen gioi han cua ban cu (regex '(\\w+)'), vi codegen can
    (kind, idx) memory slot THAT cua bien do de lay DIA CHI (ldarga/ldloca -
    ToString() la instance method tren value type)."""
    if len(args) != 1 or args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: json_dumps() can DUNG 1 tham so la 1 BIEN (vd "
            "'json_dumps(lst)') - bieu thuc long nhau chua ho tro")
    return args[0][1]


def temps_json_dumps(node, ctx):
    """FIRST PASS (nhom 7, 2026-08-03): hidden local cho vong lap noi chuoi.

    KHOA = id(node[2]) tuc id cua DANH SACH THAM SO, KHONG phai id(node):
    chu ky codegen cua builtin la (args, scope, out, dtype, ctx) - KHONG
    co 'node' - va args CHINH LA node[2] (cung 1 object AST, parse duy
    nhat 1 lan roi dung lai o pass 2). Dung no lam khoa giup 2 pass khop
    nhau MA KHONG phai doi chu ky cua ca 12 builtin da dang ky.

    '__jsond..._res' la bien KET QUA (ban cu ghi thang vao bien dich; gio
    la bieu thuc nen can cho chua rieng roi 'ldloc' o cuoi). idx/elem chi
    can khi tham so la list (truong hop vo huong khong co vong lap)."""
    args = node[2]
    arg_name = _json_arg_name(args)
    try:
        _, _, arg_ta = ctx['infer_scope'][arg_name]
    except KeyError:
        return
    ctx['declare_named'](f'__jsond{id(args)}_res', ctx['TypeAnn']('str', None))
    if arg_ta.shape == 'list':
        if arg_ta.elem_ta is not None:
            raise SyntaxError(
                "il_codegen: json_dumps() chua ho tro list long nhau (chi list cac gia "
                "tri vo huong)")
        ctx['declare_named'](f'__jsond{id(args)}_idx', ctx['TypeAnn']('i32', None))
        ctx['declare_named'](f'__jsond{id(args)}_elem', ctx['TypeAnn'](arg_ta.dtype, None))
    elif arg_ta.shape == 'dict':
        # dict -> JSON object (2026-08-03). KHOA phai la 'str' (JSON khong
        # co khoa kieu so). Duyet qua List<KeyValuePair<K,V>> - dung ky
        # thuat cua dict.items()/set.to_list(), khong viet Enumerator tay.
        if arg_ta.elem_ta is not None:
            raise SyntaxError(
                "il_codegen: json_dumps() chua ho tro dict long nhau (gia tri phai la "
                "vo huong)")
        if arg_ta.key_dtype != 'str':
            raise SyntaxError(
                f"il_codegen: json_dumps() can dict co KHOA kieu 'str' (JSON khong co "
                f"khoa kieu so) - '{arg_name}' co khoa {arg_ta.key_dtype!r}")
        kv_ta = ctx['TypeAnn'](arg_ta.dtype, 'dict_kvpair', 'str')
        ctx['declare_named'](f'__jsond{id(args)}_idx', ctx['TypeAnn']('i32', None))
        ctx['declare_named'](f'__jsond{id(args)}_elem', ctx['TypeAnn'](arg_ta.dtype, None))
        ctx['declare_named'](f'__jsond{id(args)}_items',
                             ctx['TypeAnn'](arg_ta.dtype, 'list', elem_ta=kv_ta))
        ctx['declare_named'](f'__jsond{id(args)}_pair', kv_ta)
    elif arg_ta.shape is not None:
        raise SyntaxError(
            f"il_codegen: json_dumps() hien CHI ho tro bien vo huong (i32/i64/f32/f64/str), "
            f"list cac gia tri vo huong, hoac dict[str, vo huong] - '{arg_name}' co "
            f"shape={arg_ta.shape!r} chua duoc ho tro (vd set/record)")


def _push_json_dumps_list(args, arg_name, scope, out, ctx):
    list_ta = scope[arg_name][2]
    reject_if_handle_type_elem(list_ta, ctx.get('extern_class_defs'), 'json_dumps')
    # reject o tren da chan handle type khi ctx co extern_class_defs; neu ctx
    # thieu key nay se roi ve message loi cu mo ho hon - xem
    # test/verify/list_handle_type_reject_test.py
    list_type = il_list_type(list_ta.dtype, ctx.get('records'))
    load_var_ref = ctx['load_var_ref']
    _, res_idx, _ = scope[f'__jsond{id(args)}_res']
    _, idx_idx, _ = scope[f'__jsond{id(args)}_idx']
    _, elem_idx, _ = scope[f'__jsond{id(args)}_elem']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_jsond{n}_start"
    skip_comma_lbl = f"{ctx['prefix']}_jsond{n}_skipcomma"
    end_lbl = f"{ctx['prefix']}_jsond{n}_end"

    out.append('    ldstr "["')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')

    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    load_var_ref(arg_name, scope, out)
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append(f'    bge {end_lbl}')
    # dau phan tu (idx > 0): them dau phay truoc.
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    beq {skip_comma_lbl}')
    out.append(f'    ldloc.s {res_idx}')
    out.append('    ldstr ","')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append(f'    stloc.s {res_idx}')
    out.append(f'  {skip_comma_lbl}:')
    # elem = list[idx]
    load_var_ref(arg_name, scope, out)
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    out.append(f'    stloc.s {elem_idx}')
    # res = res + token(elem)
    out.append(f'    ldloc.s {res_idx}')
    _emit_scalar_as_json_token(list_ta.dtype, 'local', elem_idx, out, ctx)
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append(f'    stloc.s {res_idx}')
    # idx += 1; loop
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {res_idx}')
    out.append('    ldstr "]"')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')



def _push_json_dumps_dict(args, arg_name, scope, out, ctx):
    """dict[str, vo huong] -> '{"k":v,...}'. Duyet qua List<KeyValuePair>
    (1 newobj) roi lap theo chi so - dung cach cua dict.items()."""
    dict_ta = scope[arg_name][2]
    kvp_type = (f'valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2'
                f'<string, {IL_SCALAR[dict_ta.dtype]}>')
    items_type = f'class [mscorlib]System.Collections.Generic.List`1<{kvp_type}>'
    _, res_idx, _ = scope[f'__jsond{id(args)}_res']
    _, idx_idx, _ = scope[f'__jsond{id(args)}_idx']
    _, elem_idx, _ = scope[f'__jsond{id(args)}_elem']
    _, items_idx, _ = scope[f'__jsond{id(args)}_items']
    _, pair_idx, _ = scope[f'__jsond{id(args)}_pair']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_jsondd{n}_start"
    skip_comma_lbl = f"{ctx['prefix']}_jsondd{n}_skipcomma"
    end_lbl = f"{ctx['prefix']}_jsondd{n}_end"

    ctx['load_var_ref'](arg_name, scope, out)
    out.append(f'    newobj instance void {items_type}::.ctor(class '
               '[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    stloc.s {items_idx}')
    out.append('    ldstr "{"')
    out.append(f'    stloc.s {res_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {idx_idx}')

    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    ldloc.s {items_idx}')
    out.append(f'    callvirt instance int32 {items_type}::get_Count()')
    out.append(f'    bge {end_lbl}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    beq {skip_comma_lbl}')
    out.append(f'    ldloc.s {res_idx}')
    out.append('    ldstr ","')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append(f'    stloc.s {res_idx}')
    out.append(f'  {skip_comma_lbl}:')
    out.append(f'    ldloc.s {items_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append(f'    callvirt instance !0 {items_type}::get_Item(int32)')
    out.append(f'    stloc.s {pair_idx}')
    # res = res + "\"" + escape(key) + "\":"
    out.append(f'    ldloc.s {res_idx}')
    out.append('    ldstr "\\""')
    out.append(f'    ldloca.s {pair_idx}')
    out.append(f'    call instance !0 {kvp_type}::get_Key()')
    _emit_escape_json_string(out)
    out.append('    ldstr "\\":"')
    out.append('    call string [mscorlib]System.String::Concat(string, string, string, string)')
    out.append(f'    stloc.s {res_idx}')
    # elem = pair.Value; res = res + token(elem)
    out.append(f'    ldloca.s {pair_idx}')
    out.append(f'    call instance !1 {kvp_type}::get_Value()')
    out.append(f'    stloc.s {elem_idx}')
    out.append(f'    ldloc.s {res_idx}')
    _emit_scalar_as_json_token(dict_ta.dtype, 'local', elem_idx, out, ctx)
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append(f'    stloc.s {res_idx}')
    out.append(f'    ldloc.s {idx_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {idx_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {res_idx}')
    out.append('    ldstr "}"')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')


def push_json_dumps(args, scope, out, dtype, ctx):
    arg_name = _json_arg_name(args)
    _, _, arg_ta = scope[arg_name]
    if arg_ta.shape == 'list':
        return _push_json_dumps_list(args, arg_name, scope, out, ctx)
    if arg_ta.shape == 'dict':
        return _push_json_dumps_dict(args, arg_name, scope, out, ctx)
    kind, idx, _ = scope[arg_name]
    _emit_scalar_as_json_token(arg_ta.dtype, kind, idx, out, ctx)


register_expr_builtin('json_dumps', push_json_dumps, 'str',
                       temps_fn=temps_json_dumps)
