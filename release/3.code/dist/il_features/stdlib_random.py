# -*- coding: utf-8 -*-
"""Module random (2026-07-29) - soan nhap boi Gemini, Claude sua 3 bug
tich hop truoc khi noi vao he thong that (xem STATUS.md): scope la 1
_Scope object tra ve tuple (kind, idx, TypeAnn) qua __getitem__, KHONG
phai dict co key 'type' voi gia tri dang chuoi 'list[i32]' - da sua lai
dung quy uoc cac il_features/*.py khac (vd list_type.py's
compile_index_list). il_list_type() cung can tham so `records` thu 2
(cho truong hop list chua 1 class dang record) - thieu tham so nay se
sai khi dtype phan tu la record.

QUYET DINH KIEN TRUC DA CHOT: khong dung static field cap class (core
chua ho tro). Moi lan goi random()/randint()/choice() khoi tao 1
System.Random MOI. GIOI HAN DA BIET (danh doi thiet ke, khong phai bug):
.NET Random() mac dinh seed theo Environment.TickCount (do phan giai
~15ms tren Windows) - 2 lenh goi LIEN TIEP RAT NHANH trong 1 vong lap co
the co CUNG seed -> tra ve CUNG 1 SO."""
from il_features.list_type import il_list_type
from il_dispatch import register_expr_builtin


def compile_random(args, scope, out, dtype, ctx):
    """random() - tra ve so thuc ngau nhien trong [0.0, 1.0), giong
    Python random.random()."""
    if len(args) != 0:
        raise SyntaxError("il_codegen: random() khong nhan tham so nao")
    out.append('    newobj instance void [mscorlib]System.Random::.ctor()')
    out.append('    callvirt instance float64 [mscorlib]System.Random::NextDouble()')
    ctx['widen_if_needed']('f64', dtype, out)


def compile_randint(args, scope, out, dtype, ctx):
    """randint(a, b) - so nguyen ngau nhien trong doan DONG [a, b].
    CHU Y NGU NGHIA: Python randint(a,b) bao gom CA b; .NET
    Random.Next(min, max) la doan NUA MO [min, max) - cong them 1 vao
    tham so b truoc khi goi Next() de bu lai khac biet nay."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: randint(a, b) chi nhan dung 2 tham so")
    compile_expr = ctx['compile_expr']
    out.append('    newobj instance void [mscorlib]System.Random::.ctor()')
    compile_expr(args[0], scope, out, 'i32', ctx)
    compile_expr(args[1], scope, out, 'i32', ctx)
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append('    callvirt instance int32 [mscorlib]System.Random::Next(int32, int32)')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_uniform(args, scope, out, dtype, ctx):
    """uniform(a, b) - so thuc ngau nhien trong [a, b], giong Python
    random.uniform(a,b). Cong thuc: a + NextDouble() * (b - a)."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: uniform(a, b) chi nhan dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[0], scope, out, 'f64', ctx)
    out.append('    newobj instance void [mscorlib]System.Random::.ctor()')
    out.append('    callvirt instance float64 [mscorlib]System.Random::NextDouble()')
    compile_expr(args[1], scope, out, 'f64', ctx)
    compile_expr(args[0], scope, out, 'f64', ctx)
    out.append('    sub')
    out.append('    mul')
    out.append('    add')
    ctx['widen_if_needed']('f64', dtype, out)


def compile_randrange(args, scope, out, dtype, ctx):
    """randrange(a, b) - so nguyen ngau nhien trong doan NUA MO [a, b),
    giong Python random.randrange(a,b). Khac randint(a,b) (dong ca 2 dau)
    dung chinh Random.Next(min,max) khong can cong 1."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: randrange(a, b) chi nhan dung 2 tham so")
    compile_expr = ctx['compile_expr']
    out.append('    newobj instance void [mscorlib]System.Random::.ctor()')
    compile_expr(args[0], scope, out, 'i32', ctx)
    compile_expr(args[1], scope, out, 'i32', ctx)
    out.append('    callvirt instance int32 [mscorlib]System.Random::Next(int32, int32)')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_choice(args, scope, out, dtype, ctx):
    """choice(lst) - chon 1 phan tu ngau nhien tu list. GIOI HAN DA BIET:
    CHI nhan 1 BIEN list don (khong ho tro bieu thuc phuc tap) - can 2
    THAM CHIEU rieng den CUNG 1 list (1 lay Count, 1 lay Item), an toan
    voi 1 bien don nhung co the sai (tinh lai/side-effect) neu la 1 bieu
    thuc phuc tap.

    THU TU STACK (da xac minh dung qua doi chieu voi compile_index_list):
    load list_ref (giu duoi cung cho get_Item sau) -> newobj Random ->
    load list_ref LAN 2 + get_Count() (dinh Random) -> Random::Next(int32)
    tieu thu [Random, count] dung thu tu goi instance method (this=Random,
    arg=count) -> con lai [list_ref, index] dung khop get_Item(int32)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: choice(lst) chi nhan dung 1 tham so")
    if args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: choice(lst) chi ho tro tham so la 1 BIEN list don, "
            "khong ho tro bieu thuc phuc tap")
    var_name = args[0][1]
    _, _, ta = scope[var_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: choice(lst) can '{var_name}' la list (shape={ta.shape!r})")
    list_type = il_list_type(ta.dtype, (ctx or {}).get('records'))
    load_var_ref = ctx['load_var_ref']

    load_var_ref(var_name, scope, out)
    out.append('    newobj instance void [mscorlib]System.Random::.ctor()')
    load_var_ref(var_name, scope, out)
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append('    callvirt instance int32 [mscorlib]System.Random::Next(int32)')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    # KHONG tu goi widen_if_needed o day (khac 4 ham random/randint/
    # uniform/randrange o tren): dtype tra ve cua choice() PHU THUOC tham
    # so (dtype phan tu list), nen phai dang ky qua return_dtype_fn
    # (_choice_dtype_fn duoi day) - _expr_call's dispatch (il_codegen.py)
    # se TU widen dua tren dtype_fn nay SAU KHI goi ham nay, giong het
    # cach push_sum/push_min_list/push_max_list cua stdlib_aggregates.py
    # lam (KHONG tu widen ben trong than ham). Neu giu ca 2 (tu widen o
    # day VA dang ky return_dtype_fn) se bi widen 2 LAN chong nhau (dung
    # bug Task 3 tung gap voi stdlib_math).


def _choice_dtype_fn(args, scope):
    """dtype tra ve cua choice(lst) PHU THUOC dtype phan tu 'lst' - khong
    co dinh, giong het cach _agg_elem_dtype cua stdlib_aggregates.py xu
    ly cho sum/min/max. Tra None neu chua suy duoc (fallback ve None ->
    _expr_call se khong widen gi them trong truong hop hiem gap loi)."""
    if len(args) != 1 or args[0][0] != 'var':
        return None
    try:
        return scope[args[0][1]][2].dtype
    except KeyError:
        return None


register_expr_builtin('random', compile_random, None)
register_expr_builtin('randint', compile_randint, None)
register_expr_builtin('uniform', compile_uniform, None)
register_expr_builtin('randrange', compile_randrange, None)
register_expr_builtin('choice', compile_choice, None, return_dtype_fn=_choice_dtype_fn)
