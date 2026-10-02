"""Duck-typing qua type-inference tinh (Task 3/5, 2026-08-17, plan
duck-typing-inference) - thu thap "interface an" tu than ham cho MOI tham
so ham top-level mang dtype 'inferred' (xem tkv_compile.py's
INFERRED_DTYPE_MARKER, gan boi _params_with_defaults khi allow_inferred=True
va annotation thieu, Task 2/5).

Module nay CHI lam buoc THU THAP (quet AST goc cua than ham, ghi lai CACH
tham so 'inferred' duoc dung TRUC TIEP - doc field/goi method/toan tu nhi
nguyen) - CHUA lam resolve tai call-site/monomorphize (Task 4). Dat CUNG
cap voi operators.py/record_feature.py (compiler/il_features/*.py) theo
dung de xuat Task 1 report, muc 6.

Vi sao quet tren ast.FunctionDef GOC (khong phai body_lines text da dedent/
rewrite): AST co san cau truc Attribute/Call/BinOp/Compare day du, khong can
re-parse text qua il_core.py's _ExprParser (khac voi cach il_codegen.py xu
ly bieu thuc luc CODEGEN, o day chi can XAC DINH HINH DANG usage, khong can
sinh CIL) - dung dung thoi diem con AST (truoc khi _body_source_lines()
chuyen thanh danh sach dong text trong tkv_compile.py's vong lap
tree.body, xem _parse_program_ast)."""

import ast


class Constraint:
    """Lop co so cho 3 dang rang buoc - MOI subclass (FieldConstraint/
    MethodConstraint/OperatorConstraint) TU VIET __eq__/__hash__ rieng
    (KHONG phai __eq__/__hash__ mac dinh cua dataclass-like tuple) de
    _add_constraint() khu trung lap don gian (vd 'p.x' xuat hien 2 lan
    trong than ham chi ghi 1 FieldConstraint('x'))."""


class FieldConstraint(Constraint):
    """Tham so doc TRUC TIEP 1 thuoc tinh: 'param.field'."""

    __slots__ = ('name',)

    def __init__(self, name):
        self.name = name

    def __eq__(self, other):
        return isinstance(other, FieldConstraint) and self.name == other.name

    def __hash__(self):
        return hash(('field', self.name))

    def __repr__(self):
        return f'FieldConstraint({self.name!r})'


class MethodConstraint(Constraint):
    """Tham so goi TRUC TIEP 1 method: 'param.method(a, b)' -> arity=2."""

    __slots__ = ('name', 'arity')

    def __init__(self, name, arity):
        self.name = name
        self.arity = arity

    def __eq__(self, other):
        return (isinstance(other, MethodConstraint) and self.name == other.name
                and self.arity == other.arity)

    def __hash__(self):
        return hash(('method', self.name, self.arity))

    def __repr__(self):
        return f'MethodConstraint({self.name!r}, arity={self.arity})'


class OperatorConstraint(Constraint):
    """Tham so dung TRUC TIEP lam mot ve cua 1 toan tu nhi nguyen/so sanh:
    'param + x' / 'x + param' / 'param == y' / ... - `op` la ky hieu toan
    tu van ban ('+', '==', ...), KHONG phan biet ve trai/phai (ca hai deu
    can cung 1 dunder/toan tu ho tro tai buoc resolve o Task 4)."""

    __slots__ = ('op',)

    def __init__(self, op):
        self.op = op

    def __eq__(self, other):
        return isinstance(other, OperatorConstraint) and self.op == other.op

    def __hash__(self):
        return hash(('operator', self.op))

    def __repr__(self):
        return f'OperatorConstraint({self.op!r})'


_BINOP_TO_STR = {
    ast.Add: '+', ast.Sub: '-', ast.Mult: '*', ast.Div: '/',
    ast.FloorDiv: '//', ast.Mod: '%', ast.Pow: '**',
}

_CMPOP_TO_STR = {
    ast.Eq: '==', ast.NotEq: '!=', ast.Lt: '<', ast.LtE: '<=',
    ast.Gt: '>', ast.GtE: '>=',
}


