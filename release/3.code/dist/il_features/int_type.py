# -*- coding: utf-8 -*-
"""Kieu 'int' NGANG BANG PYTHON - so nguyen vo han chu so (moc 6 buoc 2,
2026-08-05).

Python co MOT kieu so nguyen duy nhat, vo han chu so. TokenVector truoc
day chi co 'i32'/'i64' -> '13!' cho 1932053504 thay vi 6227020800, im
lang. Buoc 1 (a5ce8d2) da doi tran thanh loi ON AO (add.ovf); buoc nay
lam DUNG.

## Bieu dien

    .class sequential TkvInt { int64 lo; object big }

`big == null` nghia la dang o DUONG NHANH (gia tri that nam trong `lo`);
khac null la 1 BigInteger da dong hop. Day la mo hinh PyLong cua CPython
(so nho di duong nhanh, tu thang hang khi tran).

## Vi sao STRUCT chu khong phai "hai local song song"

Spike 1 (docs/spikes/README.md) chot thiet ke "moi bien int giu hai local
lo+big" nhung KHONG tra loi duoc: _compile_expr() day DUNG MOT gia tri
len stack, vay 1 bieu thuc int TRUNG GIAN mang hai gia tri di kieu gi?

Spike 2 (docs/spikes/spike_int_repr.py) do that, cung mot phien:

    int64 thuan (ngu nghia SAI)   25 ms   88,9x CPython
    hai local song song           50 ms   44,5x CPython
    struct, MOT gia tri tren stack 59 ms  37,7x CPython

Struct dat hon 18% so voi hai-local, va giu nguyen duoc giao uoc "mot gia
tri tren stack" cua toan bo codegen - khong phai viet lai ~100 diem goi.
Doi 18% lay gon ca thiet ke: CHON STRUCT.

## Duong nhanh BAT BUOC noi tuyen

Ket luan dat nhat cua spike 1 (helper 9,5x vs noi tuyen 1,4x so int32):
phep +/-/* sinh ma NOI TUYEN tai tung diem, chi DUONG CHAM (hiem) moi goi
helper. Dung "don dep" cho gon thanh 1 helper - se mat gan het loi ich.

## Kiem tran bang phep bit, khong try/catch

    a+b:  r = a+b (add THUONG);  tran <=> ((a^r) & (b^r)) < 0
    a-b:  r = a-b;               tran <=> ((a^b) & (a^r)) < 0
    a*b:  chi di duong nhanh khi CA HAI toan hang nam gon trong int32
          (tich cua 2 so int32 luon vua int64) - kiem tra BAO THU, so
          lon roi xuong BigInteger. Bao thu o day KHONG sai ket qua:
          duong cham cho ket qua chinh xac tuyet doi.
"""
from il_core import IL_SCALAR, IL_NARROW_TO_I32
from il_dispatch import register_expr_builtin

TKVINT_CLASS = 'TkvInt'
BIG = '[System.Numerics]System.Numerics.BigInteger'

# 4 local NHAP (scratch) dung chung cho MOI phep toan int trong 1 ham.
# Tai su dung duoc vi chung chi bi ghi SAU KHI ca hai toan hang da tinh
# xong va nam tren stack duoi dang BAN SAO (struct = copy-by-value) -
# bieu thuc long nhau khong dam nhau. Xem _emit_binop_fast.
SCRATCH_A = '__tkvint_a'
SCRATCH_B = '__tkvint_b'
SCRATCH_R = '__tkvint_r'
SCRATCH_X = '__tkvint_x'  # int64, giu ket qua tho truoc khi kiem tran

INT64_MIN_HEX = '0x8000000000000000'
INT64_MAX_HEX = '0x7FFFFFFFFFFFFFFF'


def register_int_dtype():
    """Goi luc nap module (cuoi file) - dang ky 'int' vao cac bang kieu
    IL dung chung.

    IL_SCALAR keo theo List<valuetype TkvInt> va Dictionary<K, valuetype
    TkvInt> MIEN PHI: il_list_elem_ilstr/il_dict_* deu tra cuu qua no.
    Day la duong list/dict THAT SU chay (List`1::get_Item/set_Item), da
    do bang bigint_container_test.py voi gia tri toi 10^32.

    KHONG dang ky vao IL_LDC_OP: 'ldc.<gi do> 5' khong tao duoc mot
    struct. Hang so 'int' di compile_literal (FromI64/FromStr).

    KHONG dang ky vao IL_LDELEM/IL_STELEM/IL_NEWARR_ELEM (mang tho
    'newarr'/'ldelem'). Da thu dang ky va PHAT HIEN chung khong he duoc
    cham toi: list di qua List`1, con mang tho chi tao duoc bang
    np.zeros(n, dtype=np.<numpy dtype>) - 'int' khong co dtype numpy
    tuong ung nen KHONG CO cu phap nao dan toi day. Doi chung dot bien
    da chi ra dieu do: doi IL_LDELEM['int'] thanh 'ldelem.i8' ma bo test
    van xanh. Ba dong dang ky khong the kiem chung ay da bi go - thieu
    khoa se bao KeyError ON AO neu sau nay co duong nao that su can, va
    do la ket qua dung."""
    IL_SCALAR['int'] = f'valuetype {TKVINT_CLASS}'
    IL_NARROW_TO_I32['int'] = (f'    call int32 {TKVINT_CLASS}::ToI32'
                               f'(valuetype {TKVINT_CLASS})')


