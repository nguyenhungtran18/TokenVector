# -*- coding: utf-8 -*-
"""datetime/timedelta - kieu that (Phase 4, 2026-08-11).

Nguoi dung CHON huong "kieu datetime rieng" (khong phai ham tu do tren
i64 tho): TypeAnn.dtype 'datetime'/'timedelta' la 2 DTYPE moi, vat ly deu
la int64 (so ticks .NET, 100ns/don vi - giong het System.DateTime.Ticks/
System.TimeSpan.Ticks) nhung PHAN BIET o tang kieu (khong the gan lan cho
nhau, khong the cong truc tiep voi i64 thuong) - dung shape_key = dtype
(giong 'str', xem _shape_key trong il_codegen.py) de d.strftime(fmt) dispatch
dung qua register_expr_method.

Vi datetime/timedelta VAT LY deu la int64 ticks, datetime +/- timedelta
va datetime - datetime CHI la phep add/sub int64 THUONG - khong can goi
BCL, tranh dung toan tu '+'/'-' tong quat (rui ro cao, phai sua binop
dispatch dung chung cho MOI dtype) - thay bang 3 HAM TU DO rieng
(datetime_add/datetime_sub/datetime_diff) - THU HEP PHAM VI CO Y THUC,
giong tinh than Phase 3.2 (defaultdict/Counter).

strftime/strptime dich ky hieu dinh dang Python (%Y/%m/%d/...) sang
.NET custom format string NGAY LUC BIEN DICH (fmt BAT BUOC la CHUOI HANG
- khong ho tro bien) - giong phong cach macro text-level cua .format()/
%-format (Phase 1.1/1.2).

Hop nhat (2026-08-11, cung phien, theo yeu cau nguoi dung): xoa han
stdlib_datetime.py cu ('datetime_now_utc()'/'datetime_ticks()' 0 tham so)
va 'datetime_now()' rieng o cay .tkv (stdlib_bcl.tkv, tra str gio dia
phuong) - CHI CON 1 ham 'now' duy nhat: datetime() (doi ten tu
datetime_utcnow ban dau, vi khong con trung ten voi ham nao nua). Muon
lay str/ticks tu 1 gia tri datetime da co thi dung d.strftime(fmt)/
datetime_ticks(d) (1 THAM SO, KHONG con la ham 0 tham so tu goi UtcNow
rieng)."""
import re
from il_core import IL_SCALAR
from il_dispatch import (
    register_assign_rhs_parser, register_first_pass_walk, register_stmt_codegen,
    register_expr_builtin, register_expr_method,
)

IL_SCALAR['datetime'] = 'int64'
IL_SCALAR['timedelta'] = 'int64'

_PY_TO_NET_FMT = [
    ('%Y', 'yyyy'), ('%y', 'yy'),
    ('%B', 'MMMM'), ('%b', 'MMM'), ('%m', 'MM'),
    ('%A', 'dddd'), ('%a', 'ddd'), ('%d', 'dd'),
    ('%H', 'HH'), ('%I', 'hh'), ('%M', 'mm'), ('%S', 'ss'),
    ('%p', 'tt'), ('%%', '%'),
]


def _py_fmt_to_net(py_fmt):
    """Dich %Y-%m-%d... sang yyyy-MM-dd... (chuoi HANG, luc bien dich).
    Khong xu ly %f (micro-giay, .NET khong co dinh dang tuong duong don
    gian) - out of scope, ghi lai neu can sau."""
    out = []
    i = 0
    while i < len(py_fmt):
        matched = False
        for py_tok, net_tok in _PY_TO_NET_FMT:
            if py_fmt.startswith(py_tok, i):
                out.append(net_tok)
                i += len(py_tok)
                matched = True
                break
        if not matched:
            ch = py_fmt[i]
            # Ky tu chu cai trong .NET custom format can escape ('T' rieng
            # co y nghia...) - bao ton don gian: bao trong nhay don neu la
            # chu cai, giu nguyen neu khong (dau '-', '/', ':', khoang trang).
            out.append(f"'{ch}'" if ch.isalpha() else ch)
            i += 1
    return ''.join(out)


def _str_lit_text(node):
    """Trich noi dung THAT (khong dau nhay) tu 1 node bieu thuc CHUOI
    HANG - dung chung cho ca fmt cua strftime/strptime (xem quy uoc
    tuong tu metaprogramming.py's attr_name extraction)."""
    if isinstance(node, tuple) and node[0] == 'str_lit':
        return str(node[1]).strip('"\'')
    raise SyntaxError(
        "il_codegen: tham so 'fmt' cua strftime()/strptime() bat buoc la "
        "1 CHUOI HANG (dich sang .NET format luc bien dich, khong ho tro bien)")


_INV_CULTURE = ('    call class [mscorlib]System.Globalization.CultureInfo '
                '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()')


def _push_ticks_as_datetime(out):
    """Ticks (int64) dang tren stack -> DateTime valuetype, box+unbox de
    goi duoc instance method (mau box/unbox da chung minh dung o
    _push_datetime_now ben duoi va _push_datetime_strptime)."""
    out.append('    newobj instance void [mscorlib]System.DateTime::.ctor(int64)')
    out.append('    box [mscorlib]System.DateTime')
    out.append('    unbox [mscorlib]System.DateTime')


# ---------- datetime() -> datetime (ticks UTC that, khong phai hash) - ----------
# ---------- HAM DUY NHAT de lay thoi diem hien tai (hop nhat 2026-08-11) --------

