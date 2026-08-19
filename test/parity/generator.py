# -*- coding: utf-8 -*-
"""Sinh chuong trinh .tkv nho, CO KIEU (moc 8, buoc 1.1 cua ke hoach).

Nguon su that kep:
  - Builtin/method THU VIEN: doc THANG tu registry `il_dispatch` (khong
    chep tay) - dang ky moi mot method la sinh ra ngay, khong can sua
    generator. `grammar_coverage_test.py` khoa dieu nay.
  - Van pham CO BAN (bien/gan/if/for/while/container/subscript/slice):
    KHONG nam trong registry (do la ngu phap loi, khong phai builtin), nen
    viet tay o day - cac hinh dang duoc CO Y lam DA DANG (bien vs bieu
    thuc lam iterable, mot vs nhieu doi so trong subscript, tap vs dict
    cho 'not in', chi so am hang so vs dong...) dung ngay o cho cac loi
    B1-B6 (xem BUGS_TODO.md) song - fuzz.py roi tim ra chung bang CACH
    CHAY, khong phai vi generator biet truoc chung.

Chuong trinh sinh ra la THUAN va DUNG: khong I/O, khong dong ho, khong
mang, moi vong lap co chan tren ro rang.
"""
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
if str(ROOT / 'compiler') not in sys.path:
    sys.path.insert(0, str(ROOT / 'compiler'))

import il_codegen  # noqa: E402  (import de KICH HOAT dang ky toan bo il_features)
import il_dispatch as D  # noqa: E402

# ---------------------------------------------------------------------------
# Phan 1: tu REGISTRY - builtin/method THU VIEN thuan + tat dinh. Loai I/O
# that (http/db/os/zip) va loai khong tat dinh (dong ho that).
# ---------------------------------------------------------------------------
_UNSAFE_BUILTINS = {
    'http_get', 'http_get_h', 'http_post', 'http_post_h', 'http_post_type',
    'http_put', 'http_put_h', 'http_delete', 'http_delete_h', 'http_request',
    'db_open', 'db_close', 'db_exec', 'db_query_int', 'db_query_text',
    'os_getenv', 'os_list_files', 'os_mkdir', 'zip_create', 'zip_extract',
    'datetime_now_utc', 'datetime_ticks', 'json_get_str',
}
# name -> so doi so ky vong, chi cac ham 1 doi so vo huong duoc dua vao
# van pham nay (sum/min/max/sorted can container, xu ly rieng o tmpl_agg).
SAFE_BUILTIN_ARITY1 = {'int': 'str', 'float': 'str', 'base64_encode': 'str',
                        'md5_hex': 'str', 'sha256_hex': 'str'}
# base64_decode CO Y bo qua: doi so ngau nhien hau nhu chac chan KHONG
# phai base64 hop le, nen ca hai phia deu chi "nem loi tren rac" - tin
# hieu do khong noi len dieu gi ve TokenVector.
for _n in SAFE_BUILTIN_ARITY1:
    assert _n in D.EXPR_BUILTIN_CODEGEN, _n
AGG_BUILTINS = {'sum', 'min', 'max', 'sorted', 'all', 'any'}
assert AGG_BUILTINS <= set(D.EXPR_BUILTIN_CODEGEN)
CONTAINER_ARG_BUILTINS = {'json_dumps'}
assert CONTAINER_ARG_BUILTINS <= set(D.EXPR_BUILTIN_CODEGEN)

# Builtin THUAN nhung KHONG sinh, kem LY DO ro rang - doi xung voi
# UNGENERATABLE cua ke hoach (1.1): 'de ngo co ghi ly do' thay vi lot
# qua trong im lang. grammar_coverage_test.py doc dict nay.
UNGENERATABLE = {
    'eval_arith': ("can 1 chuoi la BIEU THUC SO HOP LE ('1 + 2 * 3') - "
                    "chuoi ngau nhien cua generator hien tai hau nhu chac "
                    "chan khong parse duoc, ca hai phia se chi nem loi "
                    "tren rac. Can 1 generator bieu thuc rieng."),
}

