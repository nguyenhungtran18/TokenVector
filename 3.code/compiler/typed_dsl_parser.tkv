# -*- coding: utf-8 -*-
"""Lexer + recursive-descent parser cho chu ky ham co kieu/shape, ke thua
dung phong cach cua recursive_ternary_parser.py (khong dung regex-per-line
nhu symbol_transpiler.py, vi ngoac vuong long + danh sach so la dung lop
bai toan ma regex da chung minh yeu).

Ngu phap (Phase 1 cua plan):
    typed_sig  := IDENT '(' param_list ')' ('->' type_ann)? ('=>' | ':')
    param_list := (param (',' param)*)?
    param      := IDENT ':' type_ann
    type_ann   := DTYPE ('[' dim_list ']')?
    dim_list   := NUMBER (',' NUMBER)*
    DTYPE      := 'f32' | 'f64' | 'i32' | 'i64'

Sau '=>' la 1 bieu thuc don (body_mode='expr', phan con lai cua dong).
Sau ':' la block-body nhieu dong (body_mode='block'), do CALLER (
typed_dsl_transpile.py) thu thap cac dong thut le tiep theo - parser nay
chi chiu trach nhiem cho DONG CHU KY, khong doc than ham nhieu dong.
"""
import re

# 'int' (2026-08-05, moc 6 buoc 2) = so nguyen VO HAN CHU SO nhu Python,
# bieu dien bang struct TkvInt (xem il_features/int_type.py). 'i32'/'i64'
# giu nguyen y nghia cu (do rong co dinh, tran thi nem OverflowException)
# - ma .tkv cu khong doi hanh vi.
DTYPES = {'f32', 'f64', 'i32', 'i64', 'str', 'int', 'datetime', 'timedelta', 'complex'}
# 'inferred' (Task 2/5, duck-typing-inference, 2026-08-17): dtype dac biet
# gan boi tkv_compile.py's _params_with_defaults(allow_inferred=True) cho
# tham so ham top-level THIEU annotation - chi di qua NGUYEN VEN o tang
# parse nay (khong resolve/validate gi them), Task 3/4 se thay the bang
# kieu cu the tai call-site (xem il_codegen.py::_expr_call).
DTYPES.add('inferred')

TOKEN_RE = re.compile(r'''
    \s*(?:
        (?P<FATARROW>=>)
      | (?P<ARROW>->)
      | (?P<STRING>"[^"]*")
      | (?P<NUMBER>\d+(?:\.\d+)?)
      | (?P<IDENT>[A-Za-z_]\w*)
      | (?P<OP>\*\*|[():,\[\]=*-])
    )
''', re.VERBOSE)


def tokenize(src: str):
    """Tra ve list (kind, value, end_pos). end_pos dung de cat phan body_expr
    con lai sau '=>' (khong bi tokenize, giu nguyen text goc)."""
    tokens = []
    pos = 0
    while pos < len(src):
        m = TOKEN_RE.match(src, pos)
        if not m or m.end() == pos:
            break  # gap ky tu la (vd bat dau body_expr sau '=>') - dung lai
        pos = m.end()
        kind = m.lastgroup
        if kind:
            tokens.append((kind, m.group(kind), pos))
    tokens.append(('EOF', None, pos))
    return tokens