class _ConstraintVisitor(ast.NodeVisitor):
    """Duyet than ham 1 lan, ghi nhan MOI usage TRUC TIEP hop le cua cac
    tham so 'inferred' (fields/methods/operators - dung dung 3 shape brief
    quy dinh), danh dau (qua `id(node)`, node AST khong hashable-value nhung
    object identity la duy nhat trong 1 cay) MOI node ast.Name(param) da
    duoc 'xu ly' boi 1 trong 3 nhanh do. Sau khi duyet xong,
    collect_inferred_constraints() quet lai TOAN BO cay bang ast.walk() -
    bat ky ast.Name(param, Load) nao CHUA duoc danh dau la 1 usage GIAN
    TIEP (argument cua ham/method KHAC, chi so [], gan lai bien, ...) ->
    raise TranspileError NGAY (dung thiet ke 'khong lan truyen')."""

    def __init__(self, param_names):
        self.param_names = param_names
        self.constraints = {p: [] for p in param_names}
        self.handled_ids = set()

    def _add(self, param, constraint):
        lst = self.constraints[param]
        if constraint not in lst:
            lst.append(constraint)

    def visit_Attribute(self, node):
        # 'param.field' (doc, ctx=Load) VA 'param.field = x' (ghi, ctx=Store)
        # deu duoc coi la FieldConstraint('field') GIONG NHAU - buoc THU
        # THAP nay khong phan biet field CO THE GHI duoc hay khong (chi can
        # field TON TAI tren kieu cu the, Task 4's resolve_call_site() se
        # tu quyet dinh gan duoc hay khong). Luu y: day la Attribute node
        # (node.value la Name(param)) - KHAC voi ast.Name(param, ctx=Store)
        # o collect_inferred_constraints() (gan lai CHINH bien param, vd
        # 'param = x') - truong hop do van bi raise, KHONG duoc lan voi
        # truong hop field-write hop le nay.
        #
        # Chi field TANG 1 ('param.field') duoc bat truc tiep o day - field
        # LONG NHAU ('param.field.sub') CHI dung lai o '.field' (FieldConstraint
        # 'field'), phan '.sub' KHONG duoc phan tich them o buoc THU THAP
        # nay (day la HANH VI CO Y, khong phai thieu sot: '.sub' se duoc
        # resolve tren KIEU CUA field do o Task 4, sau khi kieu cu the cua
        # 'field' da xac dinh).
        if isinstance(node.value, ast.Name) and node.value.id in self.param_names:
            self.handled_ids.add(id(node.value))
            self._add(node.value.id, FieldConstraint(node.attr))
            return
        self.generic_visit(node)

    def visit_Call(self, node):
        func = node.func
        if isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name) \
                and func.value.id in self.param_names:
            self.handled_ids.add(id(func.value))
            # arity gom CA node.args LAN node.keywords (vd 'p.m(1, k=2)' ->
            # arity=2) - Task 4 chi can so luong tham so TRUYEN VAO de doi
            # chieu voi method that; validate rieng ten keyword co khop
            # tham so cua method that hay khong la pham vi cua Task 4's
            # resolve_call_site(), khong phai buoc THU THAP nay.
            self._add(func.value.id,
                      MethodConstraint(func.attr, len(node.args) + len(node.keywords)))
            # Van duyet tiep cac argument (co the tu chua 1 usage khac cua
            # 1 tham so inferred KHAC - hoac usage GIAN TIEP can bi bat,
            # vd 'p.method(q)' voi q cung la 1 tham so inferred khac -
            # KHONG duoc coi la truc tiep, se bi flag o buoc quet cuoi).
            for a in node.args:
                self.visit(a)
            for kw in node.keywords:
                self.visit(kw.value)
            return
        self.generic_visit(node)

    def visit_BinOp(self, node):
        op_str = _BINOP_TO_STR.get(type(node.op))
        left_is_param = isinstance(node.left, ast.Name) and node.left.id in self.param_names
        right_is_param = isinstance(node.right, ast.Name) and node.right.id in self.param_names
        if op_str and (left_is_param or right_is_param):
            if left_is_param:
                self.handled_ids.add(id(node.left))
                self._add(node.left.id, OperatorConstraint(op_str))
            else:
                self.visit(node.left)
            if right_is_param:
                self.handled_ids.add(id(node.right))
                self._add(node.right.id, OperatorConstraint(op_str))
            else:
                self.visit(node.right)
            return
        self.generic_visit(node)

    def visit_Compare(self, node):
        operands = [node.left] + list(node.comparators)
        for op, a, b in zip(node.ops, operands, operands[1:]):
            op_str = _CMPOP_TO_STR.get(type(op))
            if op_str is None:
                continue
            if isinstance(a, ast.Name) and a.id in self.param_names:
                self.handled_ids.add(id(a))
                self._add(a.id, OperatorConstraint(op_str))
            if isinstance(b, ast.Name) and b.id in self.param_names:
                self.handled_ids.add(id(b))
                self._add(b.id, OperatorConstraint(op_str))
        for operand in operands:
            if not (isinstance(operand, ast.Name) and operand.id in self.param_names):
                self.visit(operand)


