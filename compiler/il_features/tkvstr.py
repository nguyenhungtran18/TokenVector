# -*- coding: utf-8 -*-
"""MOT duong chuyen chuoi duy nhat cho str()/print() (moc 7, 2026-08-05).

## Vi sao phai co class rieng

Duong cu (_str_of_slot trong string_feature.py) goi ToString() - INSTANCE
method tren value type - nen CIL doi DIA CHI, ma mot gia tri tam tren
stack thi khong co dia chi. Hau qua: 'str(a + b)' phai do qua mot local
AN khai bao tu first-pass, va moi noi muon in mot bieu thuc deu phai
mang theo co che do. TkvStr::* la STATIC va nhan GIA TRI, nen bien mat
ca han che lan co che.

## Vi sao khong dung thang ToString("R")

Python's repr(float) la chuoi NGAN NHAT doc lai dung. "R" cua .NET
Framework 4.8 KHONG phai vay - do that:

    123456789012345.6   R cho "123456789012345.59"   Python '123456789012345.6'

Nen dung THANG G15 -> G16 -> G17, lay ban dau tien parse nguoc lai bang
chinh no. Day la cach vong chinh thuc cua .NET Framework cho round-trip,
va no cho DUNG chuoi ngan nhat trong moi ca da do.

## Ba cho .NET va Python khac nhau ve DINH DANG (khong phai chu so)

1. Nguong ky hieu khoa hoc: .NET chuyen sang dang E tu 10^15, Python tu
   10^16. Nen DUY NHAT so mu 15 can dung lai thanh dang thuong. KHONG
   dung ToString("F1") cho viec nay du no nhin co ve dung: F1 chi giu 15
   chu so co nghia nen 1000000000000000.1 ra "1000000000000000.0" - sai
   am tham. Phai dich dau cham tu chinh chuoi chu so ngan nhat.
2. 'E' hoa vs 'e' thuong: Python in '1e+16'.
3. inf/-inf/nan: .NET in "Infinity"/"NaN". Va -0.0: .NET in "0", Python
   in '-0.0' - phai xet BIT DAU, khong so sanh duoc bang '=='.

GIOI HAN DA BIET: so subnormal cuc nho - repr(5e-324) cua Python la
'5e-324', G17 cua .NET Framework cho '4.94065645841247E-324'. Thang
G-ladder khong voi toi duoc; can port Grisu/Ryu (moc 15).
"""
from il_dispatch import register_expr_builtin  # noqa: F401  (giu quy uoc import)