class TypeAnn:
    def __init__(self, dtype: str, shape, key_dtype=None, tuple_dtypes=None, elem_ta=None,
                 func_params=None):
        self.dtype = dtype          # 'f32' | 'f64' | 'i32' | 'i64' | 'str' (VALUE dtype khi shape='dict')
        self.shape = shape          # list[int] | None (scalar) | 'list' | 'dict' | 'tuple'
        self.key_dtype = key_dtype  # CHI dung khi shape == 'dict' (dtype cua khoa)
        self.tuple_dtypes = tuple_dtypes  # CHI dung khi shape == 'tuple' - list[str] DUNG 2 phan tu
        # Wave 2 (2026-07-29) - container long nhau: khi shape=='list'/'dict'
        # VA phan tu/gia tri KHONG PHAI vo huong/record ma la 1 container
        # KHAC (List<List<T>>, Dictionary<K, List<T>>), elem_ta giu TypeAnn
        # DAY DU (de quy) cua phan tu/gia tri do - `dtype` luc nay CHI la 1
        # sentinel khong dung truc tiep (xem il_type_str trong il_codegen.py).
        # None (mac dinh) = truong hop cu, khong doi hanh vi cac tinh nang
        # da co (backward-compatible).
        self.elem_ta = elem_ta
        # func_params: CHI dung khi shape == 'func' (Wave 3, 2026-07-29,
        # "function reference" HEP - khong phai closure that, xem
        # project-tokenvector-wave2-status memory). list[str] cac dtype
        # THAM SO (scalar-only), `dtype` cua chinh TypeAnn nay la dtype
        # TRA VE. CHI dung duoc lam KIEU THAM SO cua 1 ham khac (truyen 1
        # ten ham top-level TRUC TIEP tai diem goi) - KHONG ho tro gan lai
        # vao 1 bien local thuong (khong co FIRST_PASS_WALK cho truong hop
        # do, gioi han co y thuc de tranh dung vao van de "bien tu do sau
        # khi ham ngoai return" cua closure that).
        self.func_params = func_params

    def __repr__(self):
        return (f'TypeAnn({self.dtype}, shape={self.shape}, key_dtype={self.key_dtype}, '
                f'tuple_dtypes={self.tuple_dtypes}, elem_ta={self.elem_ta}, '
                f'func_params={self.func_params})')


class Param:
    def __init__(self, name: str, type_ann: TypeAnn, default_node=None, is_vararg=False,
                 is_kwarg=False):
        self.name = name
        self.type_ann = type_ann
        # default_node: node bieu thuc ('num'/'str_lit'/'neg', ...) hoac
        # None (khong co gia tri mac dinh). CHI ho tro literal so/chuoi
        # (Wave 2, 2026-07-29) - khong ho tro bieu thuc tham chieu bien
        # khac (Python cho phep nhung mac dinh chi tinh 1 lan luc dinh
        # nghia ham, DSL nay chua co khai niem do - gioi han co y thuc).
        self.default_node = default_node
        # is_vararg/is_kwarg (Phase 5.1, 2026-08-11): '*name: T'/'**name: T'
        # - THAM SO CUOI CUNG cua ham top-level, dong nhat kieu (tat ca gia
        # tri du them cung 1 dtype T). type_ann o day KHONG con la scalar T
        # nua ma da la 'list' (vararg) / 'dict' key='str' (kwarg) - xem
        # parse_param. Gioi han co y thuc: khong ho tro tren decorator/method
        # (chi ham top-level, xem tkv_compile.py's _extract_signature_line).
        self.is_vararg = is_vararg
        self.is_kwarg = is_kwarg

    def __repr__(self):
        return f'Param({self.name}: {self.type_ann} = {self.default_node})'