def ensure_class(ctx):
    """Chen dinh nghia .class TkvInt vao chuong trinh DUNG MOT LAN."""
    emitted = ctx.get('emitted_types')
    if emitted is None or TKVINT_CLASS in emitted:
        return
    import il_features.tkvstr as _tkvstr
    _tkvstr.ensure_class(ctx)
    emitted.add(TKVINT_CLASS)
    ctx['extra_classes'].append(_gen_tkvint_class_il())


# ============================================================
# Sinh ma cho tung phep - PHAN NOI TUYEN
# ============================================================

def _addr(ctx, name, scope, out):
    ctx['load_var_addr'](name, scope, out)


def _ld(ctx, name, scope, out):
    ctx['load_var_ref'](name, scope, out)


def _st(ctx, name, scope, out):
    ctx['store_var'](name, scope, out)


def _load_field(ctx, name, field, il_type, scope, out):
    _addr(ctx, name, scope, out)
    out.append(f'    ldfld {il_type} {TKVINT_CLASS}::{field}')


def compile_literal(text, out, ctx):
    """Hang so nguyen o vi tri kieu 'int'. Hang so vua int64 di duong
    FromI64; hang so LON HON (Python viet duoc, vd 10**30 danh thang)
    di duong Parse chuoi - khong the bieu dien bang ldc.i8."""
    ensure_class(ctx)
    value = int(text)
    if -(2 ** 63) <= value < 2 ** 63:
        out.append(f'    ldc.i8 {value}')
        out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::FromI64(int64)')
    else:
        out.append(f'    ldstr "{value}"')
        out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::FromStr(string)')


def compile_binop(op, left, right, scope, out, ctx):
    """'+' '-' '*' tren kieu 'int'. Hai toan hang duoc day len stack
    truoc (dung giao uoc chung cua _compile_expr), sau do NOI TUYEN
    duong nhanh."""
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    compile_expr(left, scope, out, 'int', ctx)
    compile_expr(right, scope, out, 'int', ctx)
    _emit_binop_fast(op, scope, out, ctx)


def _emit_binop_fast(op, scope, out, ctx):
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx.get('prefix', 'expr')
    slow = f'{prefix}_int{n}_slow'
    done = f'{prefix}_int{n}_done'

    _st(ctx, SCRATCH_B, scope, out)
    _st(ctx, SCRATCH_A, scope, out)
    # Ca hai phai dang o duong nhanh (big == null)
    _load_field(ctx, SCRATCH_A, 'big', 'object', scope, out)
    out.append(f'    brtrue {slow}')
    _load_field(ctx, SCRATCH_B, 'big', 'object', scope, out)
    out.append(f'    brtrue {slow}')

    if op == '*':
        # Kiem BAO THU: ca hai toan hang phai nam gon trong int32 thi
        # tich chac chan vua int64. So lon hon roi xuong BigInteger du
        # co the van vua - dung ket qua, chi cham hon.
        for name in (SCRATCH_A, SCRATCH_B):
            _load_field(ctx, name, 'lo', 'int64', scope, out)
            out.append('    ldc.i8 -2147483648')
            out.append(f'    blt {slow}')
            _load_field(ctx, name, 'lo', 'int64', scope, out)
            out.append('    ldc.i8 2147483647')
            out.append(f'    bgt {slow}')
        _load_field(ctx, SCRATCH_A, 'lo', 'int64', scope, out)
        _load_field(ctx, SCRATCH_B, 'lo', 'int64', scope, out)
        out.append('    mul')
        _st(ctx, SCRATCH_X, scope, out)
    else:
        _load_field(ctx, SCRATCH_A, 'lo', 'int64', scope, out)
        _load_field(ctx, SCRATCH_B, 'lo', 'int64', scope, out)
        out.append('    add' if op == '+' else '    sub')
        _st(ctx, SCRATCH_X, scope, out)
        # '+': ((a^r) & (b^r)) < 0 ; '-': ((a^b) & (a^r)) < 0
        _load_field(ctx, SCRATCH_A, 'lo', 'int64', scope, out)
        if op == '+':
            _ld(ctx, SCRATCH_X, scope, out)
            out.append('    xor')
            _load_field(ctx, SCRATCH_B, 'lo', 'int64', scope, out)
            _ld(ctx, SCRATCH_X, scope, out)
            out.append('    xor')
        else:
            _load_field(ctx, SCRATCH_B, 'lo', 'int64', scope, out)
            out.append('    xor')
            _load_field(ctx, SCRATCH_A, 'lo', 'int64', scope, out)
            _ld(ctx, SCRATCH_X, scope, out)
            out.append('    xor')
        out.append('    and')
        out.append('    ldc.i8 0')
        out.append(f'    blt {slow}')

    _addr(ctx, SCRATCH_R, scope, out)
    _ld(ctx, SCRATCH_X, scope, out)
    out.append(f'    stfld int64 {TKVINT_CLASS}::lo')
    _addr(ctx, SCRATCH_R, scope, out)
    out.append('    ldnull')
    out.append(f'    stfld object {TKVINT_CLASS}::big')
    _ld(ctx, SCRATCH_R, scope, out)
    out.append(f'    br {done}')

    out.append(f'  {slow}:')
    _ld(ctx, SCRATCH_A, scope, out)
    _ld(ctx, SCRATCH_B, scope, out)
    helper = {'+': 'AddSlow', '-': 'SubSlow', '*': 'MulSlow'}[op]
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::{helper}'
               f'(valuetype {TKVINT_CLASS}, valuetype {TKVINT_CLASS})')
    out.append(f'  {done}:')


