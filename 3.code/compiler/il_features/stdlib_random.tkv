# -*- coding: utf-8 -*-
"""Module random (2026-07-29) - soan nhap boi Gemini, Claude sua 3 bug
tich hop truoc khi noi vao he thong that (xem STATUS.md): scope la 1
_Scope object tra ve tuple (kind, idx, TypeAnn) qua __getitem__, KHONG
phai dict co key 'type' voi gia tri dang chuoi 'list[i32]' - da sua lai
dung quy uoc cac il_features/*.py khac (vd list_type.py's
compile_index_list). il_list_type() cung can tham so `records` thu 2
(cho truong hop list chua 1 class dang record) - thieu tham so nay se
sai khi dtype phan tu la record.

KIEN TRUC HIEN TAI (cap nhat batch 5.5, 2026-08-12 - Task 1+2 random
seeding): dung 1 static field cap class TkvRandom::rng - 1 System.Random
DUNG CHUNG cho toan chuong trinh, khoi tao LUOI (lazy) tai lan goi
Instance() DAU TIEN (xem ensure_class/Instance() ben duoi). random()/
randint()/uniform()/randrange()/choice() deu goi qua Instance() nen dung
CHUNG 1 instance - khac ban dau (moi lan goi khoi tao Random MOI, de bi
trung seed theo Environment.TickCount khi goi lien tiep rat nhanh).
seed(n) (Task 2, codegen_seed ben duoi) goi TkvRandom::SetSeed(int32) -
gan lai field static rng = new Random(n), cho phep dat lai chuoi so ngau
nhien mot cach xac dinh (cung seed -> cung dãy gia tri)."""
from il_features.list_type import il_list_type
from il_dispatch import register_expr_builtin, register_call_stmt_temps

_HELPER_CLASS = 'TkvRandom'


def ensure_class(ctx):
    """Sinh 1 lan/chuong trinh (dedupe qua ctx['emitted_types']) class
    tinh TkvRandom giu 1 System.Random DUNG CHUNG toan chuong trinh -
    khoi tao LUOI (neu chua tung goi seed()) tai lan goi Instance() DAU
    TIEN, giong het mau TkvLogging (logging_feature.py's ensure_class)."""
    emitted = ctx.get('emitted_types')
    if emitted is None or _HELPER_CLASS in emitted:
        return
    emitted.add(_HELPER_CLASS)
    ctx['extra_classes'].append([
        f'.class public auto ansi beforefieldinit {_HELPER_CLASS} extends [mscorlib]System.Object',
        '{',
        '  .field private static class [mscorlib]System.Random rng',
        '  .method public static class [mscorlib]System.Random Instance() cil managed',
        '  {',
        '    .maxstack 8',
        f'    ldsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '    brtrue TKVRANDOM_HAVE',
        '    newobj instance void [mscorlib]System.Random::.ctor()',
        f'    stsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '  TKVRANDOM_HAVE:',
        f'    ldsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '    ret',
        '  }',
        '  .method public static void SetSeed(int32 n) cil managed',
        '  {',
        '    .maxstack 8',
        '    ldarg.0',
        '    newobj instance void [mscorlib]System.Random::.ctor(int32)',
        f'    stsfld class [mscorlib]System.Random {_HELPER_CLASS}::rng',
        '    ret',
        '  }',
        '}',
    ])


def compile_random(args, scope, out, dtype, ctx):
    """random() - tra ve so thuc ngau nhien trong [0.0, 1.0), giong
    Python random.random()."""
    if len(args) != 0:
        raise SyntaxError("il_codegen: random() khong nhan tham so nao")
    ensure_class(ctx)
    out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
    out.append('    callvirt instance float64 [mscorlib]System.Random::NextDouble()')
    ctx['widen_if_needed']('f64', dtype, out)


