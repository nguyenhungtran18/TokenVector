# -*- coding: utf-8 -*-
"""'sep'.join(lst) - noi cac phan tu 1 list[str] bang 1 chuoi ngan cach
(2026-08-03).

Port THANG String::Join(string, IEnumerable<string>) cua BCL - khong tu
viet vong lap. Ho tro CA HAI cach viet cua Python:
    sep = ", " ; s = sep.join(xs)        -> tag 'method_call' (bien)
    s = ", ".join(xs)                    -> tag 'method_call_expr' (chuoi hang)
Cach thu hai truoc day KHONG parse duoc ("con thua token '.'") - do la
cach viet PHO BIEN HON HAN trong code that.

CHI nhan list[str] (Python nem TypeError khi phan tu khong phai chuoi;
o day la loi LUC BIEN DICH, som hon)."""
from il_dispatch import register_expr_method, register_expr_codegen
from typed_dsl_parser import TypeAnn

_JOIN_IL = ('    call string [mscorlib]System.String::Join(string, class '
            '[mscorlib]System.Collections.Generic.IEnumerable`1<string>)')


def _check_list_of_str(ta, where):
    if ta is None or ta.shape != 'list' or ta.dtype != 'str':
        raise SyntaxError(
            f"il_codegen: {where} can tham so la 1 list[str] (dang co "
            f"shape={getattr(ta, 'shape', None)!r} dtype={getattr(ta, 'dtype', None)!r})")


def compile_str_join(node, scope, out, dtype, ctx):
    """Tag 'method_call': node = ('method_call', ten_bien, 'join', args)."""
    args = node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: sep.join(lst) can dung 1 tham so la list[str]")
    if args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: sep.join(lst) can tham so la 1 BIEN list[str] - gan ra 1 bien truoc")
    _check_list_of_str(scope[args[0][1]][2], "sep.join(lst)")
    ctx['load_var_ref'](node[1], scope, out)
    ctx['load_var_ref'](args[0][1], scope, out)
    out.append(_JOIN_IL)


_RECV = '__tkv_recv_expr__'


def _compile_str_method_on_expr(base_node, name, args, scope, out, dtype, ctx):
    """'<bieu thuc str>.method(...)' - vd 's[a:b].strip()', 'f(x).upper()'
    (2026-08-03). MOI codegen method chuoi da dang ky deu nap DOI TUONG
    NHAN dau tien qua ctx['load_var_ref'](node[1], ...); nen thay vi viet
    lai tung method, gan bieu thuc nhan vao 1 ten AO trong scope roi doi
    load_var_ref cua RIENG ten do thanh 'bien dich chinh bieu thuc'. Nho
    vay moi method chuoi (ke ca dang ky sau nay) dung duoc ngay."""
    from il_features.record_feature import _STR_METHODS
    fn = _STR_METHODS.get(name)
    if fn is None:
        raise SyntaxError(
            f"il_codegen: '<bieu thuc>.{name}(...)' khong phai method chuoi da biet "
            f"(chi: {sorted(_STR_METHODS)}) - gan bieu thuc ra 1 bien truoc roi goi "
            f"method tren bien do")
    # Ten AO phai DUY NHAT theo tung muc long ('s.strip().upper()' goi de
    # quy vao chinh ham nay) - dung id cua node nhan lam hau to.
    recv = f'{_RECV}{id(base_node)}'
    inner = ('method_call', recv, name, args)
    scope.vars[recv] = ('__expr__', None, TypeAnn('str', None))
    real_load = ctx['load_var_ref']

    def _load(nm, sc, o):
        if nm == recv:
            ctx['compile_expr'](base_node, sc, o, 'str', ctx)
            return
        real_load(nm, sc, o)

    sub_ctx = dict(ctx)
    sub_ctx['load_var_ref'] = _load
    try:
        fn(inner, scope, out, dtype, sub_ctx)
    finally:
        del scope.vars[recv]