def compile_compare(op, left, right, scope, out, ctx):
    """So sanh hai gia tri 'int' - ket qua int32 0/1 nhu moi so sanh
    khac. Duong nhanh (ca hai big == null) so THANG hai int64; nguoc lai
    goi BigInteger.Compare. Ket qua trung gian la -1/0/1 nen 6 toan tu
    deu quy ve so sanh voi 0."""
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    compile_expr(left, scope, out, 'int', ctx)
    compile_expr(right, scope, out, 'int', ctx)
    out.append(f'    call int32 {TKVINT_CLASS}::Cmp'
               f'(valuetype {TKVINT_CLASS}, valuetype {TKVINT_CLASS})')
    out.append('    ldc.i4.0')
    # Cmp(a,b) <op> 0  <=>  a <op> b
    if op == '>':
        out.append('    cgt')
    elif op == '<':
        out.append('    clt')
    elif op == '==':
        out.append('    ceq')
    elif op == '!=':
        out.append('    ceq')
        out.append('    ldc.i4.0')
        out.append('    ceq')
    elif op == '>=':
        out.append('    clt')
        out.append('    ldc.i4.0')
        out.append('    ceq')
    elif op == '<=':
        out.append('    cgt')
        out.append('    ldc.i4.0')
        out.append('    ceq')
    else:
        raise SyntaxError(f'int_type: toan tu so sanh khong ho tro: {op!r}')


_DIVMOD_POW_HELPER = {'//': 'FloorDiv', '%': 'Mod', '**': 'Pow'}


def compile_divmod_pow(op, left, right, scope, out, ctx):
    """'//' '%' '**' tren kieu 'int' (moc 6 lat 2, 2026-08-05).

    KHONG noi tuyen nhu +/-/*: ba phep nay hiem hon han trong ma that va
    than chung dai gap may lan (chinh dau floor, duong BigInteger) - noi
    tuyen se phinh ma doi lay khong bao nhieu. Do chinh la ly do spike 1
    bat noi tuyen +/-/*: o do helper cham 9,5x, khong phai vi helper xau.

    Ngu nghia LA CUA PYTHON, khong phai cua .NET - xem than IL: CIL 'div'/
    'rem' va BigInteger.Divide/Remainder deu CAT VE 0, Python lam tron VE
    AM VO CUC. Hai cai chi trung nhau khi hai toan hang cung dau, nen sai
    lech nay AM THAM (bien dich duoc, chay duoc, chi lech khi gap so am).
    """
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    compile_expr(left, scope, out, 'int', ctx)
    compile_expr(right, scope, out, 'int', ctx)
    helper = _DIVMOD_POW_HELPER[op]
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::{helper}'
               f'(valuetype {TKVINT_CLASS}, valuetype {TKVINT_CLASS})')


def compile_neg(operand, scope, out, ctx):
    """'-x' tren kieu 'int'. Ma lenh 'neg' cua CIL KHONG dung duoc: toan
    hang la mot struct, khong phai so may. Thieu nhanh nay thi '-x' sinh
    IL sai kieu."""
    ensure_class(ctx)
    ctx['compile_expr'](operand, scope, out, 'int', ctx)
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::Neg'
               f'(valuetype {TKVINT_CLASS})')


def compile_str_of_int(arg, scope, out, ctx):
    """'str(x)' khi x la 'int' - chuoi PHAI khop CPython o moi do lon."""
    ensure_class(ctx)
    ctx['compile_expr'](arg, scope, out, 'int', ctx)
    out.append(f'    call string {TKVINT_CLASS}::Str(valuetype {TKVINT_CLASS})')


def scratch_locals():
    """(ten, dtype) cac local nhap can khai bao trong ham CO dung 'int'.
    Xem _first_pass_collect_locals."""
    return [(SCRATCH_A, 'int'), (SCRATCH_B, 'int'), (SCRATCH_R, 'int'),
            (SCRATCH_X, 'i64')]


# ============================================================
# Dinh nghia .class TkvInt (duong cham + tien ich)
# ============================================================