# method THU VIEN thuan (shape_key, ten) -> registry hien co toan la thuan.
REGISTRY_STR_METHODS = sorted(
    name for (shape, name) in D.EXPR_METHOD_CODEGEN if shape == 'str')

# Van pham THAM VONG (2026-08-05): phuong thuc chuoi PHO BIEN trong
# Python nhung KHONG chac da dang ky - B6 ('.rfind' thieu) la vi du that
# cua chinh lop nay. Lay tu von hieu biet chung ve Python, KHONG tu
# registry - registry chi biet cai NO CO, khong biet cai NGUOI DUNG can.
# Gop CA hai nguon (da dang ky + tham vong) vao MOT pool goi duoc - cai
# da dang ky thi CHAC chay, cai tham vong thi CHUA CHAC (do la diem).
EXPLORATORY_STR_METHODS = {
    'rfind': (['str'], 'i32'), 'find': (['str'], 'i32'),
    'strip': ([], 'str'), 'upper': ([], 'str'), 'lower': ([], 'str'),
    'lstrip': ([], 'str'), 'rstrip': ([], 'str'),
    'startswith': (['str'], 'i32'), 'endswith': (['str'], 'i32'),
    'capitalize': ([], 'str'), 'isdigit': ([], 'i32'),
    'replace': (['str', 'str'], 'str'),
    # Da dang ky trong il_dispatch - THEM VAO DAY thay vi bo qua, khong
    # thi grammar_coverage_test do dung (chinh no chi ra thieu sot nay).
    'count': (['str'], 'i32'), 'title': ([], 'str'), 'zfill': (['int'], 'str'),
}
# 'join'/'split' DA duoc cham toi qua duong khac (join: dong cuoi moi
# chuong trinh sinh ra; split: tmpl_for_in_expr) - khong hop voi khuon
# "goi -> quan sat scalar" o day vi tra ve list, khong phai gia tri don.
COVERED_ELSEWHERE = {'join', 'split'}

NUMERIC_DTYPES = ('int', 'f64')
MAX_DEPTH = 2
MAX_STMTS = 9


class Env(object):
    def __init__(self, rng):
        self.rng = rng
        self.vars = {}          # ten -> spec: ('scalar', dtype) |
                                 #             ('list', dtype) |
                                 #             ('dict', kdtype, vdtype) |
                                 #             ('set', dtype)
        self._n = 0
        self.helpers = []       # nguon cac ham phu (cho B4: goi method
                                 # THANG tren ket qua goi ham)
        self.used_tags = set()  # ghi lai template nao da chay, cho ledger

    def fresh(self, prefix):
        self._n += 1
        return '%s%d' % (prefix, self._n)

    def of_kind(self, kind, dtype=None):
        out = []
        for name, spec in self.vars.items():
            if spec[0] != kind:
                continue
            if dtype is not None and spec[1] != dtype:
                continue
            out.append(name)
        return out

    def declare(self, name, spec):
        self.vars[name] = spec


def _lit(dtype, rng):
    if dtype == 'int':
        return str(rng.randint(-50, 50))
    if dtype == 'f64':
        return '%.3f' % rng.uniform(-50.0, 50.0)
    if dtype == 'str':
        alphabet = 'abcDEF _|,.-'
        n = rng.randint(0, 6)
        return '"%s"' % ''.join(rng.choice(alphabet) for _ in range(n))
    raise ValueError(dtype)


def _emit_observe(expr):
    # Moi bieu thuc quan sat deu boc try/except + str() rieng - MOT phep
    # toan tu hong khong keo sap toan bo chuong trinh, va _out ghi lai
    # "co nem hay khong" ngang hang voi gia tri, so sanh duoc trong 1 lan
    # chay (xem docstring dau file).
    return [
        'try:',
        '    _out.append(str(%s))' % expr,
        'except:',
        '    _out.append("ERR")',
    ]


# ---------------------------------------------------------------------------
# Cac template cau lenh. Moi ham: (env, rng) -> list[str] dong nguon (chua
# tha indent tuong doi) hoac None neu khong ap dung duoc luc nay.
# ---------------------------------------------------------------------------

