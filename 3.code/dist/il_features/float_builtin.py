# -*- coding: utf-8 -*-
"""float(x) - doi xung voi int(x) (int_builtin.py), THEM 2026-08-03 khi
viet cong cu THAT tools/tkvcalc.tkv: doc so THUC tu chuoi la viec co
mat trong moi chuong trinh doc du lieu (tham so dong lenh, 1 truong CSV,
1 the so cua bo phan tich tu vung) - truoc do CHI co int().

Ho tro:
- str      -> f64: Double.Parse voi InvariantCulture (BAT BUOC dung
  culture bat bien - may nay locale vi-VN, da tung co bug THAT y het voi
  Single.Parse, xem STATUS.md).
- i32/i64  -> f64: 'conv.r8'.
- f32      -> f64: 'conv.r8'.
- f64      -> f64: khong sinh lenh nao.

KHAC Python co y thuc (giong het int()): chuoi KHONG hop le lam
Double.Parse NEM exception thay vi ValueError bat duoc."""
from il_dispatch import register_expr_builtin


def push_float_builtin(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: float() chi nhan dung 1 tham so")
    src = ctx['infer_dtype'](args[0], scope, ctx.get('func_table'), ctx.get('records'),
                             ctx.get('record_methods'))
    if src == 'str':
        # moc 7 (2026-08-05): di qua TkvStr::ParseF64 chu khong goi thang
        # Double::Parse - Python's float() nhan "inf"/"-inf"/"nan"
        # (float('inf') la cach viet BINH THUONG de lay vo cuc), .NET
        # Framework thi nem FormatException. Doi xung voi duong ra:
        # str(float('inf')) phai lai ra 'inf'.
        import il_features.tkvstr as _tkvstr
        _tkvstr.ensure_class(ctx)
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    call float64 TkvStr::ParseF64(string)')
        return
    if src == 'f64':
        ctx['compile_expr'](args[0], scope, out, 'f64', ctx)
        return
    if src is None:
        # Khong suy duoc kieu - bien dich thang sang f64, de _compile_expr
        # tu bao loi RO RANG neu that su khong hop le.
        ctx['compile_expr'](args[0], scope, out, 'f64', ctx)
        return
    ctx['compile_expr'](args[0], scope, out, src, ctx)
    out.append('    conv.r8')


register_expr_builtin('float', push_float_builtin, 'f64')


def push_round_builtin(args, scope, out, dtype, ctx):
    """round(x) / round(x, n) - Python Banker's Rounding (half-to-even) (Moc 15, 2026-08-09).
    1 tham so: tra ve int32 (conv.i4).
    2 tham so: tra ve float64."""
    if len(args) < 1 or len(args) > 2:
        raise SyntaxError("il_codegen: round(x) hoac round(x, n) nhan 1 hoac 2 tham so")
    compile_expr = ctx['compile_expr']
    if len(args) == 1:
        compile_expr(args[0], scope, out, 'f64', ctx)
        out.append('    call float64 [mscorlib]System.Math::Round(float64)')
        if dtype in ('int', 'i32') or dtype is None:
            out.append('    conv.i4')
        elif dtype == 'i64':
            out.append('    conv.i8')
    else:
        compile_expr(args[0], scope, out, 'f64', ctx)
        compile_expr(args[1], scope, out, 'i32', ctx)
        out.append('    call float64 [mscorlib]System.Math::Round(float64, int32)')


def _round_dtype_fn(args, scope):
    if len(args) == 1:
        return 'i32'
    return 'f64'


register_expr_builtin('round', push_round_builtin, 'f64', return_dtype_fn=_round_dtype_fn)