def _m(sig, *body):
    return ([f'  .method public static {sig} cil managed', '  {', '    .maxstack 8']
            + list(body) + ['  }'])


def _gen_tkvint_class_il():
    lines = [
        f'.class public sequential ansi sealed beforefieldinit {TKVINT_CLASS}',
        '       extends [mscorlib]System.ValueType',
        # IComparable`1 BAT BUOC de 'sorted(list[int])' chay: List`1::Sort()
        # dung Comparer<T>.Default, va khi T khong cai dat IComparable no
        # roi ve ObjectComparer roi nem "At least one object must implement
        # IComparable" LUC CHAY (loi THAT, aggregates_test).
        '       implements class [mscorlib]System.IComparable`1<valuetype '
        f'{TKVINT_CLASS}>, [mscorlib]System.IComparable',
        '{',
        '  .field public int64 lo',
        '  .field public object big',
    ]
    v = f'valuetype {TKVINT_CLASS}'

    lines += _m(
        f'{v} FromI64(int64 v)',
        f'    .locals init ({v} r)',
        '    ldloca.s r', '    ldarg.0', f'    stfld int64 {TKVINT_CLASS}::lo',
        '    ldloca.s r', '    ldnull', f'    stfld object {TKVINT_CLASS}::big',
        '    ldloc.s r', '    ret')

    # InvariantCulture BAT BUOC: may nay locale vi-VN va du an DA co bug
    # THAT y het voi Single.Parse (xem STATUS.md). Parse(string) mot tham
    # so lay NumberFormatInfo cua culture HIEN HANH - dau am/duong theo
    # culture. Python's int() khong phu thuoc locale, nen ta cung vay.
    lines += _m(
        f'{v} FromStr(string s)',
        '    ldarg.0',
        '    ldc.i4.7',  # NumberStyles.Integer = AllowLeading/TrailingWhite|AllowLeadingSign
        '    call class [mscorlib]System.Globalization.CultureInfo '
        '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
        f'    call valuetype {BIG} {BIG}::Parse(string, '
        'valuetype [mscorlib]System.Globalization.NumberStyles, '
        'class [mscorlib]System.IFormatProvider)',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})',
        '    ret')

    # Chuan hoa: BigInteger vua int64 thi HA ve duong nhanh. Bat buoc,
    # neu khong thi sau 1 lan tran moi phep sau deu di duong cham va
    # 'big' khac null se lam Str/Cmp cho ket qua dung nhung cham dan.
    lines += _m(
        f'{v} FromBig(valuetype {BIG} b)',
        f'    .locals init ({v} r)',
        '    ldarg.0', f'    ldc.i8 {INT64_MIN_HEX}',
        f'    call bool {BIG}::op_GreaterThanOrEqual(valuetype {BIG}, int64)',
        '    brfalse.s BIGPATH',
        '    ldarg.0', f'    ldc.i8 {INT64_MAX_HEX}',
        f'    call bool {BIG}::op_LessThanOrEqual(valuetype {BIG}, int64)',
        '    brfalse.s BIGPATH',
        '    ldloca.s r', '    ldarg.0',
        f'    call int64 {BIG}::op_Explicit(valuetype {BIG})',
        f'    stfld int64 {TKVINT_CLASS}::lo',
        '    ldloca.s r', '    ldnull', f'    stfld object {TKVINT_CLASS}::big',
        '    ldloc.s r', '    ret',
        '  BIGPATH:',
        '    ldloca.s r', '    ldc.i8 0', f'    stfld int64 {TKVINT_CLASS}::lo',
        '    ldloca.s r', '    ldarg.0', f'    box {BIG}',
        f'    stfld object {TKVINT_CLASS}::big',
        '    ldloc.s r', '    ret')

    lines += _m(
        f'valuetype {BIG} ToBig({v} a)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brfalse.s FASTPATH',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        f'    unbox.any {BIG}', '    ret',
        '  FASTPATH:',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo',
        f'    call valuetype {BIG} {BIG}::op_Implicit(int64)', '    ret')

    for name, opname in (('AddSlow', 'op_Addition'), ('SubSlow', 'op_Subtraction'),
                          ('MulSlow', 'op_Multiply')):
        lines += _m(
            f'{v} {name}({v} a, {v} b)',
            '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
            '    ldarg.1', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
            f'    call valuetype {BIG} {BIG}::{opname}(valuetype {BIG}, valuetype {BIG})',
            f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})',
            '    ret')

    lines += _m(
        f'int32 Cmp({v} a, {v} b)',
        '    .locals init (int64 x)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue.s SLOWPATH',
        '    ldarga.s b', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue.s SLOWPATH',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s x',
        '    ldloca.s x', '    ldarga.s b', f'    ldfld int64 {TKVINT_CLASS}::lo',
        '    call instance int32 [mscorlib]System.Int64::CompareTo(int64)', '    ret',
        '  SLOWPATH:',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        '    ldarg.1', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        f'    call int32 {BIG}::Compare(valuetype {BIG}, valuetype {BIG})', '    ret')

    lines += _m(
        f'string Str({v} a)',
        f'    .locals init (int64 x, valuetype {BIG} b, float64 d)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue.s SLOWPATH',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s x',
        '    ldloca.s x',
        '    call class [mscorlib]System.Globalization.CultureInfo '
        '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
        '    call instance string [mscorlib]System.Int64::ToString('
        'class [mscorlib]System.IFormatProvider)',
        '    ret',
        '  SLOWPATH:',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    isinst [mscorlib]System.Double',
        '    brtrue.s DOUBLEPATH',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        '    stloc.s b', '    ldloca.s b',
        '    call class [mscorlib]System.Globalization.CultureInfo '
        '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()',
        f'    call instance string {BIG}::ToString('
        'class [mscorlib]System.IFormatProvider)',
        '    ret',
        '  DOUBLEPATH:',
        '    ldarga.s a',
        '    ldfld object TkvInt::big',
        '    unbox.any float64',
        '    call string TkvStr::F64(float64)',
        '    ret')

    # Thu hep CO KIEM TRA ve int32 - CHI dung o vi tri chi so (xem
    # emit_index_scalar trong il_core.py). 'conv.ovf.i4' chu khong phai
    # 'conv.i4': khong vua thi NEM, khong cat.
    lines += _m(
        f'int32 ToI32({v} a)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue TOI32_BIG',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo',
        '    conv.ovf.i4', '    ret',
        '  TOI32_BIG:',
        '    ldstr "chi so int qua lon: khong vua int32."',
        '    newobj instance void [mscorlib]System.OverflowException'
        '::.ctor(string)', '    throw')

    # Thu hep/mo rong CO KIEM TRA sang cac kieu so co do rong co dinh.
    # 'ToI64' nem khi khong vua (giong ToI32); 'ToF64' di qua BigInteger
    # explicit-cast, tra ve +Inf khi qua lon - dung het nhu Python? KHONG:
    # Python nem OverflowError. Ta cung nem, xem than ham.
    lines += _m(
        f'int64 ToI64({v} a)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue TOI64_BIG',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    ret',
        '  TOI64_BIG:',
        '    ldstr "gia tri int qua lon: khong vua int64."',
        '    newobj instance void [mscorlib]System.OverflowException'
        '::.ctor(string)', '    throw')

    lines += _m(
        f'float64 ToF64({v} a)',
        f'    .locals init (valuetype {BIG} b, float64 d)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue TOF64_BIG',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo',
        '    conv.r8', '    ret',
        '  TOF64_BIG:',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    isinst [mscorlib]System.Double',
        '    brfalse TOF64_NOT_DBL',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    unbox.any float64', '    ret',
        '  TOF64_NOT_DBL:',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        '    stloc.s b', '    ldloc.s b',
        f'    call float64 {BIG}::op_Explicit(valuetype {BIG})', '    stloc.s d',
        # Python nem OverflowError khi int qua lon de thanh float; .NET tra
        # +/-Infinity. Nem, khong tra Inf am tham.
        '    ldloc.s d', '    call bool [mscorlib]System.Double::IsInfinity(float64)',
        '    brtrue TOF64_OVF',
        '    ldloc.s d', '    ret',
        '  TOF64_OVF:',
        '    ldstr "gia tri int qua lon de chuyen thanh float."',
        '    newobj instance void [mscorlib]System.OverflowException'
        '::.ctor(string)', '    throw')

    # So sanh cho Comparer<T>.Default. Ban generic la duong THAT SU chay;
    # ban 'object' giu cho cac API khong generic (Array.Sort cu, ArrayList).
    lines += [
        f'  .method public hidebysig newslot virtual final instance int32 CompareTo({v} other) cil managed',
        '  {', '    .maxstack 8',
        f'    .override method instance int32 class [mscorlib]System.IComparable`1<{v}>::CompareTo(!0)',
        '    ldarg.0', f'    ldobj {v}', '    ldarg.1',
        f'    call int32 {TKVINT_CLASS}::Cmp({v}, {v})', '    ret', '  }',
        '  .method public hidebysig newslot virtual final instance int32 CompareTo(object other) cil managed',
        '  {', '    .maxstack 8',
        '    .override [mscorlib]System.IComparable::CompareTo',
        '    ldarg.0', f'    ldobj {v}', '    ldarg.1', f'    unbox.any {v}',
        f'    call int32 {TKVINT_CLASS}::Cmp({v}, {v})', '    ret', '  }',
        '  .method public hidebysig virtual instance string ToString() cil managed',
        '  {', '    .maxstack 8',
        '    ldarg.0', f'    ldobj {v}',
        f'    call string {TKVINT_CLASS}::Str({v})', '    ret', '  }',
    ]

    lines += _gen_floordiv_mod(v)
    lines += _gen_pow_neg(v)
    lines += _gen_builtins(v)

    lines.append('}')
    return lines