def collect_inferred_constraints(sig, func_node_ast, records, record_methods):
    """sig: Signature DA parse (typed_dsl_parser.py) cua CHINH ham
    func_node_ast - dung de xac dinh tham so nao dtype == 'inferred'
    (INFERRED_DTYPE_MARKER, gan boi tkv_compile.py's _params_with_defaults
    khi allow_inferred=True). func_node_ast: ast.FunctionDef/AsyncFunctionDef
    GOC cua CHINH ham do (truoc khi chuyen sang body_lines text).

    records/record_methods: NHAN de khop dung chu ky brief (Task 1 report,
    muc 6) - o buoc THU THAP nay CHUA can dung toi (khong resolve kieu cu
    the, chi ghi lai HINH DANG usage) - viec kiem tra field/method/toan tu
    do co ton tai tren 1 kieu CU THE nao khong la viec cua Task 4's
    resolve_call_site(), tai dung dung co che tra cuu dunder cua
    operators.py's compile_binop/compile_compare (xem Task 1 report muc 4).
    Giu tham so o day de khong phai doi chu ky khi Task 4 can mo rong
    (vd validate ten field/method KHONG rong ngay luc collect).

    Tra ve: dict[param_name(str), list[Constraint]] - CHI gom cac tham so
    co dtype == 'inferred' trong `sig`. Tham so inferred KHONG dung usage
    truc tiep hop le nao van co mat trong dict voi list RONG (vd tham so
    inferred nhung khong dung gi trong than ham - hop le, se khong resolve
    duoc gi o Task 4 nhung khong phai loi o day).

    raise: TranspileError (lazy-import tu tkv_compile de tranh circular
    import - module nay duoc tkv_compile.py import o muc module-level,
    xem ghi chu dau file) NGAY khi gap 1 usage ast.Name(param, Load) KHONG
    thuoc 3 shape truc tiep (field/method/operator) - vd tham so truyen lam
    argument cua 1 loi goi ham/method KHAC, dung lam chi so 'param[i]', hoac
    gan lai 'x = param' roi dung 'x' thay the."""
    from tkv_compile import TranspileError  # tranh circular import (xem docstring)

    inferred_params = {p.name for p in sig.params
                        if p.type_ann is not None and p.type_ann.dtype == 'inferred'}
    if not inferred_params:
        return {}

    visitor = _ConstraintVisitor(inferred_params)
    for stmt in func_node_ast.body:
        visitor.visit(stmt)

    # Gan lai/xoa CHINH bien tham so ('param = x' hoac 'del param') - ctx
    # Store/Del cua ast.Name(param) - KHONG duoc bo qua nhu truoc (truoc day
    # chi loc ctx=Load nen 'param = 5; return param + 1' bi ghi nhan SAI
    # OperatorConstraint('+') cua int 5 thay vi cua tham so, va 'param += 1'
    # bi nuot hoan toan khong raise). Day la 1 dang usage GIAN TIEP (redefine/
    # shadow bien) - raise NGAY, thong diep RIENG de khong lan voi cac usage
    # gian tiep khac. LUU Y PHAN BIET: day la ast.Name('param', Store) (gan
    # lai CHINH bien) - KHAC HOAN TOAN voi ast.Attribute(value=Name('param'),
    # attr='f', ctx=Store) (gan vao FIELD cua param, vd 'param.f = 1') - truong
    # hop field-write van HOP LE (FieldConstraint, xem visit_Attribute), vi
    # node.value (Name('param')) trong Attribute do co ctx=Load, KHONG phai
    # Store, nen KHONG bi bat boi vong nay.
    # AugAssign tren CHINH tham so ('param += x', 'param -= x', ...) duoc
    # kiem tra TRUOC vong Store/Del ben duoi (target cua AugAssign cung la
    # ast.Name(param, ctx=Store) ve mat ky thuat) de thong diep loi RO RANG
    # hon (khac voi gan lai binh thuong) - nguoi dung hieu DUNG nguyen nhan
    # la "augmented assign chua ho tro" chu khong nham voi "truyen vao ham
    # khac" hay "gan lai binh thuong".
    augassign_target_ids = set()
    for node in ast.walk(func_node_ast):
        if isinstance(node, ast.AugAssign) and isinstance(node.target, ast.Name) \
                and node.target.id in inferred_params:
            augassign_target_ids.add(id(node.target))
            raise TranspileError(
                f"ham '{sig.name}': tham so '{node.target.id}' (dtype 'inferred', suy kieu qua "
                f"cach dung) dung augmented assign ('param += x' hoac tuong tu) o dong "
                f"~{getattr(node, 'lineno', '?')} - augmented assign tren tham so kieu suy tu "
                f"dong (inferred) CHUA duoc ho tro. Neu can gan lai gia tri, khai kieu tuong "
                f"minh cho tham so nay thay vi de trong (bo annotation).")

    for node in ast.walk(func_node_ast):
        if isinstance(node, ast.Name) and node.id in inferred_params \
                and isinstance(node.ctx, (ast.Store, ast.Del)) \
                and id(node) not in augassign_target_ids:
            action = 'xoa (del)' if isinstance(node.ctx, ast.Del) else 'gan lai'
            raise TranspileError(
                f"ham '{sig.name}': tham so '{node.id}' (dtype 'inferred', suy kieu qua "
                f"cach dung) bi {action} o dong ~{getattr(node, 'lineno', '?')} - gan lai/xoa "
                f"CHINH bien tham so (vd 'param = x' hoac 'del param') lam mat kha nang suy kieu "
                f"tu cach dung ban dau, chua duoc ho tro. Neu can gan lai gia tri, khai kieu "
                f"tuong minh cho tham so nay thay vi de trong (bo annotation).")

    for node in ast.walk(func_node_ast):
        if isinstance(node, ast.Name) and node.id in inferred_params \
                and isinstance(node.ctx, ast.Load) and id(node) not in visitor.handled_ids:
            raise TranspileError(
                f"ham '{sig.name}': tham so '{node.id}' (dtype 'inferred', suy kieu qua "
                f"cach dung) o dong ~{getattr(node, 'lineno', '?')} dung theo cach GIAN TIEP "
                f"khong suy duoc kieu (vd truyen lam argument cho 1 loi goi ham/method KHAC, "
                f"dung lam chi so 'param[i]', hoac gan lai 'x = param' roi dung 'x' thay the) - "
                f"chi ho tro dung TRUC TIEP: doc thuoc tinh 'param.field', goi method "
                f"'param.method(...)', hoac toan tu nhi nguyen/so sanh 'param + x'/'param == x'. "
                f"Neu can dung theo cach khac, khai kieu tuong minh cho tham so nay thay vi de "
                f"trong (bo annotation).")

    return visitor.constraints


