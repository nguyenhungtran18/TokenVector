# -*- coding: utf-8 -*-
"""str()/fmt_float() (Phase "tach tkvc.exe thanh plugin", 2026-08-12) -
TACH RA khoi string_feature.py (file do GIU LAI compile_index_str/
compile_len_str/compile_binop_concat/compile_compare_str - ngu nghia
kieu 'str' CO BAN cua ngon ngu, khong tach duoc, xem docstring dau file
do). 2 ham nay la BUILTIN DANG HAM ('str(x)'/'fmt_float(x,n)'), thuoc
nhom "thu vien" tach duoc theo thiet ke o
docs/superpowers/specs/2026-08-12-tkvc-plugin-architecture-design.md
muc 3.2. Ke ca cac ham phu chi phuc vu rieng str() (_is_bool_shaped,
_str_of_slot, _temps_str_builtin) cung chuyen theo - chung KHONG duoc
dung boi 4 ham con lai o string_feature.py (da xac minh qua grep truoc
khi tach, xem task-8-report.md)."""
from il_core import IL_SCALAR
from il_dispatch import register_expr_builtin, EXPR_BUILTIN_TEMPS


_BOOL_SHAPED_CALL_NAMES = ('all', 'any')
_BOOL_SHAPED_METHOD_NAMES = ('startswith', 'endswith')


def _is_bool_shaped(node):
    """True neu bieu thuc 'node' co dtype='i32' nhung MANG NGHIA logic
    (Python se in "True"/"False", khong phai so). compare/boolop/not/in
    LUON tra ve i32 0/1 (xem _infer_dtype trong il_codegen.py - co tinh
    khai cung de tranh AccessViolationException voi TkvInt); all()/any()
    va .startswith()/.endswith() cung tra i32 0/1 cung ly do (dang ky
    dtype='i32' trong stdlib_aggregates.py / string_methods_batch3.py).
    KHONG bao gom .find() - do la CHI SO that, khong phai co/khong."""
    tag = node[0]
    if tag in ('compare', 'boolop', 'not', 'in'):
        return True
    if tag == 'call' and node[1] in _BOOL_SHAPED_CALL_NAMES:
        return True
    if tag in ('method_call', 'method_call_expr') and node[2] in _BOOL_SHAPED_METHOD_NAMES:
        return True
    return False