class Signature:
    def __init__(self, name, params, return_type, body_mode, body_expr=None, is_static=False,
                 is_async=False):
        self.name = name
        self.params = params                # list[Param]
        self.return_type = return_type      # TypeAnn hoac None
        self.body_mode = body_mode          # 'expr' | 'block'
        self.body_expr = body_expr          # str hoac None (chi co khi 'expr')
        # is_static: True cho method record co '@staticmethod' (Wave 1,
        # 2026-07-29) - KHONG bind 'self', gen_il_method goi gen_il_function
        # voi self_type_ann=None (giong ham top-level), xem tkv_compile.py's
        # _extract_record_method_sig_line/compile_method_call.
        self.is_static = is_static
        # is_async: True cho 'async def' (Phase 4, 2026-08-11 - port tu cay
        # .tkv tu-host, thiet ke da co san va CHAY DUOC that: KHONG phai
        # state-machine/continuation that, ham 'async def' van chay DONG BO
        # den het roi ket qua duoc boc vao 1 Task<T> DA HOAN TAT qua
        # Task.FromResult<T>(...) truoc 'ret' (xem il_features/control_flow.py's
        # codegen_return) - 'await' o phia goi chi don gian goi .get_Result()
        # dong bo (xem il_features/async_await.py). Giu dung cu phap Python
        # that (async def/await) nhung KHONG co overlap/concurrency THAT -
        # du cho code CPU-bound, ngoai pham vi lam concurrency that.
        self.is_async = is_async

    def __repr__(self):
        return (f'Signature({self.name}, params={self.params}, '
                f'return_type={self.return_type}, body_mode={self.body_mode!r})')