def _fast_prologue(slow):
    """Ca hai toan hang phai o duong nhanh, va SO CHIA phai khac 0 va
    khac -1. Vi sao loai -1: MIN_VALUE / -1 va MIN_VALUE rem -1 lam CIL
    nem OverflowException, trong khi Python tra dung ket qua. Day chinh
    la ca ma 'kiem tra bao thu' phai bat - de lot thi ta doi mot lech am
    tham lay mot cu sap."""
    return [
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        f'    brtrue {slow}',
        '    ldarga.s b', f'    ldfld object {TKVINT_CLASS}::big',
        f'    brtrue {slow}',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s x',
        '    ldarga.s b', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s y',
        '    ldloc.s y', '    ldc.i8 0', f'    beq {slow}',
        '    ldloc.s y', '    ldc.i8 -1', f'    beq {slow}',
    ]


def _slow_divrem():
    """ba/bb -> bq (thuong CAT VE 0) va br (du, dau theo SO BI CHIA)."""
    return [
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig'
                       f'(valuetype {TKVINT_CLASS})', '    stloc.s ba',
        '    ldarg.1', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig'
                       f'(valuetype {TKVINT_CLASS})', '    stloc.s bb',
        '    ldloc.s ba', '    ldloc.s bb', '    ldloca.s bdu',
        f'    call valuetype {BIG} {BIG}::DivRem(valuetype {BIG}, '
        f'valuetype {BIG}, valuetype {BIG}&)',
        '    stloc.s bq',
    ]


