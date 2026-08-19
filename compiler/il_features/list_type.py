# -*- coding: utf-8 -*-
"""Kieu IL cua List<T> dong - tach rieng file theo tinh nang (2026-07-28)
de sua bug/test list KHONG can dong den phan dict/set/tuple. Xem
il_core.py cho kernel dung chung.

Tu Phase 1 buoc 1 (2026-07-28), file nay CUNG so huu logic parse+codegen
+first-pass rieng cua list (khong chi ham kieu-IL thuan nhu truoc). Cac
ham can goi lai vao core (_compile_expr/_load_var_ref/_widen_if_needed...)
nhan chung qua tham so `ctx` (dictionary duoc 'tiem' san cac ham nay -
xem gen_il_function trong il_codegen.py) THAY VI import truc tiep tu
il_codegen.py - BAT BUOC de tranh circular import (il_codegen.py import
CA file nay, file nay khong bao gio duoc import nguoc lai)."""
import re

from il_core import IL_SCALAR, parse_expr, emit_index_value
from il_dispatch import (
    register_assign_rhs_parser, register_line_parser,
    register_stmt_codegen, register_first_pass_walk,
)


def il_list_elem_ilstr(dtype: str, records: dict = None, extern_class_defs: dict = None) -> str:
    """Kieu IL cua 1 PHAN TU List<T>/Dictionary value/HashSet<T> - dtype
    vo huong THAT (tra ve IL_SCALAR[dtype]) HOAC ten 1 'class dang record'
    da khai bao (tra ve 'class TenRecord' - khoang trong ngon ngu #2,
    "List chua record"; DA doi tu 'valuetype' sang 'class' cung B1,
    2026-07-29 - record gio la reference type, xem project-tokenvector-
    wave2-status memory) HOAC ten 1 extern-class da khai bao (tra ve
    'class [assembly]ClassName' - Task 2, extern-class-list, 2026-08-18).
    Dung CHUNG boi ca list_type.py/dict_type.py/set_type.py (khong dat
    rieng moi noi, tranh trung lap logic). `extern_class_defs` mac dinh
    None de KHONG pha cac call site cu (record-only, chua biet
    extern-class)."""
    elem = IL_SCALAR.get(dtype)
    if elem is not None:
        return elem
    if records and dtype in records:
        return f'class {dtype}'
    if extern_class_defs and dtype in extern_class_defs:
        d = extern_class_defs[dtype]
        return f"class [{d['assembly']}]{d['class']}"
    raise SyntaxError(
        f"il_codegen: List phan tu kieu {dtype!r} khong hop le - phai la dtype vo huong "
        f"(f32/f64/i32/i64/str) hoac ten 1 class dang record/extern-class da khai bao")


def il_list_type(dtype: str, records: dict = None, extern_class_defs: dict = None) -> str:
    """Kieu IL cua 1 List<T> DONG (closed generic) - dung CHUNG cho khai
    bao local, .ctor, va cac method Add/get_Item/get_Count (khi goi tren
    generic type DA DONG, IL ghi THANG kieu cu the, KHONG dung placeholder
    !0 - placeholder chi dung khi goi tren DINH NGHIA generic mo).
    `extern_class_defs` mac dinh None (Task 2, extern-class-list)."""
    return (f'class [mscorlib]System.Collections.Generic.List`1'
            f'<{il_list_elem_ilstr(dtype, records, extern_class_defs)}>')


_LIST_LIT_RE = re.compile(r'^\[.*\]$', re.S)
_LIST_APPEND_RE = re.compile(r'^(\w+)\.append\((.+)\)\s*$')


