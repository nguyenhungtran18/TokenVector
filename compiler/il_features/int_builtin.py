# -*- coding: utf-8 -*-
"""int(x) - doi xung voi str(x) da co san (string_feature.py), THEM
2026-08-03 (Giai doan 1). Truoc do DSL CHI co mot chieu so->chuoi; chieu
nguoc lai KHONG CO gi ca, nen moi doan code doc so tu chuoi (tham so dong
lenh, 1 truong CSV, ket qua json_get_str, giao thuc chuoi trong
buffer.tkv...) deu ket - do la ly do THAT khien buffer_size() cua
buffer.tkv phai hardcode 1024 (bug ghi trong ke hoach v2).

Ho tro:
- str  -> i32: Int32.Parse voi InvariantCulture (BAT BUOC dung culture
  bat bien - may nay locale vi-VN, da tung co bug THAT y het voi
  Single.Parse, xem STATUS.md).
- f32/f64 -> i32: 'conv.i4' - CAT phan thap phan HUONG VE 0, giong het
  int(3.7)==3 va int(-3.7)==-3 cua Python (KHONG lam tron).
- i64 -> i32: 'conv.i4' (cat bit cao neu tran - giong hanh vi ep kieu cua
  .NET unchecked, KHONG giong Python int vo han; ghi ro khong giau).
- i32 -> i32: khong sinh lenh nao.

KHAC Python co y thuc: chuoi KHONG hop le lam Int32.Parse NEM exception
(chuong trinh dung ngay) thay vi ValueError bat duoc. Chon NEM thay vi
tra 0 am tham - sai am tham la thu dat nhat trong 3 bug cua phien truoc."""
from il_dispatch import register_expr_builtin


def push_int_builtin(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: int() chi nhan dung 1 tham so")
    src = ctx['infer_dtype'](args[0], scope, ctx.get('func_table'), ctx.get('records'),
                             ctx.get('record_methods'))
    int_dtypes, float_dtypes = ctx['int_dtypes'], ctx['float_dtypes']

    if dtype == 'int':
        # Ngu canh 'int' (vo han chu so, moc 6 lat 3 2026-08-05): KHONG
        # duoc di duong Int32.Parse roi nho _widen_if_needed nang len -
        # nhu the int("99999999999999999999") NEM trong khi Python tra ve
        # dung so. Xem int_type.compile_to_int.
        import il_features.int_type as _int_type
        return _int_type.compile_to_int(args[0], src, scope, out, ctx)

    if src == 'str':
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    call class [mscorlib]System.Globalization.CultureInfo '
                   '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')
        out.append('    call int32 [mscorlib]System.Int32::Parse(string, '
                   'class [mscorlib]System.IFormatProvider)')
        return
    if src in float_dtypes or src == 'i64':
        ctx['compile_expr'](args[0], scope, out, src, ctx)
        out.append('    conv.i4')
        return
    # i32 hoac khong suy duoc kieu (None) - bien dich thang sang i32,
    # de _compile_expr tu bao loi neu that su khong hop le.
    ctx['compile_expr'](args[0], scope, out, 'i32', ctx)


register_expr_builtin('int', push_int_builtin, 'i32', native_int=True)