def tmpl_decl_scalar(env, rng):
    # KHONG dung 'name: "dtype" = value' - do KHONG phai cu phap TokenVector
    # that (grep toan bo repo khong thay ai dung dang nay cho bien CUC BO,
    # chi tham so ham/return type moi co annotation). Dtype suy tu HANG SO:
    # so nguyen -> 'int' (mac dinh toan cuc tu moc 6), so thuc -> 'f64',
    # chuoi -> 'str' - dung DUNG luat _infer_literal_dtype cua compiler.
    dtype = rng.choice(NUMERIC_DTYPES + ('str',))
    name = env.fresh('v')
    env.declare(name, ('scalar', dtype))
    return ['%s = %s' % (name, _lit(dtype, rng))]


def tmpl_arith_binop(env, rng):
    dtype = rng.choice(NUMERIC_DTYPES)
    xs = env.of_kind('scalar', dtype)
    if len(xs) < 2:
        return None
    a, b = rng.sample(xs, 2)
    op = rng.choice(['+', '-', '*', '//', '%', '**']
                     if dtype == 'int' else ['+', '-', '*'])
    if dtype == 'int' and op in ('//', '%') and rng.random() < 0.3:
        b = _lit('int', rng)  # tranh chia 0 qua thuong xuyen tu bien
        if b == '0':
            b = '3'
    # '/' giua hai i32 nay BAO LOI RO RANG (moc 6) - DUNG probe co y do
    # chinh no, khong lan trong binop ngau nhien nua (xem tmpl_int_div).
    return _emit_observe('%s %s %s' % (a, op, b))


def tmpl_int_div(env, rng):
    """'/' giua hai 'int': Python tra float, TokenVector (sau moc 6) bao
    loi thay vi chia nguyen am tham - xac nhan lai hanh vi da ghi."""
    xs = env.of_kind('scalar', 'int')
    if len(xs) < 2:
        return None
    a, b = rng.sample(xs, 2)
    return _emit_observe('%s / %s' % (a, b))


def tmpl_compare_bool(env, rng):
    dtype = rng.choice(NUMERIC_DTYPES)
    xs = env.of_kind('scalar', dtype)
    if len(xs) < 2:
        return None
    a, b = rng.sample(xs, 2)
    cmp_op = rng.choice(['<', '<=', '>', '>=', '==', '!='])
    expr = '%s %s %s' % (a, cmp_op, b)
    if rng.random() < 0.5:
        c, d = rng.sample(xs, 2) if len(xs) >= 2 else (a, b)
        bop = rng.choice(['and', 'or'])
        expr = '(%s) %s (%s %s %s)' % (expr, bop, c, cmp_op, d)
    return _emit_observe(expr)


def tmpl_list_new(env, rng):
    dtype = rng.choice(('int', 'str'))
    name = env.fresh('lst')
    env.declare(name, ('list', dtype))
    lines = ['%s = []' % name]
    for _ in range(rng.randint(2, 5)):
        lines.append('%s.append(%s)' % (name, _lit(dtype, rng)))
    return lines


def tmpl_list_index(env, rng):
    """Chi so hang so (kha nang cao la an toan) VA chi so AM DONG qua
    bien ('lst[-i]') - theo dung docstring cua sample_negative_index.tkv,
    ho tro CHI hang so; bien am la mot trong cac hinh dang can do."""
    lists = env.of_kind('list')
    if not lists:
        return None
    name = rng.choice(lists)
    mode = rng.choice(['const_pos', 'const_neg', 'dynamic_neg', 'slice'])
    if mode == 'const_pos':
        idx = str(rng.randint(0, 2))
        return _emit_observe('%s[%s]' % (name, idx))
    if mode == 'const_neg':
        idx = str(-rng.randint(1, 2))
        return _emit_observe('%s[%s]' % (name, idx))
    if mode == 'dynamic_neg':
        ints = env.of_kind('scalar', 'int')
        if not ints:
            return None
        i = rng.choice(ints)
        return _emit_observe('%s[-%s]' % (name, i))
    # slice - CO THE vuot bien do dai that (Python luon kep, khong nem)
    a = rng.randint(-3, 6)
    b = rng.randint(-3, 6)
    return _emit_observe('%s[%d:%d]' % (name, a, b))