# ---------------------------------------------------------------------------
# Task 4/5: resolve tai call-site + monomorphize (mangle ten).
#
# mangle_name dung '$' lam ky tu phan cach - '$' KHONG phai ky tu hop le
# trong 1 Python identifier (nguon goc ten ham DSL luon la 1 def PYTHON
# THAT, xem tkv_compile.py's ast.parse) nen KHONG THE trung voi bat ky ten
# ham nguoi dung tu dat (khac voi de xuat '__' ban dau cua Task 1 report -
# '__' VAN la ky tu hop le trong 1 identifier Python, vd 'foo__bar' - kiem
# chung lai luc Task 4 implement, an toan hon dung '$'). CIL cho phep BAT KY
# chuoi nao lam ten dinh danh khi boc trong dau nhay don (xem il_codegen.py's
# _il_ident - MOI ten deu duoc boc, khong rieng gi ten mangled) nen '$' hop
# le ve mat CIL du khong hop le ve mat Python.
def mangle_name(func_name, concrete_types):
    """concrete_types: list[str] cac dtype/ten-record CU THE (THEO DUNG THU
    TU cac tham so 'inferred' xuat hien trong sig.params, KHONG phai thu tu
    xuat hien trong loi goi) da duoc resolve cho 1 ham co >=1 tham so
    'inferred'. Tra ve 1 ten ham MOI, DUY NHAT cho tung to hop (func_name,
    concrete_types) - dung lam '.name' cua Signature monomorphize VA lam
    khoa cache (cung voi func_name) trong _expr_call/il_codegen.py."""
    return f'{func_name}$T${"$".join(concrete_types)}'