def _compile_method_on_expr_generic(base_node, name, args, scope, out, dtype, ctx, obj_ta):
    """Tong quat hoa _compile_str_method_on_expr (Task 4, extern-class,
    2026-08-18): '<bieu thuc extern-class>.Method(...)' - vd
    's.Append("y").ToString()' (base_node = ('method_call', 's', 'Append',
    [...]), obj_ta = TypeAnn('Sb', 'extern_class') suy tu ket qua Append).
    KHAC _compile_str_method_on_expr (tra cuu rieng qua _STR_METHODS): o
    day nhan obj_ta LAM THAM SO va di THANG qua dispatcher DAY DU
    compile_method_call (record_feature.py) - do la NGUON SU THAT DUY
    NHAT cho MOI shape (str/list/dict/file/record/extern_class...), tranh
    viet lai 1 ban tra cuu rieng chi cho extern_class o day."""
    import il_features.record_feature as _rf
    recv = f'{_RECV}{id(base_node)}'
    inner = ('method_call', recv, name, args)
    scope.vars[recv] = ('__expr__', None, obj_ta)
    real_load = ctx['load_var_ref']

    def _load(nm, sc, o):
        if nm == recv:
            ctx['compile_expr'](base_node, sc, o, obj_ta.dtype, ctx)
            return
        real_load(nm, sc, o)

    sub_ctx = dict(ctx)
    sub_ctx['load_var_ref'] = _load
    try:
        _rf.compile_method_call(inner, scope, out, dtype, sub_ctx)
    finally:
        del scope.vars[recv]


def compile_method_call_expr(node, scope, out, dtype, ctx):
    """Tag 'method_call_expr' (2026-08-03): method goi tren 1 BIEU THUC
    thay vi 1 ten bien. '<chuoi>.join(lst)' co duong rieng ben duoi; moi
    method CHUOI khac di qua _compile_str_method_on_expr."""
    base_node, name, args = node[1], node[2], node[3]
    if isinstance(base_node, tuple) and len(base_node) >= 2 and base_node[0] == 'call' and base_node[1] == 'super':
        import il_features.record_feature as _rf
        return _rf.compile_method_call(node, scope, out, dtype, ctx)
    if name != 'join':
        base_dtype = ctx['infer_dtype'](base_node, scope, ctx.get('func_table'),
                                        ctx.get('records'), ctx.get('record_methods'))
        # Task 4 (extern-class, 2026-08-18): '<bieu thuc extern-class>.Method(...)'
        # - vd 's.Append("y").ToString()'. infer_dtype tag 'method_call' da
        # tra dung TEN CLASS (vd 'Sb') qua EXPR_METHOD_SHAPE (dang ky o
        # tkv_compile.py's compile_tkv_cli) - CHI can nhan dien ten do co
        # phai 1 extern-class DA khai bao khong (import tri hoan tranh
        # circular import, giong nhanh 'super' o tren).
        import il_codegen as _ilc
        if base_dtype in _ilc._EXTERN_CLASS_DEFS:
            _compile_method_on_expr_generic(base_node, name, args, scope, out, dtype, ctx,
                                             TypeAnn(base_dtype, 'extern_class'))
            return
        if base_dtype != 'str':
            raise SyntaxError(
                f"il_codegen: '<bieu thuc>.{name}(...)' hien chi ho tro khi bieu thuc nhan "
                f"la CHUOI (dang suy ra dtype={base_dtype!r}) - gan ra 1 bien truoc roi goi "
                f"method tren bien do")
        _compile_str_method_on_expr(base_node, name, args, scope, out, dtype, ctx)
        return
    if len(args) != 1 or args[0][0] != 'var':
        raise SyntaxError(
            "il_codegen: \"sep\".join(lst) can dung 1 tham so la 1 BIEN list[str]")
    _check_list_of_str(scope[args[0][1]][2], '"sep".join(lst)')
    ctx['compile_expr'](base_node, scope, out, 'str', ctx)
    ctx['load_var_ref'](args[0][1], scope, out)
    out.append(_JOIN_IL)


register_expr_method('str', 'join', compile_str_join, return_dtype='str')
register_expr_codegen('method_call_expr', compile_method_call_expr)