def tmpl_dict_new(env, rng):
    kdtype = rng.choice(('int', 'str'))
    name = env.fresh('d')
    env.declare(name, ('dict', kdtype, 'int'))
    lines = ['%s = {}' % name]
    for _ in range(rng.randint(2, 4)):
        lines.append('%s[%s] = %s' % (name, _lit(kdtype, rng), _lit('int', rng)))
    return lines


def tmpl_dict_call_key(env, rng):
    """'d[f(a, b)] = v' - khoa la KET QUA GOI HAM NHIEU DOI SO ngay trong
    subscript. B3: bo tach chi so cua compiler cat nham tai dau phay BEN
    TRONG loi goi ham."""
    dicts = env.of_kind('dict')
    ints = env.of_kind('scalar', 'int')
    if not dicts or len(ints) < 2:
        return None
    d = rng.choice(dicts)
    a, b = rng.sample(ints, 2)
    return ['%s[max(%s, %s)] = %s' % (d, a, b, _lit('int', rng))]


def tmpl_dict_order_probe(env, rng):
    """Xoa roi chen lai - Python (>=3.7) dua khoa vua chen lai xuong CUOI
    thu tu duyet; .NET Dictionary khong bao dam gi. Doi chieu bang cach
    noi TOAN BO khoa (dang str) lai voi nhau."""
    dicts = env.of_kind('dict')
    if not dicts:
        return None
    d = rng.choice(dicts)
    kdtype = env.vars[d][1]
    extra = _lit(kdtype, rng)
    lines = ['%s[%s] = %s' % (d, extra, _lit('int', rng))]
    keys_var = env.fresh('ks')
    lines.append('%s = []' % keys_var)
    lines.append('for _k in %s:' % d)
    lines.append('    %s.append(str(_k))' % keys_var)
    lines += _emit_observe('"-".join(%s)' % keys_var)
    return lines


def tmpl_for_in_dict_bare(env, rng):
    """'for k in d:' TRUC TIEP tren dict (khong '.items()') - B1: bien
    dich duoc nhung CHET LUC CHAY theo BUGS_TODO.md."""
    dicts = env.of_kind('dict')
    if not dicts:
        return None
    d = rng.choice(dicts)
    acc = env.fresh('acc')
    env.declare(acc, ('scalar', 'int'))
    lines = ['%s = 0' % acc]
    lines.append('for _k in %s:' % d)
    lines.append('    %s = %s + 1' % (acc, acc))
    lines += _emit_observe(acc)
    return lines


def tmpl_for_in_list(env, rng):
    lists = env.of_kind('list')
    if not lists:
        return None
    name = rng.choice(lists)
    dtype = env.vars[name][1]
    acc = env.fresh('acc')
    x = env.fresh('x')
    lines = []
    if dtype == 'int':
        env.declare(acc, ('scalar', 'int'))
        lines.append('%s = 0' % acc)
        lines.append('for %s in %s:' % (x, name))
        lines.append('    %s = %s + %s' % (acc, acc, x))
        lines += _emit_observe(acc)
    else:
        env.declare(acc, ('scalar', 'str'))
        lines.append('%s = ""' % acc)
        lines.append('for %s in %s:' % (x, name))
        lines.append('    %s = %s + %s' % (acc, acc, x))
        lines += _emit_observe(acc)
    return lines


def tmpl_for_in_expr(env, rng):
    """'for x in <bieu thuc>.split(sep):' - iterable la KET QUA GOI HAM,
    khong phai bien thuan. B5: chi nhan bien trong menh de 'in' cua for."""
    strs = env.of_kind('scalar', 'str')
    if not strs:
        return None
    s = rng.choice(strs)
    acc = env.fresh('acc')
    x = env.fresh('x')
    env.declare(acc, ('scalar', 'int'))
    lines = ['%s = 0' % acc]
    lines.append('for %s in %s.split(","):' % (x, s))
    lines.append('    %s = %s + 1' % (acc, acc))
    lines += _emit_observe(acc)
    return lines