def _slow_needs_fix(done):
    """Chi phai chinh khi du KHAC 0 va du KHAC DAU voi so chia. Dau lay
    qua get_Sign() (-1/0/1) nen 'khac dau' = 'hai dau khong bang nhau',
    khong dung phep XOR bit nhu duong nhanh (BigInteger khong phai so
    may, khong co bit dau de xor)."""
    return [
        '    ldloca.s bdu', f'    call instance int32 {BIG}::get_Sign()',
        '    ldc.i4.0', f'    beq {done}',
        '    ldloca.s bdu', f'    call instance int32 {BIG}::get_Sign()',
        '    ldloca.s bb', f'    call instance int32 {BIG}::get_Sign()',
        f'    beq {done}',
    ]


def _gen_floordiv_mod(v):
    """'//' va '%' - ngu nghia floor cua Python tren CA HAI duong.

        Python: -7 // 2 == -4   |  -7 % 3 == 2
        CIL   : -7 /  2 == -3   |  -7 rem 3 == -1

    Cong thuc chinh giong het duong i32/i64 da co (operators.py's
    _emit_int_floor_div_or_mod): thuong bot 1 / du cong them so chia khi
    du khac 0 va hai ve khac dau. O day phai viet LAI vi toan hang la
    TkvInt chu khong phai int64 tho, va vi con duong BigInteger."""
    big_locals = (f'.locals init (int64 x, int64 y, int64 q, int64 r, '
                  f'valuetype {BIG} ba, valuetype {BIG} bb, '
                  f'valuetype {BIG} bq, valuetype {BIG} bdu)')
    lines = _m(
        f'{v} FloorDiv({v} a, {v} b)',
        f'    {big_locals}',
        *_fast_prologue('FD_SLOW'),
        '    ldloc.s x', '    ldloc.s y', '    div', '    stloc.s q',
        '    ldloc.s x', '    ldloc.s y', '    rem', '    stloc.s r',
        '    ldloc.s r', '    ldc.i8 0', '    beq FD_FAST_DONE',
        # (x xor y) < 0  <=>  hai ve khac dau
        '    ldloc.s x', '    ldloc.s y', '    xor',
        '    ldc.i8 0', '    bge FD_FAST_DONE',
        '    ldloc.s q', '    ldc.i8 1', '    sub', '    stloc.s q',
        '  FD_FAST_DONE:',
        '    ldloc.s q',
        f'    call {v} {TKVINT_CLASS}::FromI64(int64)', '    ret',
        '  FD_SLOW:',
        *_slow_divrem(),
        *_slow_needs_fix('FD_SLOW_DONE'),
        '    ldloc.s bq', f'    call valuetype {BIG} {BIG}::get_One()',
        f'    call valuetype {BIG} {BIG}::op_Subtraction('
        f'valuetype {BIG}, valuetype {BIG})', '    stloc.s bq',
        '  FD_SLOW_DONE:',
        '    ldloc.s bq',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret')

    lines += _m(
        f'{v} Mod({v} a, {v} b)',
        f'    {big_locals}',
        *_fast_prologue('MD_SLOW'),
        '    ldloc.s x', '    ldloc.s y', '    rem', '    stloc.s r',
        '    ldloc.s r', '    ldc.i8 0', '    beq MD_FAST_DONE',
        # (r xor y) < 0  <=>  du khac dau voi so chia
        '    ldloc.s r', '    ldloc.s y', '    xor',
        '    ldc.i8 0', '    bge MD_FAST_DONE',
        '    ldloc.s r', '    ldloc.s y', '    add', '    stloc.s r',
        '  MD_FAST_DONE:',
        '    ldloc.s r',
        f'    call {v} {TKVINT_CLASS}::FromI64(int64)', '    ret',
        '  MD_SLOW:',
        *_slow_divrem(),
        *_slow_needs_fix('MD_SLOW_DONE'),
        '    ldloc.s bdu', '    ldloc.s bb',
        f'    call valuetype {BIG} {BIG}::op_Addition('
        f'valuetype {BIG}, valuetype {BIG})', '    stloc.s bdu',
        '  MD_SLOW_DONE:',
        '    ldloc.s bdu',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret')
    return lines


def _gen_pow_neg(v):
    """'**' va '-x'.

    '**': KHONG dung Math::Pow nhu duong i32/i64 (stdlib_math's
    compile_pow) - Math::Pow la float64, tra ve xap xi: 3**40 qua float64
    ra 12157665459056929000 thay vi ...928801. Sai am tham dung o cho
    'ngang bang Python' khong cho phep. BigInteger::Pow la chinh xac
    tuyet doi.

    So mu AM: Python tra FLOAT (2 ** -1 == 0.5). Chua co duong int->float
    (moc 10), nen bao loi RO RANG thay vi tra 0 lang le - dung thu tu uu
    tien 'am tham nguy hiem hon on ao' cua du an."""
    lines = _m(
        f'{v} Pow({v} a, {v} b)',
        f'    .locals init (int64 e, float64 d, {v} r)',
        '    ldarga.s b', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue PW_HUGE',
        '    ldarga.s b', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s e',
        '    ldloc.s e', '    ldc.i8 0', '    blt PW_NEG',
        '    ldloc.s e', '    ldc.i8 2147483647', '    bgt PW_HUGE',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        '    ldloc.s e', '    conv.i4',
        f'    call valuetype {BIG} {BIG}::Pow(valuetype {BIG}, int32)',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret',
        '  PW_NEG:',
        '    ldarg.0', f'    call float64 {TKVINT_CLASS}::ToF64({v})',
        '    ldarg.1', f'    call float64 {TKVINT_CLASS}::ToF64({v})',
        '    call float64 [mscorlib]System.Math::Pow(float64, float64)', '    stloc.s d',
        '    ldloca.s r', '    ldc.i8 0', f'    stfld int64 {TKVINT_CLASS}::lo',
        '    ldloca.s r', '    ldloc.s d', '    box float64', f'    stfld object {TKVINT_CLASS}::big',
        '    ldloc.s r', '    ret',
        '  PW_HUGE:',
        '    ldstr "int ** so mu qua lon (> 2^31-1): ket qua khong the vua bo nho."',
        '    newobj instance void [mscorlib]System.OverflowException::.ctor(string)',
        '    throw')

    lines += _m(
        f'{v} Neg({v} a)',
        '    .locals init (int64 x)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue NG_SLOW',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s x',
        # -MIN_VALUE khong vua int64 - ca duy nhat phai xuong duong cham.
        '    ldloc.s x', f'    ldc.i8 {INT64_MIN_HEX}', '    beq NG_SLOW',
        '    ldc.i8 0', '    ldloc.s x', '    sub',
        f'    call {v} {TKVINT_CLASS}::FromI64(int64)', '    ret',
        '  NG_SLOW:',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        f'    call valuetype {BIG} {BIG}::Negate(valuetype {BIG})',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret')
    return lines


def _gen_builtins(v):
    """Ham dung cho int()/abs()/sum()/min()/max() (moc 6 lat 3,
    2026-08-05).

    'Add' la ban KHONG noi tuyen cua phep '+': vong lap cua sum() sinh ma
    MOT LAN cho ca vong nen phinh ma o day khong dang gia nhu o bieu thuc
    le - va _emit_binop_fast can 4 local nhap cua ham dang bien dich,
    khong dung duoc tu ben trong stdlib_aggregates.

    'FromF64' di THANG BigInteger::.ctor(float64): ham dung nay CAT VE 0
    (giong int(3.7)==3, int(-3.7)==-3 cua Python) va nem cho NaN/Inf -
    dung ca ba diem so voi Python, o MOI do lon ('conv.ovf.i8' se nem oan
    voi 1e30 trong khi Python tra ve so nguyen chinh xac)."""
    lines = _m(
        f'{v} Add({v} a, {v} b)',
        '    .locals init (int64 x, int64 y, int64 r)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue AD_SLOW',
        '    ldarga.s b', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue AD_SLOW',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s x',
        '    ldarga.s b', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s y',
        '    ldloc.s x', '    ldloc.s y', '    add', '    stloc.s r',
        # tran <=> ((x^r) & (y^r)) < 0 - cung phep bit voi duong noi tuyen
        '    ldloc.s x', '    ldloc.s r', '    xor',
        '    ldloc.s y', '    ldloc.s r', '    xor',
        '    and', '    ldc.i8 0', '    blt AD_SLOW',
        '    ldloc.s r', f'    call {v} {TKVINT_CLASS}::FromI64(int64)', '    ret',
        '  AD_SLOW:',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        '    ldarg.1', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        f'    call valuetype {BIG} {BIG}::op_Addition(valuetype {BIG}, valuetype {BIG})',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret')

    lines += _m(
        f'{v} Abs({v} a)',
        '    .locals init (int64 x)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue AB_SLOW',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo', '    stloc.s x',
        '    ldloc.s x', '    ldc.i8 0', '    bge AB_POS',
        # abs(MIN_VALUE) KHONG vua int64 - ca duy nhat phai xuong duong cham.
        '    ldloc.s x', f'    ldc.i8 {INT64_MIN_HEX}', '    beq AB_SLOW',
        '    ldc.i8 0', '    ldloc.s x', '    sub',
        f'    call {v} {TKVINT_CLASS}::FromI64(int64)', '    ret',
        '  AB_POS:',
        '    ldarg.0', '    ret',
        '  AB_SLOW:',
        '    ldarg.0', f'    call valuetype {BIG} {TKVINT_CLASS}::ToBig({v})',
        f'    call valuetype {BIG} {BIG}::Abs(valuetype {BIG})',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret')

    lines += _m(
        f'{v} FromF64(float64 d)',
        '    ldarg.0',
        f'    newobj instance void {BIG}::.ctor(float64)',
        f'    call {v} {TKVINT_CLASS}::FromBig(valuetype {BIG})', '    ret')

    # 'big != null' nghia la KHONG vua int64 (FromBig chuan hoa) nen chac
    # chan khac 0 - khong can hoi BigInteger.
    lines += _m(
        f'int32 IsZero({v} a)',
        '    ldarga.s a', f'    ldfld object {TKVINT_CLASS}::big',
        '    brtrue IZ_BIG',
        '    ldarga.s a', f'    ldfld int64 {TKVINT_CLASS}::lo',
        '    ldc.i8 0', '    ceq', '    ret',
        '  IZ_BIG:',
        '    ldc.i4.0', '    ret')
    return lines


# ============================================================
# Diem vao cho cac builtin (goi tu il_codegen / il_features khac)
# ============================================================

def compile_abs(arg, scope, out, ctx):
    """'abs(x)' khi x la 'int'. System.Math::Abs KHONG co overload cho
    struct TkvInt - thieu nhanh nay thi sinh ra mot loi goi ham khong ton
    tai."""
    ensure_class(ctx)
    ctx['compile_expr'](arg, scope, out, 'int', ctx)
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::Abs'
               f'(valuetype {TKVINT_CLASS})')


def compile_to_int(arg, src_dtype, scope, out, ctx):
    """'int(x)' o vi tri kieu 'int' - x la str/f32/f64/i32/i64/int.

    Duong 'str' KHAC han duong i32 cu: 'int("99999999999999999999")'
    truoc day di Int32.Parse va NEM, nay ra dung gia tri - do chinh la
    diem cua kieu 'int'."""
    ensure_class(ctx)
    compile_expr = ctx['compile_expr']
    if src_dtype == 'int':
        return compile_expr(arg, scope, out, 'int', ctx)
    if src_dtype == 'str':
        compile_expr(arg, scope, out, 'str', ctx)
        out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::FromStr(string)')
        return
    if src_dtype in ('f32', 'f64'):
        compile_expr(arg, scope, out, src_dtype, ctx)
        if src_dtype == 'f32':
            out.append('    conv.r8')
        out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::FromF64(float64)')
        return
    # i32/i64, hoac chua suy duoc kieu (None) - bien dich nhu i64 roi de
    # _compile_expr tu bao loi neu that su khong hop le.
    compile_expr(arg, scope, out, 'i32' if src_dtype == 'i32' else 'i64', ctx)
    if src_dtype == 'i32':
        out.append('    conv.i8')
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::FromI64(int64)')


def emit_add(out):
    """Cong hai gia tri 'int' dang nam tren stack (dung trong vong lap
    cua sum())."""
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::Add'
               f'(valuetype {TKVINT_CLASS}, valuetype {TKVINT_CLASS})')


def emit_cmp(out, cmp_opcode):
    """So sanh hai gia tri 'int' dang nam tren stack -> int32 0/1.
    cmp_opcode la 'clt' hoac 'cgt' nhu duong so may."""
    out.append(f'    call int32 {TKVINT_CLASS}::Cmp'
               f'(valuetype {TKVINT_CLASS}, valuetype {TKVINT_CLASS})')
    out.append('    ldc.i4.0')
    out.append(f'    {cmp_opcode}')


def emit_is_zero(out):
    """1 khi gia tri 'int' tren stack bang 0 (dung cho any()/all())."""
    out.append(f'    call int32 {TKVINT_CLASS}::IsZero(valuetype {TKVINT_CLASS})')


def emit_zero(out, ctx):
    ensure_class(ctx)
    out.append('    ldc.i8 0')
    out.append(f'    call valuetype {TKVINT_CLASS} {TKVINT_CLASS}::FromI64(int64)')


register_int_dtype()