def _ancestors(record_bases, type_name):
    """Tap {type_name} UNION toan bo to tien (dung ho tro record ke thua,
    xem 'ancestors' duoc dung y HET trong operators.py's compile_binop/
    compile_compare - dong dung 1 vong lap thu cong TRUC TIEP tren
    record_bases, KHONG qua _field_owner_class/_method_owner_class, dung
    theo dung Task 1 report muc 4.3)."""
    ancestors = {type_name}
    walk = type_name
    while isinstance(record_bases.get(walk), str) and record_bases.get(walk):
        walk = record_bases[walk]
        ancestors.add(walk)
    return ancestors


def _check_constraint(func_name, param_name, constraint, concrete_type,
                       records, record_methods, record_bases, caller_desc):
    """1 rang buoc (FieldConstraint/MethodConstraint/OperatorConstraint) ->
    raise TranspileError NGAY neu 'concrete_type' KHONG thoa. Tai dung DUNG
    co che tra cuu dunder cua operators.py's compile_binop/compile_compare
    (Task 1 report muc 4) - KHONG viet lai logic khac."""
    from tkv_compile import TranspileError
    import il_codegen
    loc = (f"ham '{func_name}': tham so '{param_name}' (kieu cu the "
           f"'{concrete_type}', suy ra tu loi goi trong ham '{caller_desc}')")

    if concrete_type in il_codegen._EXTERN_CLASS_DEFS:
        raise TranspileError(
            f"duck-typing: tham so 'inferred' khong the la extern-class handle type "
            f"{concrete_type!r} - handle type khong tham gia co che suy kieu nay, "
            f"khai annotation tuong minh")

    if isinstance(constraint, FieldConstraint):
        if concrete_type not in records:
            raise TranspileError(
                f"{loc} can co field '.{constraint.name}' nhung kieu "
                f"'{concrete_type}' la kieu vo huong (scalar), khong phai record "
                f"nen khong co field nao.")
        for anc in _ancestors(record_bases, concrete_type):
            if constraint.name in dict(records.get(anc, [])):
                return
        raise TranspileError(
            f"{loc} can co field '.{constraint.name}' nhung record "
            f"'{concrete_type}' (va to tien cua no) khong co field nay.")

    if isinstance(constraint, MethodConstraint):
        if concrete_type not in records:
            raise TranspileError(
                f"{loc} can co method '.{constraint.name}(...)' nhung kieu "
                f"'{concrete_type}' la kieu vo huong (scalar), khong phai record "
                f"nen khong co method nao.")
        method_sig = None
        for anc in _ancestors(record_bases, concrete_type):
            m = (record_methods.get(anc) or {}).get(constraint.name)
            if m is not None:
                method_sig = m
                break
        if method_sig is None:
            raise TranspileError(
                f"{loc} can co method '.{constraint.name}(...)' nhung record "
                f"'{concrete_type}' (va to tien cua no) khong co method nay.")
        if len(method_sig.params) != constraint.arity:
            raise TranspileError(
                f"{loc} goi method '.{constraint.name}(...)' voi {constraint.arity} "
                f"tham so nhung method that cua record '{concrete_type}' can dung "
                f"{len(method_sig.params)} tham so.")
        return

    if isinstance(constraint, OperatorConstraint):
        op = constraint.op
        if concrete_type not in records:
            # Kieu vo huong (i32/i64/f32/f64/str/int/complex/...) ho tro
            # toan tu nhi nguyen/so sanh TU NHIEN qua ha tang codegen co
            # san (operators.py) - khong can kiem tra them o day.
            return
        if op == '+':
            for anc in _ancestors(record_bases, concrete_type):
                if (record_methods.get(anc) or {}).get('__add__') is not None:
                    return
            raise TranspileError(
                f"{loc} dung toan tu '+' nhung record '{concrete_type}' (va to tien "
                f"cua no) khong co '__add__' - '+' tren record can dinh nghia "
                f"'def __add__(self, other) -> \"T\":'.")
        if op in ('==', '!='):
            # __eq__ CO THI DUNG, KHONG CO thi ROI xuong so sanh mac dinh
            # (reference-compare) - operators.py's compile_compare khong
            # bao gio raise cho '=='/'!=' tren record, xem Task 1 report
            # muc 4.2. Vi vay KHONG can kiem tra gi them o day.
            return
        # '<'/'<='/'>'/'>=' tren record: operators.py's compile_compare
        # HIEN KHONG tra cuu dunder nao cho 4 toan tu nay (chi '=='/'!=' co
        # __eq__, xem muc 4.2) - neu de qua, codegen se sinh so sanh mac
        # dinh SAI (so sanh tham chieu doi tuong bang < / > vo nghia).
        # Chan RO tai day thay vi de loi am tham o tang codegen.
        raise TranspileError(
            f"{loc} dung toan tu '{op}' tren record '{concrete_type}' - toan tu nay "
            f"CHUA duoc ho tro cho record (hien chi ho tro '+' qua __add__ va "
            f"'=='/'!=' mac dinh). Khai kieu tuong minh cho tham so nay neu can "
            f"dung toan tu khac.")