def tmpl_set_new_membership(env, rng):
    """'x not in s' voi s la SET - B2: SyntaxError chi voi set, dict thi
    chay binh thuong."""
    ints = env.of_kind('scalar', 'int')
    if len(ints) < 2:
        return None
    name = env.fresh('s')
    env.declare(name, ('set', 'int'))
    lines = ['%s = set()' % name]
    for v in rng.sample(ints, min(2, len(ints))):
        lines.append('%s.add(%s)' % (name, v))
    probe = rng.choice(ints)
    op = rng.choice(['in', 'not in'])
    return lines + _emit_observe('(%s %s %s)' % (probe, op, name))


def tmpl_method_on_var(env, rng):
    strs = env.of_kind('scalar', 'str')
    if not strs:
        return None
    s = rng.choice(strs)
    name = rng.choice(list(EXPLORATORY_STR_METHODS.keys()))
    arg_types, _ret = EXPLORATORY_STR_METHODS[name]
    args = ', '.join(_lit(t, rng) for t in arg_types)
    return _emit_observe('%s.%s(%s)' % (s, name, args))


def tmpl_method_on_call(env, rng):
    """'f().method(...)' - goi method NGAY TREN KET QUA goi ham, khong
    qua bien trung gian. B4: method tren BIEU THUC (khong phai bien)."""
    if not env.helpers:
        hname = env.fresh('mk')
        strs = env.of_kind('scalar', 'str')
        body_expr = strs[0] if strs and env.rng.random() < 0.5 else '"abc"'
        env.helpers.append(
            'def %s() -> "str":\n    return %s\n' % (hname, body_expr))
        env._helper_name = hname
    hname = env._helper_name
    method = rng.choice(['upper', 'strip', 'find'])
    arg = '"a"' if method == 'find' else ''
    return _emit_observe('%s().%s(%s)' % (hname, method, arg))


def tmpl_builtin_arity1(env, rng):
    # Ca 5 ham trong SAFE_BUILTIN_ARITY1 (int/float/base64_encode/md5_hex/
    # sha256_hex) deu nhan DUY NHAT 1 doi so 'str' - khong can nhanh rieng.
    strs = env.of_kind('scalar', 'str')
    if not strs:
        return None
    name = rng.choice(list(SAFE_BUILTIN_ARITY1.keys()))
    arg = rng.choice(strs)
    return _emit_observe('%s(%s)' % (name, arg))


def tmpl_agg(env, rng):
    lists = env.of_kind('list', 'int')
    if not lists:
        return None
    name = rng.choice(lists)
    fn = rng.choice(['sum', 'min', 'max', 'sorted', 'any', 'all'])
    expr = '%s(%s)' % (fn, name)
    if fn == 'sorted':
        expr = 'str(%s(%s))' % (fn, name)
    return _emit_observe(expr)


def tmpl_json_dumps(env, rng):
    lists = env.of_kind('list', 'int')
    dicts = env.of_kind('dict')
    pool = lists + dicts
    if not pool:
        return None
    name = rng.choice(pool)
    return _emit_observe('json_dumps(%s)' % name)


def tmpl_round(env, rng):
    """round(x)/round(x, n) - Python lam tron VE SO CHAN (banker's)."""
    floats = env.of_kind('scalar', 'f64')
    if not floats:
        return None
    x = rng.choice(floats)
    if rng.random() < 0.5:
        return _emit_observe('round(%s)' % x)
    return _emit_observe('round(%s, %d)' % (x, rng.randint(0, 2)))


def tmpl_if(env, rng, depth):
    ints = env.of_kind('scalar', 'int')
    if not ints or depth >= MAX_DEPTH:
        return None
    a = rng.choice(ints)
    # Bien khai bao BEN TRONG than if KHONG CHAC da duoc gan (nhanh co
    # the khong bao gio chay) - Python nem UnboundLocalError neu dong
    # sau do dung no VO DIEU KIEN. Chup lai env.vars TRUOC, phuc hoi SAU
    # khi sinh than xong - cung mot lop loi voi tmpl_while's declare-
    # before-return da sua o tren, chi khac la o day CA CHUOI bien long
    # ben trong can loai, khong phai 1 ten don le.
    snapshot = dict(env.vars)
    body = _gen_block(env, rng, depth + 1, rng.randint(1, 2))
    env.vars = snapshot
    if not body:
        return None
    lines = ['if %s %s 0:' % (a, rng.choice(['>', '<', '==']))]
    lines += ['    ' + ln for ln in body]
    return lines