def compile_randint(args, scope, out, dtype, ctx):
    """randint(a, b) - so nguyen ngau nhien trong doan DONG [a, b].
    CHU Y NGU NGHIA: Python randint(a,b) bao gom CA b; .NET
    Random.Next(min, max) la doan NUA MO [min, max) - cong them 1 vao
    tham so b truoc khi goi Next() de bu lai khac biet nay."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: randint(a, b) chi nhan dung 2 tham so")
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
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
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    compile_expr(args[0], scope, out, 'f64', ctx)
    out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
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
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
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
    ensure_class(ctx)

    load_var_ref(var_name, scope, out)
    out.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
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


def _fisher_yates_prefix(body, list_type, load_list_fn, i_idx, j_idx, tmp_idx,
                          k_upper_loader, ctx, label_prefix):
    """Vong lap Fisher-Yates TANG DAN dung chung cho shuffle(lst) (xao het
    n phan tu) va sample(lst, k) (xao k phan tu dau tren 1 ban sao) - xem
    ghi chu chinh sua thuat toan tai dau file/spec 2026-08-12 (pseudocode
    goc dung vong GIAM DAN la SAI, o day dung TANG DAN: for i in [0..k-1]:
    j = Instance().Next(i, n); swap arr[i], arr[j] - n LUON la do dai THAT
    cua list dang duoc thao tac (load_list_fn), k la so buoc can xao (bang
    n cho shuffle, la tham so rieng cho sample). i/j/tmp la 3 local AN i32/
    T da duoc khai bao san o first-pass (khoa theo id(args), xem
    _shuffle_temps/_sample_temps) - ham nay CHI sinh IL, KHONG tu them
    '.locals init' (xem canh bao trong brief - .locals da duoc
    gen_il_function gom 1 lan duy nhat o first-pass)."""
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx.get('prefix', 'fy')
    start_lbl = f'{prefix}_{label_prefix}{n}_start'
    end_lbl = f'{prefix}_{label_prefix}{n}_end'

    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {i_idx}')
    body.append(f'  {start_lbl}:')
    body.append(f'    ldloc.s {i_idx}')
    k_upper_loader(body)
    body.append(f'    bge {end_lbl}')

    # j = TkvRandom::Instance().Next(i, n)  (n = do dai THAT cua list)
    body.append(f'    call class [mscorlib]System.Random {_HELPER_CLASS}::Instance()')
    body.append(f'    ldloc.s {i_idx}')
    load_list_fn(body)
    body.append(f'    callvirt instance int32 {list_type}::get_Count()')
    body.append('    callvirt instance int32 [mscorlib]System.Random::Next(int32, int32)')
    body.append(f'    stloc.s {j_idx}')

    # tmp = list[i]
    load_list_fn(body)
    body.append(f'    ldloc.s {i_idx}')
    body.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    body.append(f'    stloc.s {tmp_idx}')

    # list[i] = list[j]
    load_list_fn(body)
    body.append(f'    ldloc.s {i_idx}')
    load_list_fn(body)
    body.append(f'    ldloc.s {j_idx}')
    body.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    body.append(f'    callvirt instance void {list_type}::set_Item(int32, !0)')

    # list[j] = tmp
    load_list_fn(body)
    body.append(f'    ldloc.s {j_idx}')
    body.append(f'    ldloc.s {tmp_idx}')
    body.append(f'    callvirt instance void {list_type}::set_Item(int32, !0)')

    # i = i + 1
    body.append(f'    ldloc.s {i_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {i_idx}')
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')


def _shuffle_temps(node, ctx):
    """FIRST PASS (register_call_stmt_temps): khai 3 local an i32/i32/T
    (i, j, tmp) cho shuffle(lst) - khoa ten theo id(args) (args = node[2],
    CUNG object voi call_args nhan o codegen_shuffle_stmt vi ca 2 pass
    deu doc tu CUNG 1 stmt['call_node'] - giong het quy uoc cua
    stdlib_aggregates.py's _temps_agg)."""
    args = node[2]
    if len(args) != 1 or args[0][0] != 'var':
        return
    try:
        ta = ctx['infer_scope'][args[0][1]][2]
    except KeyError:
        return
    if ta.shape != 'list':
        return
    TypeAnn = ctx['TypeAnn']
    ctx['declare_named'](f'__shuf{id(args)}_i', TypeAnn('i32', None))
    ctx['declare_named'](f'__shuf{id(args)}_j', TypeAnn('i32', None))
    ctx['declare_named'](f'__shuf{id(args)}_tmp', TypeAnn(ta.dtype, None))


def codegen_shuffle_stmt(call_args, scope, body, ctx):
    """shuffle(lst) - Fisher-Yates TAI CHO, sinh INLINE (khong generic
    method tu viet). lst PHAI la 1 BIEN list don (giong gioi han
    choice()). Dung _fisher_yates_prefix voi k = do dai THAT cua lst (xao
    het list)."""
    if len(call_args) != 1:
        raise SyntaxError("il_codegen: shuffle(lst) nhan dung 1 tham so")
    if call_args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: shuffle(lst) chi ho tro tham so la 1 BIEN list don")
    var_name = call_args[0][1]
    _, _, ta = scope[var_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: shuffle(lst) can '{var_name}' la list (shape={ta.shape!r})")
    list_type = il_list_type(ta.dtype, (ctx or {}).get('records'))
    load_var_ref = ctx['load_var_ref']
    ensure_class(ctx)

    i_idx = scope[f'__shuf{id(call_args)}_i'][1]
    j_idx = scope[f'__shuf{id(call_args)}_j'][1]
    tmp_idx = scope[f'__shuf{id(call_args)}_tmp'][1]

    def load_list(b):
        load_var_ref(var_name, scope, b)

    def k_upper(b):
        load_list(b)
        b.append(f'    callvirt instance int32 {list_type}::get_Count()')

    _fisher_yates_prefix(body, list_type, load_list, i_idx, j_idx, tmp_idx,
                          k_upper, ctx, 'shuf')


def _sample_temps(node, ctx):
    """FIRST PASS: khai 5 local an cho sample(lst, k) - copy (List<T> ban
    sao), i/j/tmp (vong Fisher-Yates dung chung), va k (luu 1 lan gia tri
    tham so thu 2, tranh tinh lai bieu thuc k nhieu lan trong dieu kien
    vong lap)."""
    args = node[2]
    if len(args) != 2 or args[0][0] != 'var':
        return
    try:
        ta = ctx['infer_scope'][args[0][1]][2]
    except KeyError:
        return
    if ta.shape != 'list':
        return
    TypeAnn = ctx['TypeAnn']
    ctx['declare_named'](f'__smpl{id(args)}_copy', TypeAnn(ta.dtype, 'list'))
    ctx['declare_named'](f'__smpl{id(args)}_i', TypeAnn('i32', None))
    ctx['declare_named'](f'__smpl{id(args)}_j', TypeAnn('i32', None))
    ctx['declare_named'](f'__smpl{id(args)}_tmp', TypeAnn(ta.dtype, None))
    ctx['declare_named'](f'__smpl{id(args)}_k', TypeAnn('i32', None))


def compile_sample(args, scope, out, dtype, ctx):
    """sample(lst, k) - tra ve 1 List<T> MOI gom k phan tu dau cua 1 ban
    sao DA XAO (Fisher-Yates dung chung voi shuffle, gioi han k buoc dau
    thay vi het list), KHONG mutate lst goc. Ban sao qua
    .ctor(IEnumerable<T>) (List<T> co overload nay - da XAC NHAN THAT qua
    PowerShell reflection, xem brief), roi GetRange(0, k) cat lay k phan
    tu dau DA duoc xao vao dau danh sach."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: sample(lst, k) nhan dung 2 tham so")
    if args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: sample(lst, k) chi ho tro tham so dau la 1 BIEN list don")
    var_name = args[0][1]
    _, _, ta = scope[var_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: sample(lst, k) can '{var_name}' la list (shape={ta.shape!r})")
    list_type = il_list_type(ta.dtype, (ctx or {}).get('records'))
    ensure_class(ctx)
    load_var_ref = ctx['load_var_ref']
    compile_expr = ctx['compile_expr']

    copy_idx = scope[f'__smpl{id(args)}_copy'][1]
    i_idx = scope[f'__smpl{id(args)}_i'][1]
    j_idx = scope[f'__smpl{id(args)}_j'][1]
    tmp_idx = scope[f'__smpl{id(args)}_tmp'][1]
    k_idx = scope[f'__smpl{id(args)}_k'][1]

    # copy = new List<T>(lst) - ban sao doc lap, KHONG mutate lst goc.
    load_var_ref(var_name, scope, out)
    out.append(
        f'    newobj instance void {list_type}::.ctor(class '
        f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    stloc.s {copy_idx}')

    # k = <bieu thuc tham so thu 2>
    compile_expr(args[1], scope, out, 'i32', ctx)
    out.append(f'    stloc.s {k_idx}')

    def load_list(b):
        b.append(f'    ldloc.s {copy_idx}')

    def k_upper(b):
        b.append(f'    ldloc.s {k_idx}')

    _fisher_yates_prefix(out, list_type, load_list, i_idx, j_idx, tmp_idx,
                          k_upper, ctx, 'smpl')

    # ket qua = copy.GetRange(0, k)
    out.append(f'    ldloc.s {copy_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    ldloc.s {k_idx}')
    out.append(
        f'    callvirt instance class [mscorlib]System.Collections.Generic.List`1<!0> '
        f'{list_type}::GetRange(int32, int32)')


def _sample_dtype_fn(args, scope):
    """dtype tra ve cua sample(lst, k) PHU THUOC dtype 'lst' - giong het
    _choice_dtype_fn."""
    if len(args) != 2 or args[0][0] != 'var':
        return None
    try:
        return scope[args[0][1]][2].dtype
    except KeyError:
        return None


register_expr_builtin('sample', compile_sample, None, return_shape='list',
                       temps_fn=_sample_temps, return_dtype_fn=_sample_dtype_fn)
register_call_stmt_temps('shuffle', _shuffle_temps)


def codegen_seed(call_args, scope, body, ctx):
    """seed(n) - lenh DOC LAP (khong tra gia tri), dispatch qua
    RANDOM_STMT_CODEGEN giong het log_set_level (logging_feature.py)."""
    if len(call_args) != 1:
        raise SyntaxError("il_codegen: seed(n) nhan dung 1 tham so")
    ensure_class(ctx)
    ctx['compile_expr'](call_args[0], scope, body, 'i32', ctx)
    body.append(f'    call void {_HELPER_CLASS}::SetSeed(int32)')


RANDOM_STMT_CODEGEN = {'seed': codegen_seed, 'shuffle': codegen_shuffle_stmt}