def _push_datetime_now(args, scope, out, dtype, ctx):
    out.append('    call valuetype [mscorlib]System.DateTime [mscorlib]System.DateTime::get_UtcNow()')
    out.append('    box [mscorlib]System.DateTime')
    out.append('    unbox [mscorlib]System.DateTime')
    out.append('    call instance int64 [mscorlib]System.DateTime::get_Ticks()')


def _try_rhs_datetime_now(rhs, name, known_shapes):
    if rhs.strip() != 'datetime()':
        return None
    return {'kind': 'assign_datetime_now', 'name': name}


def _fpw_datetime_now(stmt, ctx):
    ctx['declare_named'](stmt['name'], ctx['TypeAnn']('datetime', None))


def _codegen_datetime_now(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    _push_datetime_now([], scope, body, 'datetime', ctx)
    ctx['store_var'](stmt['name'], scope, body)


register_assign_rhs_parser('datetime', _try_rhs_datetime_now)
register_first_pass_walk('assign_datetime_now', _fpw_datetime_now)
register_stmt_codegen('assign_datetime_now', _codegen_datetime_now)
register_expr_builtin('datetime', _push_datetime_now, 'datetime')


# ---------- datetime_ticks(d) -> i64 (trich ticks tu 1 gia tri datetime co san;
# datetime VAT LY DA LA int64 ticks nen chi can widen nhan dtype, khong IL nao khac) --

def _push_datetime_ticks(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: datetime_ticks(d) nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'i64', ctx)


register_expr_builtin('datetime_ticks', _push_datetime_ticks, 'i64')


# ---------- datetime_strptime(s, fmt_literal) -> datetime ----------

def _push_datetime_strptime(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: datetime_strptime(s, fmt) nhan dung 2 tham so")
    net_fmt = _py_fmt_to_net(_str_lit_text(args[1]))
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    ldstr "{net_fmt}"')
    out.append(_INV_CULTURE)
    out.append('    call valuetype [mscorlib]System.DateTime '
                '[mscorlib]System.DateTime::ParseExact(string, string, '
                'class [mscorlib]System.IFormatProvider)')
    out.append('    box [mscorlib]System.DateTime')
    out.append('    unbox [mscorlib]System.DateTime')
    out.append('    call instance int64 [mscorlib]System.DateTime::get_Ticks()')


register_expr_builtin('datetime_strptime', _push_datetime_strptime, 'datetime')


# ---------- d.strftime(fmt_literal) -> str ----------

def _compile_strftime(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 1:
        raise SyntaxError("il_codegen: d.strftime(fmt) nhan dung 1 tham so")
    net_fmt = _py_fmt_to_net(_str_lit_text(args[0]))
    ctx['load_var_ref'](obj_name, scope, out)
    _push_ticks_as_datetime(out)
    out.append(f'    ldstr "{net_fmt}"')
    out.append(_INV_CULTURE)
    out.append('    call instance string [mscorlib]System.DateTime::ToString(string, '
                'class [mscorlib]System.IFormatProvider)')


register_expr_method('datetime', 'strftime', _compile_strftime, 'str')


# ---------- timedelta_days/hours/minutes/seconds(n) -> timedelta ----------

def _make_timedelta_from(unit_method):
    def _push(args, scope, out, dtype, ctx):
        if len(args) != 1:
            raise SyntaxError(f"il_codegen: timedelta_{unit_method.lower()}(n) nhan dung 1 tham so")
        ctx['compile_expr'](args[0], scope, out, 'i32', ctx)
        out.append('    conv.r8')
        out.append(f'    call valuetype [mscorlib]System.TimeSpan '
                    f'[mscorlib]System.TimeSpan::From{unit_method}(float64)')
        out.append('    box [mscorlib]System.TimeSpan')
        out.append('    unbox [mscorlib]System.TimeSpan')
        out.append('    call instance int64 [mscorlib]System.TimeSpan::get_Ticks()')
    return _push


for _unit in ('Days', 'Hours', 'Minutes', 'Seconds'):
    _fn = _make_timedelta_from(_unit)
    register_expr_builtin(f'timedelta_{_unit.lower()}', _fn, 'timedelta')


# ---------- datetime_add/datetime_sub/datetime_diff: vat ly la int64 add/sub ----------

def _push_datetime_add(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: datetime_add(d, td) nhan dung 2 tham so")
    ctx['compile_expr'](args[0], scope, out, 'datetime', ctx)
    ctx['compile_expr'](args[1], scope, out, 'timedelta', ctx)
    out.append('    add')


def _push_datetime_sub(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: datetime_sub(d, td) nhan dung 2 tham so")
    ctx['compile_expr'](args[0], scope, out, 'datetime', ctx)
    ctx['compile_expr'](args[1], scope, out, 'timedelta', ctx)
    out.append('    sub')


def _push_datetime_diff(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: datetime_diff(d1, d2) nhan dung 2 tham so")
    ctx['compile_expr'](args[0], scope, out, 'datetime', ctx)
    ctx['compile_expr'](args[1], scope, out, 'datetime', ctx)
    out.append('    sub')


register_expr_builtin('datetime_add', _push_datetime_add, 'datetime')
register_expr_builtin('datetime_sub', _push_datetime_sub, 'datetime')
register_expr_builtin('datetime_diff', _push_datetime_diff, 'timedelta')