class Parser:
    def __init__(self, tokens, src, record_names=frozenset(), extern_class_names=frozenset()):
        self.tokens = tokens
        self.src = src
        self.i = 0
        self.record_names = record_names  # ten cac 'class dang record' da khai bao trong file
        # extern_class_names (Task 2, extern-class, 2026-08-18): ten cac
        # handle-type khai bao qua __tkv_extern_class__ trong CUNG file -
        # chap nhan y het record_names (dtype vo huong, shape rieng), xem
        # nhanh cuoi parse_type_ann.
        self.extern_class_names = extern_class_names

    def peek(self):
        return self.tokens[self.i]

    def advance(self):
        tok = self.tokens[self.i]
        self.i += 1
        return tok

    def expect(self, kind, value=None):
        k, v, pos = self.advance()
        if k != kind or (value is not None and v != value):
            raise SyntaxError(f"Ky vong {kind} {value!r}, gap {k} {v!r} (vi tri ~{pos})")
        return v

    def parse_type_ann(self) -> TypeAnn:
        """type_ann := DTYPE ('[' dim_list ']')? | '(' DTYPE (',' DTYPE)+ ')'
        Dang tuple ho tro 2-7 phan tu (ValueTuple`2..`7, xem il_codegen.py)
        va CHI dung cho RETURN TYPE trong thuc te (tham so kieu tuple duoc
        chap nhan cu phap nhung chua co codegen doc/dung)."""
        kind0, value0, _ = self.peek()
        if kind0 == 'OP' and value0 == '(':
            self.advance()
            dtypes = []
            while True:
                k, v, p = self.advance()
                if k != 'IDENT' or v not in DTYPES:
                    raise SyntaxError(f"Ky vong dtype trong tuple type, gap {v!r} (vi tri ~{p})")
                dtypes.append(v)
                k2, v2, _ = self.peek()
                if k2 == 'OP' and v2 == ',':
                    self.advance()
                    continue
                break
            self.expect('OP', ')')
            if not (2 <= len(dtypes) <= 7):
                raise SyntaxError(
                    f"il_codegen: tuple type ho tro 2-7 phan tu (ValueTuple`2..`7 co san "
                    f"trong mscorlib, `8 can TRest long nhau - ngoai pham vi), gap {len(dtypes)}")
            return TypeAnn(dtypes[0], 'tuple', tuple_dtypes=dtypes)
        kind, value, pos = self.advance()
        if kind == 'IDENT' and value == 'list':
            self.expect('OP', '[')
            elem_ta = self.parse_type_ann()
            self.expect('OP', ']')
            if elem_ta.shape is None and elem_ta.elem_ta is None:
                return TypeAnn(elem_ta.dtype, 'list')
            else:
                return TypeAnn(elem_ta.dtype, 'list', elem_ta=elem_ta)
        if kind == 'IDENT' and value == 'set':
            # 'set[dtype]' (2026-08-03) - shape 'set' DA co day du trong
            # codegen (il_set_type, len(), 'x in s', s.add/remove, phep
            # union/intersection...) nhung CU PHAP CHU THICH thi thieu, nen
            # khong the khai bao 1 THAM SO/GIA TRI TRA VE kieu set - set chi
            # song duoc ben trong 1 ham. Phan tu CHI vo huong (set long nhau
            # khong co y nghia trong .NET: HashSet<T> can T so sanh duoc).
            self.expect('OP', '[')
            e_kind, e_val, e_pos = self.advance()
            if e_kind != 'IDENT' or e_val not in DTYPES:
                raise SyntaxError(
                    f"il_codegen: ky vong dtype trong 'set[...]', gap {e_val!r} (vi tri ~{e_pos})")
            self.expect('OP', ']')
            return TypeAnn(e_val, 'set')
        if kind == 'IDENT' and value == 'dict':
            self.expect('OP', '[')
            k_kind, k_val, k_pos = self.advance()
            if k_kind != 'IDENT' or k_val not in DTYPES:
                raise SyntaxError(f"il_codegen: ky vong key_dtype trong 'dict[...]', gap {k_val!r} (vi tri ~{k_pos})")
            self.expect('OP', ',')
            val_ta = self.parse_type_ann()
            self.expect('OP', ']')
            if val_ta.shape is None and val_ta.elem_ta is None:
                return TypeAnn(val_ta.dtype, 'dict', key_dtype=k_val)
            else:
                return TypeAnn(val_ta.dtype, 'dict', key_dtype=k_val, elem_ta=val_ta)
        if kind == 'IDENT' and value == 'defaultdict':
            # 'defaultdict[K,V]' (Phase 3.2, 2026-08-11): giong 'dict[K,V]'
            # nhung V CHI ho tro vo huong (khong long nhau list/dict khac) -
            # xem il_features/defaultdict_type.py cho hanh vi doc/ghi.
            self.expect('OP', '[')
            k_kind, k_val, k_pos = self.advance()
            if k_kind != 'IDENT' or k_val not in DTYPES:
                raise SyntaxError(
                    f"il_codegen: ky vong key_dtype trong 'defaultdict[...]', gap {k_val!r} "
                    f"(vi tri ~{k_pos})")
            self.expect('OP', ',')
            v_kind, v_val, v_pos = self.advance()
            if v_kind != 'IDENT' or v_val not in DTYPES:
                raise SyntaxError(
                    f"il_codegen: ky vong dtype gia tri vo huong trong 'defaultdict[...]' "
                    f"(khong ho tro long nhau list/dict), gap {v_val!r} (vi tri ~{v_pos})")
            self.expect('OP', ']')
            return TypeAnn(v_val, 'defaultdict', key_dtype=k_val)
        if kind == 'IDENT' and value == 'Counter':
            # 'Counter[K]' (Phase 3.2, 2026-08-11): dtype GIA TRI luon CO
            # DINH 'i32' (dem tan suat) - khong cho khai bao dtype khac,
            # khac 'dict[K,V]'/'defaultdict[K,V]' co V tuy chon.
            self.expect('OP', '[')
            k_kind, k_val, k_pos = self.advance()
            if k_kind != 'IDENT' or k_val not in DTYPES:
                raise SyntaxError(
                    f"il_codegen: ky vong key_dtype trong 'Counter[...]', gap {k_val!r} "
                    f"(vi tri ~{k_pos})")
            self.expect('OP', ']')
            return TypeAnn('i32', 'counter', key_dtype=k_val)
        if kind == 'IDENT' and value == 'func':
            # 'func(dtype, dtype, ...) -> dtype' - "function reference" HEP
            # (Wave 3, 2026-07-29): CHI dung lam kieu THAM SO, bieu dien 1
            # System.Func`N (xem il_type_str trong il_codegen.py). Tham so
            # va tra ve deu CHI scalar (khong ho tro list/dict/record).
            self.expect('OP', '(')
            func_params = []
            k, v, _ = self.peek()
            if not (k == 'OP' and v == ')'):
                while True:
                    k2, v2, p2 = self.advance()
                    if k2 != 'IDENT' or v2 not in DTYPES:
                        raise SyntaxError(
                            f"il_codegen: ky vong dtype trong 'func(...)', gap {v2!r} (vi tri ~{p2})")
                    func_params.append(v2)
                    k3, v3, _ = self.peek()
                    if k3 == 'OP' and v3 == ',':
                        self.advance()
                        continue
                    break
            self.expect('OP', ')')
            self.expect('ARROW')
            k4, v4, p4 = self.advance()
            if k4 != 'IDENT' or v4 not in DTYPES:
                raise SyntaxError(
                    f"il_codegen: ky vong dtype tra ve sau '->' trong 'func(...)', "
                    f"gap {v4!r} (vi tri ~{p4})")
            return TypeAnn(v4, 'func', func_params=func_params)
        if kind != 'IDENT' or value not in DTYPES:
            if kind == 'IDENT' and value in self.record_names:
                # Ten 1 'class dang record' da khai bao trong file (huong
                # tiep theo sau tuple, xem il_codegen.py) - dung nhu 1 dtype
                # vo huong (shape='record'), tham chieu THANG ten class
                # (khong ho tro mang/list/dict cua record trong pham vi nay).
                return TypeAnn(value, 'record')
            if kind == 'IDENT' and value in self.extern_class_names:
                # Ten 1 handle-type khai bao qua __tkv_extern_class__ (Task 2,
                # extern-class, 2026-08-18) - dung nhu 1 dtype vo huong
                # (shape='extern_class'), giong het record o tren nhung
                # tra ve .NET class NGOAI (assembly-qualified) thay vi class
                # do compiler TU SINH - xem il_type_str's nhanh moi.
                return TypeAnn(value, 'extern_class')
            raise SyntaxError(f"Ky vong dtype (f32/f64/i32/i64/str), gap {value!r} (vi tri ~{pos})")
        dtype = value
        shape = None
        kind2, value2, _ = self.peek()
        if kind2 == 'OP' and value2 == '[':
            if dtype == 'str':
                raise SyntaxError("il_codegen: 'str[...]' (mang chuoi) chua duoc ho tro - "
                                   "'str' hien CHI ho tro dang vo huong don")
            self.advance()
            shape = [int(self.expect('NUMBER'))]
            while True:
                k, v, _ = self.peek()
                if k == 'OP' and v == ',':
                    self.advance()
                    shape.append(int(self.expect('NUMBER')))
                else:
                    break
            self.expect('OP', ']')
        return TypeAnn(dtype, shape)

    def parse_default_literal(self, dtype: str):
        """default := ['-'] NUMBER | STRING - CHI literal, khong tham
        chieu bien (xem ghi chu o Param.default_node)."""
        neg = False
        kind, value, pos = self.peek()
        if kind == 'OP' and value == '-':
            self.advance()
            neg = True
            kind, value, pos = self.peek()
        if dtype == 'str':
            if neg:
                raise SyntaxError(f"il_codegen: gia tri mac dinh cho tham so kieu 'str' "
                                   f"khong the co dau '-' (vi tri ~{pos})")
            kind, value, pos = self.advance()
            if kind != 'STRING':
                raise SyntaxError(f"il_codegen: gia tri mac dinh cho tham so kieu 'str' "
                                   f"phai la 1 chuoi literal (\"...\"), gap {kind} {value!r} "
                                   f"(vi tri ~{pos})")
            return ('str_lit', value)
        kind, value, pos = self.advance()
        if kind != 'NUMBER':
            raise SyntaxError(f"il_codegen: gia tri mac dinh cho tham so kieu '{dtype}' "
                               f"phai la 1 so literal, gap {kind} {value!r} (vi tri ~{pos})")
        node = ('num', value)
        return ('neg', node) if neg else node

    def parse_param(self) -> Param:
        """param := IDENT ':' type_ann ('=' default_literal)?
                   | '*' IDENT ':' type_ann
                   | '**' IDENT ':' type_ann
        '*name: T'/'**name: T' (Phase 5.1, 2026-08-11): dong nhat kieu T
        cho MOI gia tri du them - type_ann THAT su cua Param la 'list[T]'
        (vararg) / 'dict[str,T]' (kwarg), khong phai T thuan."""
        kind0, value0, _ = self.peek()
        if kind0 == 'OP' and value0 in ('*', '**'):
            self.advance()
            is_kwarg = (value0 == '**')
            name = self.expect('IDENT')
            self.expect('OP', ':')
            elem_ta = self.parse_type_ann()
            if elem_ta.shape is not None:
                raise SyntaxError(
                    f"il_codegen: tham so '{'**' if is_kwarg else '*'}{name}' phai khai bao "
                    f"1 dtype VO HUONG (vd 'i32'/'str'), khong ho tro list/dict long nhau")
            if is_kwarg:
                type_ann = TypeAnn(elem_ta.dtype, 'dict', key_dtype='str')
            else:
                type_ann = TypeAnn(elem_ta.dtype, 'list')
            return Param(name, type_ann, None, is_vararg=not is_kwarg, is_kwarg=is_kwarg)
        name = self.expect('IDENT')
        self.expect('OP', ':')
        type_ann = self.parse_type_ann()
        default_node = None
        kind, value, _ = self.peek()
        if kind == 'OP' and value == '=':
            if type_ann.shape is not None:
                raise SyntaxError(
                    f"il_codegen: tham so '{name}' co shape (list/dict/mang) khong the "
                    f"co gia tri mac dinh - Wave 2 chi ho tro default cho scalar")
            self.advance()
            default_node = self.parse_default_literal(type_ann.dtype)
        return Param(name, type_ann, default_node)

    def parse_param_list(self):
        params = []
        kind, value, _ = self.peek()
        if kind == 'OP' and value == ')':
            return params
        params.append(self.parse_param())
        while True:
            k, v, _ = self.peek()
            if k == 'OP' and v == ',':
                self.advance()
                params.append(self.parse_param())
            else:
                break
        # Python rule: mot khi 1 tham so co default, TAT CA tham so sau no
        # cung phai co default (khong the '(a: i32 = 1, b: i32)').
        seen_default = False
        for p in params:
            if p.is_vararg or p.is_kwarg:
                continue
            if p.default_node is not None:
                seen_default = True
            elif seen_default:
                raise SyntaxError(
                    f"il_codegen: tham so '{p.name}' khong co gia tri mac dinh nhung dung "
                    f"SAU 1 tham so da co default - tat ca tham so sau tham so co default "
                    f"dau tien cung phai co default (giong Python)")
        # '*args' phai truoc '**kwargs', ca 2 phai o CUOI danh sach tham so
        # (Phase 5.1, 2026-08-11) - khong ho tro tham so thuong SAU vararg
        # (khac Python cho phep keyword-only sau '*args', DSL nay chua co
        # khai niem keyword-only rieng).
        vararg_idx = next((i for i, p in enumerate(params) if p.is_vararg), None)
        kwarg_idx = next((i for i, p in enumerate(params) if p.is_kwarg), None)
        if vararg_idx is not None and kwarg_idx is not None and vararg_idx > kwarg_idx:
            raise SyntaxError("il_codegen: '*args' phai khai bao TRUOC '**kwargs'")
        tail_start = min(x for x in (vararg_idx, kwarg_idx) if x is not None) \
            if (vararg_idx is not None or kwarg_idx is not None) else len(params)
        for p in params[tail_start:]:
            if not (p.is_vararg or p.is_kwarg):
                raise SyntaxError(
                    f"il_codegen: tham so '{p.name}' khong the dung SAU '*args'/'**kwargs' "
                    f"(khong ho tro keyword-only param rieng)")
        return params

    def parse_signature(self) -> Signature:
        # 'async def foo(...)' (Phase 4, 2026-08-11) - prefix 'async' TRUOC
        # ten ham, xem docstring Signature.is_async.
        is_async = False
        k0, v0, _ = self.peek()
        if k0 == 'IDENT' and v0 == 'async':
            self.advance()
            is_async = True
        name = self.expect('IDENT')
        self.expect('OP', '(')
        params = self.parse_param_list()
        self.expect('OP', ')')

        return_type = None
        kind, value, _ = self.peek()
        if kind == 'ARROW':
            self.advance()
            return_type = self.parse_type_ann()

        kind, value, _ = self.peek()
        if kind == 'FATARROW':
            _, _, end_pos = self.advance()
            body_expr = self.src[end_pos:].strip()
            return Signature(name, params, return_type, 'expr', body_expr, is_async=is_async)
        if kind == 'OP' and value == ':':
            self.advance()
            return Signature(name, params, return_type, 'block', is_async=is_async)
        raise SyntaxError(f"Ky vong '=>' (ham 1 bieu thuc) hoac ':' (ham nhieu dong) "
                           f"sau chu ky, gap {kind} {value!r}")