def resolve_call_site(sig, concrete_arg_types, records, record_methods, record_bases,
                       call_site_info=None):
    """sig: Signature GOC (co >=1 tham so dtype=='inferred', voi
    sig.inferred_constraints da duoc collect_inferred_constraints() gan san,
    xem Task 3). concrete_arg_types: dict[ten_tham_so(str) -> kieu_cu_the(str)]
    - CHI can gom cac tham so 'inferred' (kieu cu the: dtype vo huong nhu
    'i32'/'str'/... HOAC ten 1 record). records/record_methods/record_bases:
    3 bang da co san, TRUYEN THANG tu ctx (xem il_codegen.py's _expr_call).
    call_site_info: dict tuy chon, CHI dung de lam thong bao loi ro hon (vd
    {'caller_name': ten_ham_dang_goi}).

    Kiem tra TUNG rang buoc da thu thap (Task 3) cho TUNG tham so inferred so
    voi kieu cu the tuong ung trong concrete_arg_types - KHONG thoa 1 rang
    buoc nao -> raise TranspileError NGAY (xem _check_constraint). Thoa HET
    -> tra ve 1 Signature MOI (params da thay 'inferred' bang kieu cu the,
    '.name' da mangle qua mangle_name) - Signature GOC (sig) KHONG bi doi.

    Neu sig KHONG co tham so 'inferred' nao, tra ve NGUYEN sig (khong mangle,
    khong tao object moi) - cho phep goi ham nay VO DIEU KIEN tai diem chen
    trong _expr_call (kiem tra "co can resolve khong" o CHINH ham nay, caller
    khong can tu kiem tra truoc)."""
    from tkv_compile import TranspileError
    from typed_dsl_parser import Signature, Param, TypeAnn

    inferred_params = [p for p in sig.params
                        if p.type_ann is not None and p.type_ann.dtype == 'inferred']
    if not inferred_params:
        return sig

    call_site_info = call_site_info or {}
    caller_desc = call_site_info.get('caller_name') or '?'
    constraints = getattr(sig, 'inferred_constraints', None) or {}

    resolved_by_param = {}
    for p in inferred_params:
        concrete_type = concrete_arg_types.get(p.name)
        if not concrete_type:
            raise TranspileError(
                f"ham '{sig.name}': khong suy duoc kieu cu the cho tham so '{p.name}' "
                f"(dtype 'inferred') tai loi goi trong ham '{caller_desc}' - doi so truyen "
                f"vao co dtype khong xac dinh duoc (vd 1 bieu thuc phuc tap chua ho tro suy "
                f"kieu tinh). Khai kieu tuong minh cho tham so nay, hoac dung 1 bien don "
                f"gian lam doi so.")
        resolved_by_param[p.name] = concrete_type
        # Tham so 'inferred' KHONG duoc nhan extern-class handle type - kiem
        # tra NAY phai chay VO DIEU KIEN (khong phu thuoc constraints.get(p.name))
        # vi 1 tham so 'inferred' HOP LE co the KHONG co rang buoc nao (than
        # than KHONG dung trong body - xem docstring collect_inferred_constraints
        # o Task 3), khien vong for c in constraints.get(...) o duoi khong
        # chay lan nao va _check_constraint (noi dang co kiem tra
        # _EXTERN_CLASS_DEFS) khong bao gio duoc goi cho tham so do - handle
        # type se lot qua het qua khoi resolve_call_site va gay KeyError o
        # il_type_str sau nay (xem 5th instance cua bug class trong
        # docs/BUGS_TODO.md muc O). Import cham (tranh vong lap import voi
        # il_codegen o module-load-time, giong cach _check_constraint lam).
        import il_codegen
        if concrete_type in il_codegen._EXTERN_CLASS_DEFS:
            raise TranspileError(
                f"ham '{sig.name}': tham so 'inferred' '{p.name}' khong the la "
                f"extern-class handle type {concrete_type!r} (tai loi goi trong ham "
                f"'{caller_desc}') - handle type khong tham gia co che suy kieu nay, "
                f"du tham so co dung trong than ham hay khong. Khai annotation tuong minh.")
        for c in constraints.get(p.name, []):
            _check_constraint(sig.name, p.name, c, concrete_type,
                               records, record_methods, record_bases, caller_desc)

    concrete_types_in_order = [resolved_by_param[p.name] for p in inferred_params]
    mangled = mangle_name(sig.name, concrete_types_in_order)

    new_params = []
    for p in sig.params:
        if p.name in resolved_by_param:
            ct = resolved_by_param[p.name]
            new_ta = TypeAnn(ct, 'record' if ct in records else None)
            new_params.append(Param(p.name, new_ta, default_node=p.default_node,
                                     is_vararg=p.is_vararg, is_kwarg=p.is_kwarg))
        else:
            new_params.append(p)

    new_sig = Signature(mangled, new_params, sig.return_type, sig.body_mode,
                         body_expr=sig.body_expr, is_static=sig.is_static,
                         is_async=sig.is_async)
    # Rang buoc CHI can cho lan resolve NAY (tham so da thanh kieu cu the
    # that, khong con 'inferred' nao) - khong can giu lai tren Signature moi
    # (tranh resolve-lai vo nghia neu co code nao vo tinh doc lai thuoc tinh
    # nay tren new_sig).
    new_sig.inferred_constraints = {}
    return new_sig