def compile_str_builtin(args, scope, out, dtype, ctx):
    """Nhanh 'str(x)' cua _expr_call - chuyen 1 bien so (f32/f64/i32/i64)
    sang string. GIOI HAN THAT (chua ho tro bieu thuc phuc tap):
    ToString() la INSTANCE method tren value type - CIL can DIA CHI
    (managed pointer, ldarga/ldloca), khong the lay dia chi cua 1 gia
    tri TAM tren stack (ket qua 1 bieu thuc bat ky) - CHI bien don da co
    san 1 memory slot (arg/local) moi lay dia chi truc tiep duoc."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: str() chi nhan dung 1 tham so")
    arg = args[0]
    int_dtypes, float_dtypes = ctx['int_dtypes'], ctx['float_dtypes']
    if ctx['infer_dtype'](arg, scope, ctx.get('func_table')) == 'int':
        # Kieu 'int' (vo han chu so) - Str() la STATIC nhan gia tri nen
        # KHONG vuong han che "phai co dia chi" cua ToString() o duoi:
        # 'str(a * b)' chay duoc thang, khong can local an.
        import il_features.int_type as _int_type
        return _int_type.compile_str_of_int(arg, scope, out, ctx)
    if arg[0] != 'var':
        # moc 7 (2026-08-05): duong DUY NHAT, qua TkvStr::* - cac ham do
        # la STATIC va nhan GIA TRI nen 'str(a + b)' khong con can local
        # AN nao (xem docstring cua tkvstr.py). Nhanh __strtmp cu ben
        # duoi chi con giu cho dtype chua co trong bang cua TkvStr.
        import il_features.tkvstr as _tkvstr
        # 'infer_literal_dtype' CHI co trong ctx cua pass 1 (first-pass suy
        # kieu, xem print_feature.py) - pass 2 (codegen that) KHONG co key
        # nay. Truoc day index truc tiep ('ctx[...]') gay KeyError CRASH
        # NOI BO khi 'infer_dtype' tra None o pass 2 (vd str(lst[-1:5]) -
        # ket qua slice co shape='list', khong phai scalar) - .get() voi
        # fallback None de roi xuong nhanh duoi, tu bao SyntaxError co
        # kiem soat ("khong suy duoc kieu") thay vi crash khong debug duoc.
        _d = (ctx['infer_dtype'](arg, scope, ctx.get('func_table'), ctx.get('records'),
                                  ctx.get('record_methods'))
              or ctx.get('infer_literal_dtype', lambda n: None)(arg))
        if _d in ('i32', 'i64', 'f32', 'f64', 'str'):
            ctx['compile_expr'](arg, scope, out, _d, ctx)
            if _d == 'i32' and _is_bool_shaped(arg):
                return _tkvstr.emit_to_str('bool', out, ctx)
            return _tkvstr.emit_to_str(_d, out, ctx)
        # 2026-08-03: 'str(<bieu thuc>)' (vd str(i + 1), str(len(xs))) -
        # ToString() la instance method tren value type nen CIL can DIA
        # CHI; gia tri tam tren stack khong co dia chi. Cach lam: do ket
        # qua bieu thuc vao 1 local AN (khai bao san boi _temps_str_builtin
        # o first-pass) roi lay dia chi cua local do - dung 1 lan, khong
        # doi ngu nghia.
        tmp_name = f'__strtmp{id(arg)}'
        try:
            tmp_kind, tmp_idx, tmp_ta = scope[tmp_name]
        except SyntaxError:
            raise SyntaxError(
                "il_codegen: str(<bieu thuc>) khong suy duoc kieu cua bieu thuc "
                "- gan ra 1 bien truoc roi str() bien do")
        ctx['compile_expr'](arg, scope, out, tmp_ta.dtype, ctx)
        out.append(f'    stloc.s {tmp_idx}')
        return _str_of_slot('local', tmp_idx, tmp_ta, out, ctx, int_dtypes, float_dtypes)
    var_kind, var_idx, var_ta = scope[arg[1]]
    if var_ta.dtype == 'str' and var_ta.shape is None:
        # str(s) khi 's' DA LA string - Python that: str(mot_chuoi) tra
        # ve CHINH chuoi do (khong doi) - can THEM (Wave 2, 2026-07-29)
        # de f-string macro (xem fstring.py) co the BOC DONG LOAT moi
        # {var} bang str(var) ma khong can biet truoc dtype cua var luc
        # macro-expand (van ban, TRUOC first-pass suy kieu).
        ctx['load_var_ref'](arg[1], scope, out)
        return
    if var_kind == 'const' and var_ta.shape is None and var_ta.dtype in (int_dtypes | float_dtypes):
        # HANG SO module ('LIMIT = 50' o dau file): scope giu THANG gia tri
        # o cho cua chi so local, nen duong ToString cu sinh 'ldloca.s 50'
        # = dia chi local so 50 (khong ton tai) -> InvalidProgramException
        # LUC CHAY (bug that, tim qua cong cu codestat 2026-08-03). Gia tri
        # da biet luc bien dich nen sinh thang chuoi, dinh dang theo Python
        # (float luon co phan thap phan).
        text = (str(int(var_idx)) if var_ta.dtype in int_dtypes
                else repr(float(var_idx)))
        out.append(f'    ldstr "{text}"')
        return
    if var_ta.dtype == 'Exception' or (ctx and var_ta.dtype in ctx.get('records', {}) and ctx.get('record_bases', {}).get(var_ta.dtype) == 'Exception'):
        ctx['load_var_ref'](arg[1], scope, out)
        out.append('    callvirt instance string [mscorlib]System.Exception::get_Message()')
        return
    if var_ta.dtype == 'object' or (ctx and var_ta.dtype in ctx.get('records', {})):
        ctx['load_var_ref'](arg[1], scope, out)
        out.append('    callvirt instance string [mscorlib]System.Object::ToString()')
        return
    if var_ta.dtype not in (int_dtypes | float_dtypes) or var_ta.shape is not None:
        raise SyntaxError(
            f"il_codegen: str() chi nhan bien so vo huong (f32/f64/i32/i64), "
            f"'{arg[1]}' khong hop le (dtype={var_ta.dtype}, shape={var_ta.shape})")
    # moc 7: bien don cung di CHUNG duong voi bieu thuc - _str_of_slot cu
    # (ToString + va ".0" tai cho) da bi thay han, hai duong dinh dang so
    # thuc song song chac chan lech nhau.
    import il_features.tkvstr as _tkvstr
    ctx['load_var_ref'](arg[1], scope, out)
    return _tkvstr.emit_to_str(var_ta.dtype, out, ctx)


def _str_of_slot(var_kind, var_idx, var_ta, out, ctx, int_dtypes, float_dtypes):
    """Sinh ToString(InvariantCulture) cho 1 SLOT (arg/local) da co dia
    chi - dung chung cho ca 'str(bien)' va 'str(bieu thuc)' (bieu thuc da
    duoc do vao 1 local an truoc do).

    BUG THAT sua 2026-08-11 (phat hien khi verify .format(), xem
    string_format.py): dtype='int' (TkvInt, so nguyen vo han chu so cua
    DSL) truoc day RƠI vao nhanh chung ben duoi (gia dinh MOI dtype so co
    instance method 'ToString(IFormatProvider)') -> MissingMethodException
    THAT luc chay ('str(1)', 'str(i+1)' voi i la 'int' deu vo). TkvInt
    KHONG co ToString(IFormatProvider) - chi co ham STATIC rieng
    'TkvInt::Str(valuetype TkvInt)' (xem int_type.py's compile_str_of_int)."""
    if var_ta.dtype == 'int':
        import il_features.int_type as _int_type
        _int_type.ensure_class(ctx)
        out.append(f'    {"ldarg.s" if var_kind == "arg" else "ldloc.s"} {var_idx}')
        out.append(f'    call string {_int_type.TKVINT_CLASS}::Str(valuetype {_int_type.TKVINT_CLASS})')
        return
    if var_ta.dtype == 'object':
        out.append(f'    {"ldarg.s" if var_kind == "arg" else "ldloc.s"} {var_idx}')
        out.append('    callvirt instance string [mscorlib]System.Object::ToString()')
        return
    out.append(f'    {"ldarga.s" if var_kind == "arg" else "ldloca.s"} {var_idx}')
    if var_ta.dtype == 'f64':
        # Dinh dang "R" (round-trip) - Double.ToString() MAC DINH cua .NET
        # Framework chi in 15 chu so co nghia, nen str(0.1 + 0.2) ra "0.3"
        # trong khi Python in "0.30000000000000004" (repr ngan nhat DOC
        # LAI DUNG). Bug that tim qua tools/tkvcalc.tkv - "R" khop Python
        # o moi truong hop da thu.
        out.append('    ldstr "R"')
        out.append('    call class [mscorlib]System.Globalization.CultureInfo '
                    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
        out.append('    call instance string [mscorlib]System.Double'
                    '::ToString(string, class [mscorlib]System.IFormatProvider)')
    else:
        out.append('    call class [mscorlib]System.Globalization.CultureInfo '
                    '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
        out.append(f'    call instance string {IL_SCALAR[var_ta.dtype]}'
                    '::ToString(class [mscorlib]System.IFormatProvider)')
    if var_ta.dtype in float_dtypes:
        # .NET Single/Double.ToString() bo dau cham thap phan cho so
        # tron (vd 0.0f -> "0"), nhung Python str(0.0) LUON co ".0" -
        # bug that phat hien qua test doi chieu CPython (celsius=0.0 ->
        # exe in "0C", CPython in "0.0C"). Them ".0" neu ket qua CHUA co
        # dau cham (chi can xet '.' vi khong dung ky hieu khoa hoc 'E' o
        # day - ToString mac dinh cho float32/64 thong thuong khong tu
        # chuyen sang dang E trong khoang gia tri thuong gap).
        ctx['label_counter'][0] += 1
        n = ctx['label_counter'][0]
        has_dot_lbl = f"{ctx['prefix']}_strfix{n}_hasdot"
        end_lbl = f"{ctx['prefix']}_strfix{n}_end"
        out.append('    dup')
        out.append('    ldstr "."')
        out.append('    callvirt instance bool [mscorlib]System.String::Contains(string)')
        out.append(f'    brtrue {has_dot_lbl}')
        out.append('    ldstr ".0"')
        out.append('    call string [mscorlib]System.String::Concat(string, string)')
        out.append(f'    br {end_lbl}')
        out.append(f'  {has_dot_lbl}:')
        out.append(f'  {end_lbl}:')


def _temps_str_builtin(node, ctx):
    """First-pass: 'str(<bieu thuc>)' can 1 local AN giu ket qua bieu thuc
    (xem compile_str_builtin). Khoa theo id(arg) - CHINH node doi so, on
    dinh giua 2 pass. Khong suy duoc dtype thi bo qua: pass 2 se bao loi
    RO RANG thay vi sinh ma sai."""
    args = node[2]
    if len(args) != 1 or args[0][0] == 'var':
        return
    arg = args[0]
    d = (ctx['infer_dtype'](arg, ctx['infer_scope'], ctx['func_table'], ctx['records'],
                            ctx.get('record_methods'))
         or ctx['infer_literal_dtype'](arg))
    if d is None or d == 'str':
        return
    ctx['declare_named'](f'__strtmp{id(arg)}', ctx['TypeAnn'](d, None))


# (2026-08-12) Truoc day 'str' co duong dispatch RIENG trong _expr_call
# (if name == 'str': ...), nen moc temps o first-pass phai dang ky THANG
# vao EXPR_BUILTIN_TEMPS (khong qua register_expr_builtin, ham do khong
# nhan temps_fn tu 1 lenh goi rieng cho 'str'). Gio 'str' DA chuyen sang
# register_expr_builtin(...) o cuoi file (dispatch chung EXPR_BUILTIN_CODEGEN),
# nhung temps_fn van dang ky THANG o day (khong truyen qua tham so
# temps_fn cua register_expr_builtin) - GIU NGUYEN cach cu vi hanh vi
# giong het nhau (ca 2 deu ghi vao cung dict EXPR_BUILTIN_TEMPS['str']),
# doi lai chi them rui ro khong can thiet.
EXPR_BUILTIN_TEMPS['str'] = _temps_str_builtin


def compile_fmt_float(args, scope, out, dtype, ctx):
    """Nhanh 'fmt_float(x, n)' cua _expr_call (Wave 3, 2026-07-29) - dung
    cho f-string format spec '{x:.2f}' (xem fstring.py's _fstring_to_concat_expr)
    VA dung truc tiep duoc trong code neu can. GIOI HAN GIONG str():
    'x' CHI 1 BIEN don (can dia chi de goi ToString - value type), 'n'
    CHI hang so nguyen KHONG AM tai compile-time (tro thanh literal
    "F{n}" ngay trong IL, khong dung duoc bien dong)."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: fmt_float(x, n) can dung 2 tham so")
    arg, n_node = args
    if arg[0] != 'var':
        raise SyntaxError(
            "il_codegen: fmt_float() hien CHI ho tro 1 BIEN don (vd fmt_float(x, 2)), "
            "chua ho tro bieu thuc phuc tap")
    if n_node[0] != 'num' or '.' in n_node[1]:
        raise SyntaxError(
            "il_codegen: fmt_float(x, n) - 'n' phai la hang so nguyen KHONG AM tai "
            "compile-time (vd 2), khong ho tro bieu thuc dong")
    n = int(n_node[1])
    var_kind, var_idx, var_ta = scope[arg[1]]
    int_dtypes, float_dtypes = ctx['int_dtypes'], ctx['float_dtypes']
    if var_ta.dtype not in (int_dtypes | float_dtypes) or var_ta.shape is not None:
        raise SyntaxError(
            f"il_codegen: fmt_float() chi nhan bien so vo huong (f32/f64/i32/i64), "
            f"'{arg[1]}' khong hop le (dtype={var_ta.dtype}, shape={var_ta.shape})")
    addr_op = 'ldarga.s' if var_kind == 'arg' else 'ldloca.s'
    out.append(f'    {addr_op} {var_idx}')
    out.append(f'    ldstr "F{n}"')
    out.append('    call class [mscorlib]System.Globalization.CultureInfo '
                '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
    out.append(f'    call instance string {IL_SCALAR[var_ta.dtype]}'
                '::ToString(string, class [mscorlib]System.IFormatProvider)')


register_expr_builtin('str', compile_str_builtin, 'str')
register_expr_builtin('fmt_float', compile_fmt_float, 'str')