def compile_index_list(name, indices, scope, out, dtype, ctx):
    """CIL cho 'lst[i]' (doc 1 phan tu List<T>) - tag 'index' cua
    _compile_expr khi shape=='list', xem il_codegen.py's _expr_index.
    Dung ctx['il_type_str'] (DE QUY) thay vi il_list_type(dtype,...) THANG
    - can THIET tu Wave 2 (2026-07-29, container long nhau): khi 'lst' la
    List<List<T>>/List<Dict<K,V>> (type_ann.elem_ta khac None), chi
    il_type_str moi tinh dung kieu IL day du cua CHINH list nay (xem
    il_codegen.py's il_type_str) - voi list thuong (elem_ta=None), 2 ham
    cho ra CHUOI GIONG HET NHAU (khong doi hanh vi cu)."""
    if len(indices) != 1:
        raise SyntaxError(f"il_codegen: list '{name}' chi ho tro 1 chi so")
    _, _, type_ann = scope[name]
    list_type = ctx['il_type_str'](type_ann, (ctx or {}).get('records'))
    ctx['load_var_ref'](name, scope, out)
    emit_index_value(name, indices[0], scope, out, ctx,
                      f'callvirt instance int32 {list_type}::get_Count()')
    # QUAN TRONG: tra ve '!0' (placeholder generic param), KHONG phai
    # kieu da thay the (vd float32) - bug that phat hien qua test
    # (MissingMethodException luc chay): metadata cua get_Item duoc dinh
    # nghia TREN generic type DINH NGHIA MO voi kieu tra ve la !0;
    # methodref phai ghi DUNG nhu vay, phan <float32> chi cung cap ngu
    # canh thay the cho KIEU KHAI BAO, khong doi chu ky cua chinh method.
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    ctx['widen_if_needed'](type_ann.dtype, dtype, out)


def try_rhs_list_literal(rhs, name, known_shapes):
    """ASSIGN_RHS_PARSERS entry: 'lst = []' HOAC 'xs = [3, 1, 2]' - Giai
    doan 0.1 (2026-08-03, dong Python-parity-gap v2): dung PARSER THAT
    (parse_expr, tag 'list_literal' vua them vao il_core.py's parse_factor)
    thay vi tu tach dau phay bang tay - tu dong dung ke ca phan tu chua
    bieu thuc long nhau/dau phay trong ham (vd '[f(1, 2), 3]').

    RONG ('[]'): dtype phan tu CHUA biet o day, suy sau tu LAN GOI
    '.append(...)' DAU TIEN tren bien nay (xem declare_list) - giu NGUYEN
    hanh vi cu (stmt kind 'assign_list_new'), khong doi gi.

    CO PHAN TU ('[3, 1, 2]'): dtype suy THANG tu chinh cac phan tu (xem
    declare_list_literal), khong can quet '.append()' sau do."""
    rhs_s = rhs.strip()
    if not _LIST_LIT_RE.match(rhs_s):
        return None
    node = parse_expr(rhs_s)
    if node[0] != 'list_literal':
        return None
    known_shapes[name] = 'list'
    if not node[1]:
        return {'kind': 'assign_list_new', 'name': name}
    return {'kind': 'assign_list_literal', 'name': name, 'elements': node[1]}


