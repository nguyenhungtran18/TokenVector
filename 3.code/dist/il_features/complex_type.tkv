# -*- coding: utf-8 -*-
"""Kieu 'complex' qua System.Numerics.Complex (muc 6.8, 2/4, 2026-08-13).

Chi ho tro pham vi HEP da thong nhat: constructor 2 tham so `complex(re, im)`
(ca hai ep ve f64), toan tu '+'/'-'/'*'/'/' giua 2 gia tri 'complex', thuoc
tinh doc '.real'/'.imag'/'.magnitude', va `str()`. KHONG co literal `3+4j`,
KHONG '=='/'!=' (BCL Complex co op_Equality that nhung ngoai pham vi task
nay), KHONG long trong container (list/dict/set/tuple).

`System.Numerics.Complex` la 1 STRUCT (valuetype) san co trong assembly
System.Numerics - '.assembly extern System.Numerics' DA CO SAN khong dieu
kien trong tkv_compile.py (khong can sua). Vi la struct, doc thuoc tinh
(.real/.imag/.magnitude) va str() (ToString()) deu la INSTANCE method tren
value type -> CIL can DIA CHI (managed pointer), khong the goi truc tiep
tren 1 gia tri TAM tren stack - dung lai CHINH 2 co che da co san:

  - '.real'/'.imag'/'.magnitude' tren 1 BIEN: dung ctx['load_var_addr']
    (da xac nhan qua record_feature.py's compile_attr, nhanh dict_kvpair)
    - obj luon la 1 TEN BIEN (node[1] cua tag 'attr'), scope tra ve dung
      chi so IL cua no, khong can hardcode ten slot.
  - str(<complex>): gia tri co the la KET QUA 1 bieu thuc (vd
    str(complex(1,2))), khong phai luon la 1 bien co san dia chi. Dung 1
    LOCAL NHAP (scratch, mo phong int_type.py's SCRATCH_*) duoc khai bao
    VO DIEU KIEN trong moi ham (xem il_codegen.py's
    _first_pass_collect_locals) de 'do' gia tri TAM vao do roi lay dia chi
    - giong het ly do TkvInt can 4 local nhap cho duong noi tuyen +/-/*.
"""
from il_core import IL_SCALAR
from il_dispatch import register_expr_builtin

# Class ref TRAN (khong 'valuetype' o truoc) - dung sau '::' trong 1 loi
# goi static/instance method, giong BigInteger's BIG trong int_type.py.
COMPLEX_CLASS = '[System.Numerics]System.Numerics.Complex'
# Mo ta VALUETYPE day du - dung lam kieu tra ve/tham so, giong int_type.py's 'v'.
CPLX = f'valuetype {COMPLEX_CLASS}'

# Local nhap DUY NHAT dung cho str(<bieu thuc complex>) - xem docstring.
SCRATCH_STR = '__tkvcplx_str'

_COMPLEX_BINOPS = {'+': 'Add', '-': 'Subtract', '*': 'Multiply', '/': 'Divide'}
_COMPLEX_PROPS = {'real': 'get_Real', 'imag': 'get_Imaginary', 'magnitude': 'get_Magnitude'}


def register_complex_dtype():
    IL_SCALAR['complex'] = CPLX


def scratch_locals():
    """(ten, dtype) local nhap can khai bao VO DIEU KIEN trong moi ham -
    xem il_codegen.py's _first_pass_collect_locals (mirror _int_type.
    scratch_locals())."""
    return [(SCRATCH_STR, 'complex')]


def compile_binop(op, left, right, scope, out, ctx):
    """'+'/'-'/'*'/'/' giua 2 gia tri 'complex' - goi THANG cac static
    method Add/Subtract/Multiply/Divide co san tren System.Numerics.Complex
    (khong noi tuyen nhu TkvInt: Complex khong co van de tran/duong nhanh
    can toi uu, cu goi BCL la du chinh xac va don gian)."""
    if op not in _COMPLEX_BINOPS:
        raise SyntaxError(
            f"il_codegen: '{op}' khong ho tro tren 'complex' (chi +,-,*,/ - "
            f"khong co literal 3+4j, khong '==','!=', khong long container)")
    compile_expr = ctx['compile_expr']
    compile_expr(left, scope, out, 'complex', ctx)
    compile_expr(right, scope, out, 'complex', ctx)
    method = _COMPLEX_BINOPS[op]
    out.append(f'    call {CPLX} {COMPLEX_CLASS}::{method}({CPLX}, {CPLX})')


def compile_attr(obj_name, field_name, scope, out, dtype, ctx):
    """'.real'/'.imag'/'.magnitude' tren 1 bien 'complex' - dia chi qua
    ctx['load_var_addr'] (KHONG hardcode ten slot IL, dung dung co che
    dang dung cho dict_kvpair's '.key'/'.val' trong record_feature.py).
    Ca 3 thuoc tinh tra ve f64 - 'dtype' la kieu NGU CANH ben ngoai yeu
    cau (vd gan cho 1 bien f32), can widen/thu hep dung nhu moi field
    khac (xem record_feature.py's compile_attr nhanh record thuong)."""
    method = _COMPLEX_PROPS[field_name]
    ctx['load_var_addr'](obj_name, scope, out)
    out.append(f'    call instance float64 {COMPLEX_CLASS}::{method}()')
    ctx['widen_if_needed']('f64', dtype, out)


def emit_to_str(out, ctx):
    """'str(c)'/'print(c)' khi dtype='complex' - GIA TRI DA NAM TREN STACK
    (giao uoc chung cua emit_to_str, xem tkvstr.py). Do vao local nhap
    SCRATCH_STR (khai bao VO DIEU KIEN, xem scratch_locals()) roi lay dia
    chi bang TEN (khong qua scope: local nay duoc dat trong '.locals init'
    cua HAM chinh dang bien dich duoi dung ten nay, ilasm chap nhan tham
    chieu local theo ten giong het cach TkvInt/TkvStr's helper method tu
    dung ten cuc bo cua chinh chung, vd 'ldloc.s r' trong int_type.py)."""
    out.append(f'    stloc.s {SCRATCH_STR}')
    out.append(f'    ldloca.s {SCRATCH_STR}')
    out.append(f'    call instance string {COMPLEX_CLASS}::ToString()')


def compile_ctor(args, scope, out, dtype, ctx):
    """'complex(re, im)' - constructor 2 tham so, ca hai ep ve f64 (mau
    dang ky theo divmod_builtin.py: register_expr_builtin cho 1 builtin
    dang ham tra ve 1 gia tri vo huong)."""
    if len(args) != 2:
        raise SyntaxError(
            "il_codegen: complex(re, im) chi nhan dung 2 tham so (khong ho tro "
            "literal 3+4j hay complex(1 tham so))")
    compile_expr = ctx['compile_expr']
    compile_expr(args[0], scope, out, 'f64', ctx)
    compile_expr(args[1], scope, out, 'f64', ctx)
    out.append(f'    newobj instance void {COMPLEX_CLASS}::.ctor(float64, float64)')


register_complex_dtype()
register_expr_builtin('complex', compile_ctor, 'complex')