def tmpl_while(env, rng, depth):
    if depth >= MAX_DEPTH:
        return None
    name = env.fresh('i')
    n = rng.randint(1, 4)
    # QUAN TRONG: chi env.declare() SAU KHI biet chac se tra ve non-None.
    # _gen_block goi env.declare() ngay khi mot template thanh cong; neu
    # tmpl_while roi tra None o duoi (body rong), bien da khai bao van
    # con SOT trong env - template SAU do (vd tmpl_if) se thay bien ton
    # tai va dung no trong dieu kien, dung ten khong he co dong khai bao
    # nao trong nguon sinh ra ('if i1 < 0:' voi i1 khong ton tai). Loi
    # nay tu tim ra khi chay generator tren ~60 seed, khong phai loi
    # TokenVector - ghi lai vi de tai pham voi template moi.
    body = _gen_block(env, rng, depth + 1, rng.randint(1, 2))
    if not body:
        return None
    env.declare(name, ('scalar', 'int'))
    lines = ['%s = 0' % name,
             'while %s < %d:' % (name, n)]
    lines += ['    ' + ln for ln in body]
    lines.append('    %s = %s + 1' % (name, name))
    return lines


_FLAT_TEMPLATES = [
    tmpl_decl_scalar, tmpl_decl_scalar, tmpl_arith_binop, tmpl_int_div,
    tmpl_compare_bool, tmpl_list_new, tmpl_list_index, tmpl_dict_new,
    tmpl_dict_call_key, tmpl_dict_order_probe, tmpl_for_in_dict_bare,
    tmpl_for_in_list, tmpl_for_in_expr, tmpl_set_new_membership,
    tmpl_method_on_var, tmpl_method_on_call, tmpl_builtin_arity1,
    tmpl_agg, tmpl_round, tmpl_json_dumps,
]


def _gen_block(env, rng, depth, n_stmts):
    lines = []
    tries = 0
    while len(lines) < n_stmts and tries < n_stmts * 4:
        tries += 1
        templates = list(_FLAT_TEMPLATES)
        if depth < MAX_DEPTH:
            templates += [lambda e, r, d=depth: tmpl_if(e, r, d),
                          lambda e, r, d=depth: tmpl_while(e, r, d)]
        tmpl = rng.choice(templates)
        out = tmpl(env, rng)
        if out:
            env.used_tags.add(tmpl.__name__ if hasattr(tmpl, '__name__')
                               else 'nested')
            lines.extend(out)
    return lines


def generate_program(seed, n_stmts=None):
    """Sinh 1 chuong trinh .tkv: entry `run() -> "str"` KHONG THAM SO
    (tranh han che CLI - chi ho tro tham so vo huong str; o day gia tri
    duoc nhung THANG vao than ham nen khong can CLI parse gi ca).
    Tra ve (nguon, meta)."""
    rng = random.Random(seed)
    env = Env(rng)
    n_stmts = n_stmts or rng.randint(5, MAX_STMTS)
    body = _gen_block(env, rng, 0, n_stmts)
    if not body or '_out.append' not in '\n'.join(body):
        # BAT BUOC it nhat 1 quan sat - '_out = []' KHONG bao gio duoc
        # .append() thi dtype phan tu cua no suy ra mac dinh (i32), va
        # '"|".join(_out)' o cuoi doi list[str] -> loi bien dich GIA
        # (loi cua kich ban sinh, khong phai loi TokenVector that).
        body = body + _emit_observe('"end"')
    lines = ['def run() -> "str":', '    _out = []']
    lines += ['    ' + ln for ln in body]
    lines.append('    return "|".join(_out)')
    source = '\n\n'.join(env.helpers) + ('\n\n' if env.helpers else '')
    source += '\n'.join(lines) + '\n'
    meta = {'seed': seed, 'templates': sorted(env.used_tags)}
    return source, meta


if __name__ == '__main__':
    src, meta = generate_program(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
    print(src)
    print('# meta:', meta, file=sys.stderr)