def parse_typed_signature(line: str, record_names=frozenset(), extern_class_names=frozenset()) -> Signature:
    """Ham tien ich chinh: parse 1 DONG chu ky co kieu, tra ve Signature.
    Nem SyntaxError neu dong khong dung ngu phap typed_sig.
    record_names: ten cac 'class dang record' da khai bao trong CUNG file
    (de chap nhan chung nhu 1 dtype tham so/return type, vd 'p: "Point"').
    extern_class_names: ten cac handle-type khai bao qua
    __tkv_extern_class__ trong CUNG file (Task 2, extern-class, 2026-08-18)
    - chap nhan y het record_names."""
    tokens = tokenize(line)
    return Parser(tokens, line, record_names=record_names,
                  extern_class_names=extern_class_names).parse_signature()


def parse_type_ann_str(text: str, record_names=frozenset(), extern_class_names=frozenset()) -> TypeAnn:
    """Parse 1 CHUOI kieu don le ('list[str]', 'dict[str,i32]', 'f64')
    thanh TypeAnn - dung cho FIELD cua class (2026-08-03, field chua
    container). Tach rieng khoi parse_typed_signature vi o day khong co
    chu ky ham nao ca, chi 1 kieu. extern_class_names: xem
    parse_typed_signature."""
    tokens = tokenize(text)
    parser = Parser(tokens, text, record_names=record_names,
                     extern_class_names=extern_class_names)
    ta = parser.parse_type_ann()
    k, v, pos = parser.peek()
    if k != 'EOF':
        raise SyntaxError(f"Kieu {text!r} con thua token {v!r} (vi tri ~{pos})")
    return ta


def looks_like_typed_signature(line: str) -> bool:
    """Kiem tra nhanh (khong parse day du) truoc khi thu parse that - dung
    de phan biet 1 dong la "chu ky typed function" hay la code Python/DSL
    thuong khac, tranh nem SyntaxError tran lan khi quet qua file."""
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        return False
    return bool(re.match(r'^[A-Za-z_]\w*\s*\(.*\)\s*(->|:|=>)', stripped) or
                re.match(r'^[A-Za-z_]\w*\s*\(.*=>', stripped))


if __name__ == '__main__':
    tests = [
        'dot(a: f32[256], b: f32[256]) -> f32 => sum(a * b)',
        'matmul(a: f32[64, 64], b: f32[64, 64]) -> f32[64, 64]:',
        'scale(x: f32[10], factor: f32) -> f32[10] => x * factor',
        'noop() => 0',
    ]
    for t in tests:
        sig = parse_typed_signature(t)
        print(f'{t!r}\n  -> {sig}\n')