TKVSTR_CLASS = 'TkvStr'
_INV = ('    call class [mscorlib]System.Globalization.CultureInfo '
        '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
_STR = '[mscorlib]System.String'


def ensure_class(ctx):
    emitted = ctx.get('emitted_types')
    if emitted is None or TKVSTR_CLASS in emitted:
        return
    emitted.add(TKVSTR_CLASS)
    ctx['extra_classes'].append(_gen_class_il())


def emit_to_str(dtype, out, ctx):
    """Gia tri kieu `dtype` DANG NAM TREN STACK -> chuoi. Dung chung cho
    str(), print(), va moi noi sau nay can in."""
    if dtype == 'str':
        return
    if dtype == 'int':
        import il_features.int_type as _int_type
        _int_type.ensure_class(ctx)
        out.append('    call string TkvInt::Str(valuetype TkvInt)')
        return
    if dtype == 'complex':
        # Muc 6.8 (2/4, 2026-08-13): str(c)/print(c) - gia tri DA nam
        # tren stack, uy quyen ra complex_type.py (do vao local nhap
        # SCRATCH_STR de lay dia chi, ToString() la instance method).
        import il_features.complex_type as _complex_type
        return _complex_type.emit_to_str(out, ctx)
    records = (ctx or {}).get('records') or {}
    if dtype in records:
        # __str__ cho record (6.5, dunder overload - muc dau tien,
        # 2026-08-13). str()/print() DI QUA CHUNG diem nay nen sua 1 cho
        # lam CA HAI hoat dong. Validate chu ky TRUOC khi sinh IL - tranh
        # sinh callvirt sai kieu am tham (khac SyntaxError ro rang).
        record_methods = (ctx or {}).get('record_methods') or {}
        methods = record_methods.get(dtype, {})
        dunder = methods.get('__str__')
        if dunder is None:
            raise SyntaxError(
                f"il_codegen: record '{dtype}' khong co __str__ - str()/print() tren "
                f"record can dinh nghia 'def __str__(self) -> \"str\": ...'")
        if dunder.params or dunder.return_type is None or \
                dunder.return_type.dtype != 'str' or dunder.return_type.shape is not None:
            raise SyntaxError(
                f"il_codegen: record '{dtype}' co __str__ nhung chu ky sai - can dung "
                f"0 tham so va tra ve \"str\" ('def __str__(self) -> \"str\":')")
        from il_features.record_feature import _method_owner_class
        owner = _method_owner_class(ctx, dtype, '__str__')
        out.append(f'    callvirt instance string {owner}::__str__()')
        return
    ensure_class(ctx)
    if dtype == 'f64':
        out.append(f'    call string {TKVSTR_CLASS}::F64(float64)')
    elif dtype == 'f32':
        out.append(f'    call string {TKVSTR_CLASS}::F32(float32)')
    elif dtype == 'i64':
        out.append(f'    call string {TKVSTR_CLASS}::I64(int64)')
    elif dtype == 'i32':
        out.append(f'    call string {TKVSTR_CLASS}::I32(int32)')
    elif dtype == 'bool':
        # 2026-08-05: gia tri i32 0/1 TREN STACK nhung MANG NGHIA logic
        # (compare/boolop/not/in/all/any/startswith/endswith) - Python in
        # "True"/"False", khong phai "1"/"0". Khong doi dtype='i32' o BAT
        # KY noi nao khac (khai bao bien, phep toan) - chi danh nhan rieng
        # o diem goi str()/print() (xem string_feature.py's compile_str_
        # builtin), tranh lat lai bug AccessViolationException cu (TkvInt
        # nhan nham gia tri i32 tho, xem tkvstr.py mot doan tren).
        out.append(f'    call string {TKVSTR_CLASS}::Bool(int32)')
    else:
        raise SyntaxError(
            f"il_codegen: chua co duong chuyen '{dtype}' sang chuoi "
            f"(chi ho tro i32/i64/f32/f64/int/str/bool, hoac 1 record co __str__)")


def _m(sig, *body):
    return ([f'  .method public static {sig} cil managed', '  {', '    .maxstack 8']
            + list(body) + ['  }'])


def _ladder(clr_type, precisions):
    """G<p> tang dan, lay ban DAU TIEN parse nguoc lai bang chinh no."""
    lines = []
    for k, p in enumerate(precisions):
        lines += ['    ldarga.s 0', f'    ldstr "G{p}"', _INV,
                  f'    call instance string {clr_type}::ToString(string, '
                  'class [mscorlib]System.IFormatProvider)', '    stloc.s s']
        if k < len(precisions) - 1:
            lines += ['    ldloc.s s', _INV,
                      f'    call {"float64" if "Double" in clr_type else "float32"} '
                      f'{clr_type}::Parse(string, class [mscorlib]System.IFormatProvider)',
                      '    ldarg.0', '    beq LAD_DONE']
    lines.append('  LAD_DONE:')
    return lines


def _gen_class_il():
    lines = [
        f'.class public abstract sealed auto ansi {TKVSTR_CLASS}',
        '       extends [mscorlib]System.Object',
        '{',
    ]

    for name, clr in (('I32', '[mscorlib]System.Int32'), ('I64', '[mscorlib]System.Int64')):
        il_t = 'int32' if name == 'I32' else 'int64'
        lines += _m(
            f'string {name}({il_t} v)',
            '    ldarga.s 0', _INV,
            f'    call instance string {clr}::ToString(class [mscorlib]System.IFormatProvider)',
            '    ret')

    lines += _m(
        'string Bool(int32 v)',
        '    ldarg.0', '    brfalse BOOL_FALSE',
        '    ldstr "True"', '    ret',
        '  BOOL_FALSE:', '    ldstr "False"', '    ret')

    lines += _m(
        'string F64(float64 v)',
        '    .locals init (string s)',
        '    ldarg.0', '    call bool [mscorlib]System.Double::IsNaN(float64)',
        '    brfalse F64_NOTNAN', '    ldstr "nan"', '    ret',
        '  F64_NOTNAN:',
        '    ldarg.0', '    call bool [mscorlib]System.Double::IsInfinity(float64)',
        '    brfalse F64_NOTINF',
        '    ldarg.0', '    ldc.r8 0.0', '    blt F64_NEGINF',
        '    ldstr "inf"', '    ret',
        '  F64_NEGINF:', '    ldstr "-inf"', '    ret',
        '  F64_NOTINF:',
        # -0.0: '==' khong phan biet duoc, phai xet BIT DAU.
        '    ldarg.0', '    ldc.r8 0.0', '    bne.un F64_NOTZERO',
        '    ldarg.0',
        '    call int64 [mscorlib]System.BitConverter::DoubleToInt64Bits(float64)',
        '    ldc.i8 0', '    blt F64_NEGZERO',
        '    ldstr "0.0"', '    ret',
        '  F64_NEGZERO:', '    ldstr "-0.0"', '    ret',
        '  F64_NOTZERO:',
        *_ladder('[mscorlib]System.Double', (15, 16, 17)),
        '    ldloc.s s', f'    call string {TKVSTR_CLASS}::Post(string)', '    ret')

    lines += _m(
        'string F32(float32 v)',
        '    .locals init (string s)',
        '    ldarg.0', '    call bool [mscorlib]System.Single::IsNaN(float32)',
        '    brfalse F32_NOTNAN', '    ldstr "nan"', '    ret',
        '  F32_NOTNAN:',
        '    ldarg.0', '    call bool [mscorlib]System.Single::IsInfinity(float32)',
        '    brfalse F32_NOTINF',
        '    ldarg.0', '    ldc.r4 0.0', '    blt F32_NEGINF',
        '    ldstr "inf"', '    ret',
        '  F32_NEGINF:', '    ldstr "-inf"', '    ret',
        '  F32_NOTINF:',
        *_ladder('[mscorlib]System.Single', (7, 8, 9)),
        '    ldloc.s s', f'    call string {TKVSTR_CLASS}::Post(string)', '    ret')

    # Post: dua chuoi .NET ve dung khuon Python.
    lines += _m(
        'string Post(string s)',
        '    .locals init (int32 i, int32 e)',
        '    ldarg.0', '    ldc.i4 69',   # 'E'
        f'    callvirt instance int32 {_STR}::IndexOf(char)', '    stloc.s i',
        '    ldloc.s i', '    ldc.i4.0', '    blt PS_NOEXP',
        '    ldarg.0', '    ldloc.s i', '    ldc.i4.1', '    add',
        f'    callvirt instance string {_STR}::Substring(int32)', _INV,
        '    call int32 [mscorlib]System.Int32::Parse(string, '
        'class [mscorlib]System.IFormatProvider)', '    stloc.s e',
        # Chi so mu 15 la cho .NET va Python khac nhau ve NGUONG.
        '    ldloc.s e', '    ldc.i4 15', '    bne.un PS_LOWER',
        '    ldarg.0', '    ldloc.s i',
        f'    call string {TKVSTR_CLASS}::Expand16(string, int32)', '    ret',
        '  PS_LOWER:',
        '    ldarg.0', '    ldstr "E"', '    ldstr "e"',
        f'    callvirt instance string {_STR}::Replace(string, string)', '    ret',
        '  PS_NOEXP:',
        '    ldarg.0', '    ldstr "."',
        f'    callvirt instance bool {_STR}::Contains(string)', '    brtrue PS_ASIS',
        '    ldarg.0', '    ldstr ".0"',
        f'    call string {_STR}::Concat(string, string)', '    ret',
        '  PS_ASIS:', '    ldarg.0', '    ret')

    # Expand16: "d.dddE+15" -> dang thuong 16 chu so phan nguyen.
    lines += _m(
        'string Expand16(string s, int32 epos)',
        '    .locals init (string sign, string mant, string digs, string frac)',
        '    ldstr ""', '    stloc.s sign',
        '    ldarg.0', '    ldc.i4.0', '    ldarg.1',
        f'    callvirt instance string {_STR}::Substring(int32, int32)', '    stloc.s mant',
        '    ldloc.s mant', '    ldstr "-"',
        f'    callvirt instance bool {_STR}::StartsWith(string)', '    brfalse EX_NOSIGN',
        '    ldstr "-"', '    stloc.s sign',
        '    ldloc.s mant', '    ldc.i4.1',
        f'    callvirt instance string {_STR}::Substring(int32)', '    stloc.s mant',
        '  EX_NOSIGN:',
        '    ldloc.s mant', '    ldstr "."', '    ldstr ""',
        f'    callvirt instance string {_STR}::Replace(string, string)', '    stloc.s digs',
        '    ldloc.s digs', f'    callvirt instance int32 {_STR}::get_Length()',
        '    ldc.i4 16', '    bgt EX_LONG',
        '    ldloc.s digs', '    ldc.i4 16', '    ldc.i4 48',   # '0'
        f'    callvirt instance string {_STR}::PadRight(int32, char)', '    stloc.s digs',
        '    ldstr "0"', '    stloc.s frac',
        '    br EX_JOIN',
        '  EX_LONG:',
        '    ldloc.s digs', '    ldc.i4 16',
        f'    callvirt instance string {_STR}::Substring(int32)', '    stloc.s frac',
        '    ldloc.s digs', '    ldc.i4.0', '    ldc.i4 16',
        f'    callvirt instance string {_STR}::Substring(int32, int32)', '    stloc.s digs',
        '  EX_JOIN:',
        '    ldloc.s sign', '    ldloc.s digs', '    ldstr "."', '    ldloc.s frac',
        f'    call string {_STR}::Concat(string, string, string, string)', '    ret')

    # Duong VAO, doi xung voi F64: Python's float() nhan 'inf'/'-inf'/
    # 'nan' (va bo qua khoang trang hai dau); .NET Framework nem
    # FormatException cho ca ba. Chuan hoa TRUOC khi giao cho Parse.
    lines += _m(
        'float64 ParseF64(string s)',
        '    .locals init (string t)',
        f'    ldarg.0', f'    callvirt instance string {_STR}::Trim()',
        f'    callvirt instance string {_STR}::ToLowerInvariant()', '    stloc.s t',
        '    ldloc.s t', '    ldstr "inf"',
        f'    call bool {_STR}::op_Equality(string, string)', '    brtrue PF_INF',
        '    ldloc.s t', '    ldstr "infinity"',
        f'    call bool {_STR}::op_Equality(string, string)', '    brtrue PF_INF',
        '    ldloc.s t', '    ldstr "+inf"',
        f'    call bool {_STR}::op_Equality(string, string)', '    brtrue PF_INF',
        '    ldloc.s t', '    ldstr "-inf"',
        f'    call bool {_STR}::op_Equality(string, string)', '    brtrue PF_NEGINF',
        '    ldloc.s t', '    ldstr "-infinity"',
        f'    call bool {_STR}::op_Equality(string, string)', '    brtrue PF_NEGINF',
        '    ldloc.s t', '    ldstr "nan"',
        f'    call bool {_STR}::op_Equality(string, string)', '    brtrue PF_NAN',
        '    ldarg.0', _INV,
        '    call float64 [mscorlib]System.Double::Parse(string, '
        'class [mscorlib]System.IFormatProvider)', '    ret',
        '  PF_INF:',
        '    ldc.r8 (00 00 00 00 00 00 F0 7F)', '    ret',
        '  PF_NEGINF:',
        '    ldc.r8 (00 00 00 00 00 00 F0 FF)', '    ret',
        '  PF_NAN:',
        '    ldc.r8 (00 00 00 00 00 00 F8 FF)', '    ret')

    # Replace: '.replace(old, new)' - S.String::Replace(string,string) cua
    # .NET NEM ArgumentException khi oldStr rong, khac Python (chen newStr
    # xen giua MOI ky tu, ke ca dau/cuoi). 'old' la bieu thuc bat ky luc
    # chay (khong biet truoc rong hay khong luc bien dich) nen phai re
    # nhanh NGAY TRONG CIL, khong phai o compile-time (giao Gemini nghien
    # cuu thuat toan 2026-08-05, xac nhan dung mau).
    lines += _m(
        'string Replace(string src, string oldStr, string newStr)',
        '    .locals init (int32 i, int32 n, class [mscorlib]System.Text.StringBuilder sb)',
        '    ldarg.1', f'    callvirt instance int32 {_STR}::get_Length()',
        '    brtrue RP_NORMAL',
        # old == "": chen newStr truoc MOI ky tu cua src, roi mot lan cuoi
        # o duoi cung - dung y Python's str.replace('', x).
        '    ldarg.0', f'    callvirt instance int32 {_STR}::get_Length()', '    stloc.s n',
        '    ldloc.s n', '    ldc.i4.1', '    add',
        '    ldarg.2', f'    callvirt instance int32 {_STR}::get_Length()', '    mul',
        '    ldloc.s n', '    add',
        '    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor(int32)',
        '    stloc.s sb',
        '    ldc.i4.0', '    stloc.s i',
        '  RP_LOOP:',
        '    ldloc.s i', '    ldloc.s n', '    bge RP_TAIL',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)',
        '    pop',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s i',
        f'    callvirt instance char {_STR}::get_Chars(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(char)', '    pop',
        '    ldloc.s i', '    ldc.i4.1', '    add', '    stloc.s i',
        '    br RP_LOOP',
        '  RP_TAIL:',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb',
        '    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()',
        '    ret',
        '  RP_NORMAL:',
        '    ldarg.0', '    ldarg.1', '    ldarg.2',
        f'    callvirt instance string {_STR}::Replace(string, string)',
        '    ret')

    # ReplaceCount: '.replace(old, new, count)' (batch 5.5b, 2026-08-13)
    # - gioi han so lan thay the TOI DA 'count' lan tinh tu trai. count<0
    # coi nhu KHONG gioi han (goi lai Replace() da co, tai dung nhanh
    # old="" cua no). old="" voi count cu the: chen newStr TRUOC moi ky
    # tu, dung SAU khi da chen du count lan (ke ca gap SAU ky tu cuoi neu
    # count > do dai src) - khop 'aaa'.replace('', '-', 2) Python ->
    # '-a-aa'. old!="": vong lap IndexOf(oldStr, pos) tim tung khop, dung
    # khi du count lan hoac het khop.
    lines += _m(
        'string ReplaceCount(string src, string oldStr, string newStr, int32 count)',
        '    .locals init (int32 i, int32 n, int32 pos, int32 replaced, int32 idx, '
        'class [mscorlib]System.Text.StringBuilder sb)',
        '    ldarg.3', '    ldc.i4.0', '    bge RC_NONNEG',
        '    ldarg.0', '    ldarg.1', '    ldarg.2',
        f'    call string {TKVSTR_CLASS}::Replace(string, string, string)',
        '    ret',
        '  RC_NONNEG:',
        '    ldarg.1', f'    callvirt instance int32 {_STR}::get_Length()',
        '    brtrue RC_OLDNONEMPTY',
        # old == "": chen newStr truoc toi da 'count' ky tu dau, dung du
        # thi thoi (khong lap het chuoi nhu Replace() lam khi khong gioi
        # han).
        '    ldarg.0', f'    callvirt instance int32 {_STR}::get_Length()', '    stloc.s n',
        '    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()',
        '    stloc.s sb',
        '    ldc.i4.0', '    stloc.s i',
        '  RC_EMPTY_LOOP:',
        '    ldloc.s i', '    ldarg.3', '    bge RC_EMPTY_TAIL',
        '    ldloc.s i', '    ldloc.s n', '    bge RC_EMPTY_TAIL',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s i',
        f'    callvirt instance char {_STR}::get_Chars(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(char)', '    pop',
        '    ldloc.s i', '    ldc.i4.1', '    add', '    stloc.s i',
        '    br RC_EMPTY_LOOP',
        '  RC_EMPTY_TAIL:',
        # neu count > do dai src: con 1 gap SAU ky tu cuoi chua chen.
        '    ldarg.3', '    ldloc.s n', '    ble RC_EMPTY_NOEXTRA',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '  RC_EMPTY_NOEXTRA:',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s i',
        f'    callvirt instance string {_STR}::Substring(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb',
        '    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()',
        '    ret',
        '  RC_OLDNONEMPTY:',
        # old != "": vong lap IndexOf(oldStr, pos), thay toi da 'count' lan.
        '    ldc.i4.0', '    stloc.s pos',
        '    ldc.i4.0', '    stloc.s replaced',
        '    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()',
        '    stloc.s sb',
        '  RC_LOOP:',
        '    ldloc.s replaced', '    ldarg.3', '    bge RC_TAIL',
        '    ldarg.0', '    ldarg.1', '    ldloc.s pos',
        f'    callvirt instance int32 {_STR}::IndexOf(string, int32)',
        '    stloc.s idx',
        '    ldloc.s idx', '    ldc.i4.0', '    blt RC_TAIL',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s pos', '    ldloc.s idx', '    ldloc.s pos', '    sub',
        f'    callvirt instance string {_STR}::Substring(int32, int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb', '    ldarg.2',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s idx', '    ldarg.1', f'    callvirt instance int32 {_STR}::get_Length()', '    add',
        '    stloc.s pos',
        '    ldloc.s replaced', '    ldc.i4.1', '    add', '    stloc.s replaced',
        '    br RC_LOOP',
        '  RC_TAIL:',
        '    ldloc.s sb', '    ldarg.0', '    ldloc.s pos',
        f'    callvirt instance string {_STR}::Substring(int32)',
        '    callvirt instance class [mscorlib]System.Text.StringBuilder '
        '[mscorlib]System.Text.StringBuilder::Append(string)', '    pop',
        '    ldloc.s sb',
        '    callvirt instance string [mscorlib]System.Text.StringBuilder::ToString()',
        '    ret')

    # RFind: '.rfind(sub)' - String::LastIndexOf(string) cua .NET tra ve
    # KHAC Python khi sub="": "hello".rfind("") Python cho 5 (do dai
    # chuoi - khop sau CUNG cua chuoi rong la vi tri NGAY SAU ky tu cuoi),
    # .NET's LastIndexOf("") cho 4 (coi vi tri hop le CUOI la CHI SO ky tu
    # cuoi, khong phai do dai) - do THAT bang arbiter, khong doan (tim ra
    # SAU khi .find()/IndexOf("") da xac nhan khop san, chi rieng huong
    # 'r' bi lech). 'sub' la bieu thuc bat ky luc chay nen phai re nhanh
    # trong CIL, khong quyet dinh duoc luc bien dich.
    lines += _m(
        # tham so KHONG duoc dat ten 'sub' - trung mnemonic opcode CIL
        # 'sub' (phep tru), ilasm bao 'syntax error at token 'sub'' (da
        # do that, khong doan).
        'int32 RFind(string src, string subStr)',
        '    ldarg.1', f'    callvirt instance int32 {_STR}::get_Length()',
        '    brtrue RF_NORMAL',
        '    ldarg.0', f'    callvirt instance int32 {_STR}::get_Length()',
        '    ret',
        '  RF_NORMAL:',
        '    ldarg.0', '    ldarg.1',
        f'    callvirt instance int32 {_STR}::LastIndexOf(string)',
        '    ret')

    # IsDigit: Python str.isdigit() tra False cho chuoi rong; .NET char
    # IsDigit chi la test tung ky tu nen can vong lap + guard length.
    lines += _m(
        'int32 IsDigit(string s)',
        '    .locals init (int32 i, int32 n)',
        '    ldarg.0', f'    callvirt instance int32 {_STR}::get_Length()',
        '    stloc.s n',
        '    ldloc.s n', '    brtrue ID_INIT',
        '    ldc.i4.0', '    ret',
        '  ID_INIT:',
        '    ldc.i4.0', '    stloc.s i',
        '  ID_LOOP:',
        '    ldloc.s i', '    ldloc.s n', '    bge ID_TRUE',
        '    ldarg.0', '    ldloc.s i',
        f'    callvirt instance char {_STR}::get_Chars(int32)',
        '    call bool [mscorlib]System.Char::IsDigit(char)',
        '    brfalse ID_FALSE',
        '    ldloc.s i', '    ldc.i4.1', '    add', '    stloc.s i',
        '    br ID_LOOP',
        '  ID_FALSE:',
        '    ldc.i4.0', '    ret',
        '  ID_TRUE:',
        '    ldc.i4.1', '    ret')

    lines.append('}')
    return lines