def try_parse_list_append(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'lst.append(x)' - PHAI dang ky TRUOC
    method_call_stmt (pattern method-call tong quat cung khop dong nay).

    Loai tru known_shapes=='bytearray' (muc 6.8, 3/4, 2026-08-13, giong het
    cach try_parse_list_remove da loai tru set/frozenset o duoi): 'ba.append(x)'
    tren bytearray CAN codegen RIENG (chen 'conv.u1' truoc Add(!0) - xem
    bytearray_type.py) - neu KHONG loai tru o day, nhanh list nay se cuop
    mat truoc (list_type.py duoc import/dang ky TRUOC bytearray_type.py
    trong il_codegen.py, LINE_PARSERS thu THEO THU TU dang ky) va bo lo
    buoc narrow bat buoc do.

    Loai tru THEM known_shapes=='bytes' (muc 6.8, 4/4, 2026-08-13): 'data.append(x)'
    tren bien 'bytes' (bat bien) PHAI bi try_parse_bytes_append_blocked
    (bytes_type.py) bat va nem SyntaxError bat bien - neu KHONG loai tru o
    day, nhanh list nay se cuop mat truoc va sinh IL append hop le (SAI,
    'bytes' khong duoc mutate)."""
    m = _LIST_APPEND_RE.match(line)
    if not m or known_shapes.get(m.group(1)) in ('bytearray', 'bytes'):
        return None
    name, arg_expr = m.groups()
    return {'kind': 'list_append', 'name': name, 'value_node': parse_expr(arg_expr)}, pos + 1


def codegen_assign_list_new(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst = []'. Dung ctx['il_type_str'] (DE QUY, xem
    il_codegen.py) thay il_list_type THANG - can THIET tu Wave 2
    (2026-07-29) de ho tro dung List<List<T>>/List<Dict<K,V>> khi ta.elem_ta
    khac None; voi list thuong ra CUNG 1 chuoi nhu truoc."""
    _, _, ta = scope[stmt['name']]
    body.append(f'    newobj instance void {ctx["il_type_str"](ta, ctx.get("records"))}::.ctor()')
    ctx['store_var'](stmt['name'], scope, body)


def codegen_list_append(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst.append(x)' (x co the la 1 bien container
    khac khi lst la List long nhau, Wave 2 2026-07-29)."""
    _, _, ta = scope[stmt['name']]
    ctx['load_var_ref'](stmt['name'], scope, body)
    ctx['compile_expr'](stmt['value_node'], scope, body, ta.dtype, ctx)
    body.append(f'    callvirt instance void {ctx["il_type_str"](ta, ctx.get("records"))}::Add(!0)')


def find_first_append_dtype(stmts, name, infer_scope, ctx, kind='list_append'):
    """Tim LAN GOI '.append(...)' (hoac '.add(...)' cho set, `kind=
    'set_add'`) DAU TIEN tren list/set `name` (duyet CA cay, ke ca long
    trong for/if/while) va suy dtype phan tu tu gia tri do - can THIET
    vi 'lst = []'/'s = set()' KHONG mang thong tin dtype (giu dung cu
    phap Python that, khong bia syntax rieng). Best-effort: neu gia tri
    tham chieu bien CHUA duoc khai bao (tham chieu xuoi hiem gap), tra
    ve None (caller se fallback ve body_dtype). Dung ctx['infer_dtype']/
    ctx['contains_float_literal']/ctx['int_dtypes'] (tiem tu core - xem
    _fpp_ctx trong il_codegen.py) vi suy dtype la logic core, KHONG the
    import truc tiep (circular import)."""
    func_table, records = ctx.get('func_table'), ctx.get('records')
    for stmt in stmts:
        if stmt['kind'] == kind and stmt['name'] == name:
            try:
                # record_methods (2026-08-03): thieu no thi
                # 'toks.append(lx.next_tok())' KHONG suy duoc kieu tra ve
                # cua method record -> roi ve body_dtype (vd 'str') ->
                # list bi khai bao List<string> trong khi THAT SU chua
                # record. Cung LOAI bug voi 2 ghi chu ben duoi.
                d = ctx['infer_dtype'](stmt['value_node'], infer_scope, func_table, records,
                                       ctx.get('record_methods'))
            except KeyError:
                return None
            # Bug that tim thay 2026-07-28 (giong het loai da vay cho
            # 'compare'/dict): '.append(i * 1.0)' voi 'i' la bien i32 va
            # '1.0' la hang so float LONG trong 1 binop - infer_dtype
            # short-circuit tren 'i' truoc, bo lo hang so float, khien
            # list bi khai bao List<i32> thay vi List<f32> -> codegen
            # sau do ep '1.0' thanh 'ldc.i4 1.0' (loi cu phap ILASM that).
            if d in ctx['int_dtypes'] and ctx['contains_float_literal'](stmt['value_node']):
                d = 'f32'
            # Bug that KHAC tim thay 2026-07-29 (giong het loai da vay cho
            # dict-value, xem _infer_literal_dtype trong il_codegen.py):
            # '.append(1)' voi '1' la hang so KHONG dtype co dinh (infer_dtype
            # tra None co y) trong 1 HAM TRA VE 'str' (vd dumps_int_list()
            # -> "str") truoc day roi thang ve ctx['body_dtype']='str' ->
            # IL_LDC_OP['str'] KeyError luc codegen (khong co ma lenh 'ldc'
            # cho string). Thu doan CHINH cu phap hang so (co dau '.' hay
            # khong) TRUOC KHI roi vao body_dtype.
            return d or ctx['infer_literal_dtype'](stmt['value_node'])
        for sub_key in ('body', 'else_body'):
            sub = stmt.get(sub_key)
            if sub:
                found = find_first_append_dtype(sub, name, infer_scope, ctx, kind)
                if found:
                    return found
    return None


def find_first_append_elem_ta(stmts, name, infer_scope, kind='list_append'):
    """Container long nhau (Wave 2, 2026-07-29): giong find_first_append_dtype
    nhung tra ve TypeAnn DAY DU cua gia tri append/add DAU TIEN, CHI khi
    gia tri do la 1 BIEN tham chieu THANG 1 container KHAC (list/dict) -
    dung de declare_list biet phan tu cua 'lst' co phai CHINH NO la 1
    List/Dict khac hay khong (khong the bieu dien bang 1 dtype string
    don nhu truong hop vo huong/record). Tra None khi khong tim thay HOAC
    gia tri DAU TIEN khong phai container (khi do find_first_append_dtype
    (goi RIENG, khong o day) xu ly truong hop vo huong/record nhu cu).

    GIOI HAN THU TU DA BIET (xac nhan qua test that): bien duoc THAM
    CHIEU (vd 'inner' trong 'outer.append(inner)') PHAI duoc khai bao
    ('inner = []'/'inner = {}') o dong VAN BAN dung TRUOC dong khai bao
    'outer' - vi infer_scope duoc dien DAN theo thu tu WALK (khong phai
    lookahead toan cuc du ham nay tu no CO quet ca cay `stmts`), giong
    het gioi han da ghi nhan cho dtype khoa cua dict (xem STATUS.md).
    Sai thu tu se khien 'outer' bi suy NHAM thanh list vo huong (KHONG
    bao loi im lang - loi ro rang se lo ra sau o _expr_index khi doc lai
    phan tu, xem il_codegen.py)."""
    for stmt in stmts:
        if stmt['kind'] == kind and stmt['name'] == name:
            vn = stmt['value_node']
            if vn[0] == 'var':
                try:
                    _, _, var_ta = infer_scope[vn[1]]
                except KeyError:
                    return None
                if var_ta.shape in ('list', 'dict'):
                    return var_ta
            return None
        for sub_key in ('body', 'else_body'):
            sub = stmt.get(sub_key)
            if sub:
                found = find_first_append_elem_ta(sub, name, infer_scope, kind)
                if found is not None:
                    return found
    return None


def _params_of_call(call_node, ctx):
    """Danh sach Param cua ham/method ma 'call_node' goi toi (None neu
    khong tra cuu duoc)."""
    func_table = ctx.get('func_table') or {}
    if call_node[0] == 'call':
        sig = func_table.get(call_node[1])
        return sig.params if sig is not None else None
    if call_node[0] == 'method_call':
        record_methods = ctx.get('record_methods') or {}
        try:
            obj_ta = ctx['infer_scope'][call_node[1]][2]
        except KeyError:
            return None
        methods = record_methods.get(obj_ta.dtype) or {}
        sig = methods.get(call_node[2])
        return sig.params if sig is not None else None
    return None


def _scan_nodes_for_arg_use(node, name, ctx):
    """Tim 'name' xuat hien lam DOI SO cua 1 loi goi trong cay bieu thuc
    'node'; tra ve dtype phan tu khai bao cua tham so tuong ung."""
    if not isinstance(node, tuple):
        return None
    if node and node[0] in ('call', 'method_call'):
        args = node[2] if node[0] == 'call' else node[3]
        params = _params_of_call(node, ctx)
        if params is not None:
            for i in range(min(len(args), len(params))):
                a = args[i]
                if isinstance(a, tuple) and a[0] == 'var' and a[1] == name:
                    ta = params[i].type_ann
                    if ta is not None and ta.shape == 'list':
                        return ta.dtype
    for sub in node:
        if isinstance(sub, tuple):
            found = _scan_nodes_for_arg_use(sub, name, ctx)
            if found:
                return found
        elif isinstance(sub, list):
            for item in sub:
                found = _scan_nodes_for_arg_use(item, name, ctx)
                if found:
                    return found
    return None


def _elem_dtype_from_arg_use(stmts, name, ctx):
    """Duyet CA cay cau lenh, tim lan dau 'name' duoc TRUYEN lam doi so
    cho 1 ham/method co khai bao tham so 'list[T]' -> tra ve T."""
    for stmt in stmts:
        for key in ('rhs_node', 'expr_node', 'value_node', 'call_node', 'cond_node'):
            node = stmt.get(key)
            if node is not None:
                found = _scan_nodes_for_arg_use(node, name, ctx)
                if found:
                    return found
        for sub_key in ('body', 'else_body', 'finally_body'):
            sub = stmt.get(sub_key)
            if sub:
                found = _elem_dtype_from_arg_use(sub, name, ctx)
                if found:
                    return found
        for _exc, handler_body in stmt.get('handlers') or []:
            found = _elem_dtype_from_arg_use(handler_body, name, ctx)
            if found:
                return found
    return None


def _has_append_stmt(stmts, name, kind):
    """Co bat ky '<name>.append(...)' / '<name>.add(...)' nao trong cay
    cau lenh khong - phan biet 'container rong suot doi' (kieu phan tu
    khong quan sat duoc VA khong anh huong gi) voi 'co manh moi nhung
    chua suy duoc' (phai hoan lai hoac bao loi)."""
    for stmt in stmts:
        if stmt['kind'] == kind and stmt.get('name') == name:
            return True
        for sub_key in ('body', 'else_body', 'finally_body'):
            sub = stmt.get(sub_key)
            if sub and _has_append_stmt(sub, name, kind):
                return True
        for _exc, handler_body in stmt.get('handlers') or []:
            if _has_append_stmt(handler_body, name, kind):
                return True
    return False


def declare_list(name, ctx):
    """FIRST_PASS_WALK helper: khai bao local List<T> - dtype phan tu suy
    tu find_first_append_dtype. `ctx` o day la walk_ctx (xem il_codegen.py
    _first_pass_collect_locals) - CHUA them 'infer_dtype'/'contains_float_literal'/
    'int_dtypes'/'stmts' (tiem lien tu core, xem noi goi ham nay).

    Wave 2 (2026-07-29): thu tim container long nhau TRUOC (xem
    find_first_append_elem_ta) - neu lan '.append(...)' DAU TIEN tren
    'name' la 1 bien list/dict khac, 'name' tro thanh List<List<T>>/
    List<Dict<K,V>> (elem_ta = TypeAnn DAY DU cua bien do); nguoc lai
    (append gia tri vo huong/record nhu cu) roi ve nhanh CU khong doi."""
    declared_names = ctx['declared_names']
    if name in declared_names:
        return
    hint = (ctx.get('container_arg_hints') or {}).get(name)
    if hint is not None and hint.shape == 'list' and hint.elem_ta is None:
        # Chu thich TUONG MINH (tham so cua ham duoc goi, hoac kieu tra ve
        # cua chinh ham nay) thang phong doan tu lan '.append()' dau tien -
        # xem _container_arg_hints trong il_codegen.py. Chi ap dung cho
        # list phan tu VO HUONG (elem_ta None): container long nhau van do
        # find_first_append_elem_ta lo, no chinh xac hon.
        declared_names.add(name)
        ctx['locals_decl'].append((name, hint))
        ctx['infer_scope'].set(name, hint)
        return
    nested_ta = find_first_append_elem_ta(ctx['stmts'], name, ctx['infer_scope'])
    if nested_ta is not None:
        ta = ctx['TypeAnn']('__nested__', 'list', elem_ta=nested_ta)
    else:
        elem_dtype = (find_first_append_dtype(ctx['stmts'], name, ctx['infer_scope'], ctx)
                      # 2026-08-03: list KHONG duoc append trong CHINH ham
                      # nay ma chi TRUYEN cho ham/method khac ('vals = []'
                      # roi 'store.assign(names, vals, ...)') - suy kieu
                      # phan tu tu KHAI BAO THAM SO cua noi nhan. Truoc
                      # day roi thang ve body_dtype -> List<string> cho 1
                      # list THAT SU chua so, sai am tham.
                      or _elem_dtype_from_arg_use(ctx['stmts'], name, ctx))
        if elem_dtype is None and not _has_append_stmt(ctx['stmts'], name, 'list_append'):
            # KHONG co '.append(...)' nao trong ca ham -> list RONG suot
            # doi (vd 'lst = []' roi 'json_dumps(lst)'): kieu phan tu
            # khong the quan sat duoc VA cung khong anh huong ket qua.
            # Chon 1 kieu trung tinh thay vi doan theo kieu tra ve cua ham.
            elem_dtype = 'i32'
        if elem_dtype is None and not ctx.get('final_pass'):
            # Manh moi co the nam o 1 bien khai bao SAU (vd bien vong lap)
            # - hoan lai, thu lai sau khi di het than ham.
            ctx['defer'](lambda: declare_list(name, ctx))
            return
        if elem_dtype is None:
            raise SyntaxError(
                f"il_codegen: khong suy duoc kieu PHAN TU cua list {name!r} - hay cho 1 "
                f"manh moi ('{name}.append(<gia tri co kieu ro rang>)' truoc, hoac truyen "
                f"'{name}' cho 1 ham co khai bao tham so 'list[...]'). TRUOC 2026-08-03 cho "
                f"nay am tham lay kieu TRA VE cua ham dang bien dich - nguon cua 5 bug sai "
                f"am tham trong 1 phien.")
        ta = ctx['TypeAnn'](elem_dtype, 'list')
    declared_names.add(name)
    ctx['locals_decl'].append((name, ta))
    ctx['infer_scope'].set(name, ta)


def fpw_assign_list_new(stmt, ctx):
    declare_list(stmt['name'], ctx)


def declare_list_literal(name, elements, ctx):
    """FIRST_PASS_WALK helper: khai bao local List<T> cho 'xs = [3, 1, 2]'
    (Giai doan 0.1, 2026-08-03) - dtype phan tu suy THANG tu chinh cac
    phan tu literal (KHONG can quet '.append()' sau do nhu declare_list).
    Widen ve float NEU BAT KY phan tu nao la float (Python that: [1, 2.0]
    la list[float]) - giong het logic widen da co cho '.append()' dau
    tien trong find_first_append_dtype."""
    declared_names = ctx['declared_names']
    if name in declared_names:
        return
    declared_names.add(name)
    infer_scope = ctx['infer_scope']
    hint = (ctx.get('container_arg_hints') or {}).get(name)
    if hint is not None and hint.shape == 'list':
        # Chu thich cua ham nhan thang phong doan tu hang so - xem
        # _container_arg_hints trong il_codegen.py.
        ctx['locals_decl'].append((name, hint))
        infer_scope.set(name, hint)
        return
    func_table, records = ctx.get('func_table'), ctx.get('records')
    elem_dtype = None
    for el in elements:
        try:
            d = ctx['infer_dtype'](el, infer_scope, func_table, records,
                                   ctx.get('record_methods'))
        except KeyError:
            d = None
        if d in ctx['int_dtypes'] and ctx['contains_float_literal'](el):
            d = 'f32'
        d = d or ctx['infer_literal_dtype'](el)
        if elem_dtype is None or (elem_dtype not in ('f32', 'f64') and d in ('f32', 'f64')):
            elem_dtype = d
    ta = ctx['TypeAnn'](elem_dtype, 'list')
    ctx['locals_decl'].append((name, ta))
    ctx['infer_scope'].set(name, ta)


def fpw_assign_list_literal(stmt, ctx):
    declare_list_literal(stmt['name'], stmt['elements'], ctx)
    for el in stmt['elements']:
        ctx['collect_ternary_temps'](el)


def codegen_assign_list_literal(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'xs = [3, 1, 2]' (Giai doan 0.1, 2026-08-03) -
    tai dung 100% codegen_assign_list_new (newobj + store) roi codegen_list_append
    tung phan tu (tuong duong 'xs = []' + N lan '.append()'), khong viet
    lai logic newobj/Add rieng - dung nguyen tac DRY."""
    codegen_assign_list_new(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn)
    for el in stmt['elements']:
        codegen_list_append({'kind': 'list_append', 'name': stmt['name'], 'value_node': el},
                             scope, body, body_dtype, ctx, sig, codegen_stmts_fn)


def fpw_list_append(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['value_node'])


_LIST_REMOVE_RE = re.compile(r'^(\w+)\.remove\((.+)\)\s*$')
_LIST_INSERT_RE = re.compile(r'^(\w+)\.insert\(\s*(.+?)\s*,\s*(.+)\s*\)\s*$')


def try_parse_list_remove(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'lst.remove(x)' - PHAI dang ky TRUOC
    method_call_stmt (pattern method-call tong quat cung khop dong nay),
    giong list_append. 2026-07-29 (Huong A stdlib mo rong, khi them
    set.remove() o set_methods_batch2.py): them dieu kien loai tru
    known_shapes=='set' - regex 'x.remove(...)' giong het set.remove(),
    NEU KHONG loai tru se cuop mat luon moi loi goi set.remove() (LINE_PARSERS
    la list thu THEO THU TU dang ky, file nay import TRUOC nen luon thang
    neu khong co dieu kien nay)."""
    m = _LIST_REMOVE_RE.match(line)
    if not m or known_shapes.get(m.group(1)) in ('set', 'frozenset', 'bytearray'):
        return None
    name, arg_expr = m.groups()
    return {'kind': 'list_remove', 'name': name, 'value_node': parse_expr(arg_expr)}, pos + 1


def codegen_list_remove(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst.remove(x)' - xoa phan tu DAU TIEN khop
    gia tri x. GIOI HAN DA BIET: Python list.remove() nem ValueError neu
    khong tim thay x; .NET List<T>.Remove(T) chi tra ve bool (khong nem
    loi) - o day CHAP NHAN hanh vi .NET (bo qua gia tri bool tra ve qua
    'pop'), KHONG gia lap ValueError."""
    _, _, ta = scope[stmt['name']]
    ctx['load_var_ref'](stmt['name'], scope, body)
    ctx['compile_expr'](stmt['value_node'], scope, body, ta.dtype, ctx)
    body.append(f'    callvirt instance bool {ctx["il_type_str"](ta, ctx.get("records"))}::Remove(!0)')
    body.append('    pop')


def fpw_list_remove(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['value_node'])


def try_parse_list_insert(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """LINE_PARSERS entry: 'lst.insert(i, x)' - PHAI dang ky TRUOC
    method_call_stmt, giong list_append/list_remove."""
    m = _LIST_INSERT_RE.match(line)
    if not m or known_shapes.get(m.group(1)) == 'bytearray':
        return None
    name, idx_expr, val_expr = m.groups()
    return {'kind': 'list_insert', 'name': name, 'index_node': parse_expr(idx_expr),
            'value_node': parse_expr(val_expr)}, pos + 1


def codegen_list_insert(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN entry: 'lst.insert(i, x)' - List<T>.Insert(int32, !0)."""
    _, _, ta = scope[stmt['name']]
    ctx['load_var_ref'](stmt['name'], scope, body)
    ctx['compile_expr'](stmt['index_node'], scope, body, 'i32', ctx)
    ctx['compile_expr'](stmt['value_node'], scope, body, ta.dtype, ctx)
    body.append(f'    callvirt instance void {ctx["il_type_str"](ta, ctx.get("records"))}::Insert(int32, !0)')


def fpw_list_insert(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['index_node'])
    ctx['collect_ternary_temps'](stmt['value_node'])


# Dang ky vao il_dispatch NGAY LUC MODULE NAP (il_dispatch.py khong phu
# thuoc il_codegen.py nen import truc tiep an toan, khong circular).
register_assign_rhs_parser('list_literal', try_rhs_list_literal)
register_line_parser('list_append', try_parse_list_append)
register_line_parser('list_remove', try_parse_list_remove)
register_line_parser('list_insert', try_parse_list_insert)
register_stmt_codegen('assign_list_new', codegen_assign_list_new)
register_stmt_codegen('assign_list_literal', codegen_assign_list_literal)
register_stmt_codegen('list_append', codegen_list_append)
register_stmt_codegen('list_remove', codegen_list_remove)
register_stmt_codegen('list_insert', codegen_list_insert)
register_first_pass_walk('assign_list_new', fpw_assign_list_new)
register_first_pass_walk('assign_list_literal', fpw_assign_list_literal)
register_first_pass_walk('list_append', fpw_list_append)
register_first_pass_walk('list_remove', fpw_list_remove)
register_first_pass_walk('list_insert', fpw_list_insert)


def fpw_for_in_call_list(stmt, ctx):
    """FIRST_PASS_WALK cho 'for x in f(...):' khi f tra ve 1 LIST thuong
    (2026-08-03, dot 2) - khai bao 1 local AN giu ket qua loi goi, 1 local
    dem, va bien vong lap."""
    sig = ctx['func_table'][stmt['callee_name']]
    TypeAnn = ctx['TypeAnn']
    ret_ta = sig.return_type
    ctx['declare_named'](f'__forsrc{id(stmt)}', ret_ta)
    ctx['declare_named'](f'__foridx{id(stmt)}', TypeAnn('i32', None))
    # Task 3 review fix thu 4 (extern-class-list, 2026-08-18): doi xung voi
    # declare_scalar/_fpp_assign_scalar (il_codegen.py) - 'for x in f(...):'
    # khi f() tra ve list[HandleType] phai suy shape='extern_class' cho 'x',
    # khong chi biet nhanh 'record'. Thieu nhanh nay -> shape=None ->
    # il_type_str's nhanh shape=None tra IL_SCALAR[dtype] -> KeyError, va
    # 'x.method()'/'x.field' sau do tra cuu SAI (khong dung extern-class).
    extern_class_defs = ctx.get('extern_class_defs')
    if extern_class_defs and ret_ta.dtype in extern_class_defs:
        elem_shape = 'extern_class'
    elif ctx.get('records') and ret_ta.dtype in ctx['records']:
        elem_shape = 'record'
    else:
        elem_shape = None
    ctx['declare_named'](stmt['var'], TypeAnn(ret_ta.dtype, elem_shape))
    for arg_node in stmt['arg_nodes']:
        ctx['collect_ternary_temps'](arg_node)
    ctx['walk_fn'](stmt['body'])


def codegen_for_in_call_list(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN cho 'for x in f(...):' (f tra ve list) - goi ham 1 LAN,
    do ket qua vao 1 local an, roi lap theo chi so nhu 'for x in bien:'."""
    callee = ctx['func_table'][stmt['callee_name']]
    compile_expr = ctx['compile_expr']
    il_type_str = ctx['il_type_str']
    records = ctx.get('records')
    _, src_idx, src_ta = scope[f'__forsrc{id(stmt)}']
    _, idx_idx, _ = scope[f'__foridx{id(stmt)}']
    list_type = il_type_str(src_ta, records)

    for arg_node, p in zip(stmt['arg_nodes'], callee.params):
        compile_expr(arg_node, scope, body, p.type_ann.dtype, ctx)
    params_il = ', '.join(il_type_str(p.type_ann, records) for p in callee.params)
    class_name = ctx.get('class_name') or 'Program'
    ret_il = il_type_str(callee.return_type, records)
    body.append(f"    call {ret_il} {class_name}::{ctx['il_ident'](stmt['callee_name'])}({params_il})")
    body.append(f'    stloc.s {src_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_FCL{n}_start"
    cont_lbl = f"{ctx['prefix']}_FCL{n}_cont"
    end_lbl = f"{ctx['prefix']}_FCL{n}_end"
    body.append('    ldc.i4.0')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'  {start_lbl}:')
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    ldloc.s {src_idx}')
    body.append(f'    callvirt instance int32 {list_type}::get_Count()')
    body.append(f'    bge {end_lbl}')
    body.append(f'    ldloc.s {src_idx}')
    body.append(f'    ldloc.s {idx_idx}')
    body.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')
    ctx['store_var'](stmt['var'], scope, body)
    ctx['loop_stack'].append((cont_lbl, end_lbl))
    codegen_stmts_fn(stmt['body'], scope, body, body_dtype, ctx, sig)
    ctx['loop_stack'].pop()
    body.append(f'  {cont_lbl}:')
    body.append(f'    ldloc.s {idx_idx}')
    body.append('    ldc.i4.1')
    body.append('    add')
    body.append(f'    stloc.s {idx_idx}')
    body.append(f'    br {start_lbl}')
    body.append(f'  {end_lbl}:')


register_stmt_codegen('for_in_call_list', codegen_for_in_call_list)
register_first_pass_walk('for_in_call_list', fpw_for_in_call_list)
