# -*- coding: utf-8 -*-
"""Don chuoi trong vong lap: dung StringBuilder thay vi noi chuoi O(n^2).

VAN DE DA DO DUOC (2026-08-04, cung phien, cung tai may):

    out = out + "x"  trong 'while', so voi CPython chay CHINH doan do:
      n= 20.000   CPython   159 ms   TokenVector   154 ms   hoa
      n= 50.000   CPython   269 ms   TokenVector   574 ms   CPython nhanh 2,1x
      n=100.000   CPython   583 ms   TokenVector  3303 ms   CPython nhanh 5,7x
      n=200.000   CPython  1756 ms   TokenVector 18025 ms   CPython nhanh 10,3x

Khoang cach NOI RONG theo n - dau hieu O(n^2): chuoi .NET BAT BIEN nen moi
phep '+' cap phat va chep lai TOAN BO chuoi. CPython co duong rieng cho
`s += x`: mo rong TAI CHO khi refcount == 1, thanh O(n) khau hao.

Day la mot trong rat it cho TokenVector CHAM HON Python, va no danh thang
vao muc tieu so 1 cua du an. Nguy hiem o cho no IM LANG: ket qua van dung
tung byte, chi la cham gap 10 lan.

PHAM VI CO Y THU HEP (chu du an chot 2026-08-04: "khoan sua rong"):
Bien doi nay ap dung TRONG DUNG MOT VONG LAP, khong doi bieu dien cua bien
o bat ky cho nao khac:

    sb = new StringBuilder(out)      <- truoc vong lap
    while ...:
        sb.Append(<bieu thuc>)       <- thay cho 'out = out + <bieu thuc>'
    out = sb.ToString()              <- sau vong lap

Ngoai vong lap, 'out' van la mot 'string' binh thuong. Nho vay khong phai
dong den moi cho DOC bien - do moi la phan rong, de sau.

DIEU KIEN AN TOAN (thieu MOT dieu la bo qua, giu nguyen cach cu):
  1. Bien co kieu 'str' va la local thuong.
  2. Trong than vong lap, bien CHI xuat hien o dung mot cho: ve trai va
     toan hang trai cua chinh phep don. Doc no o cho khac se thay chuoi
     CHUA duoc dong bo -> sai ket qua, nen tu choi thang.
  3. Than vong lap KHONG co 'return': 'return' thoat ra ma khong chay buoc
     dong bo, bien se giu gia tri cu -> sai am tham. 'break'/'continue'
     thi AN TOAN vi buoc dong bo dat SAU nhan ket thuc vong lap.
  4. Khong co 'nested_def'/'yield': closure co the bat bien, generator cat
     doi luong dieu khien.
"""
from il_dispatch import register_stmt_codegen, register_first_pass_walk

_SB_IL = 'class [mscorlib]System.Text.StringBuilder'


def _walk_stmts(stmts):
    """Duyet DE QUY moi cau lenh, ke ca trong than long nhau."""
    for stmt in stmts or []:
        yield stmt
        for key in ('body', 'else_body', 'finally_body'):
            for sub in _walk_stmts(stmt.get(key)):
                yield sub
        for _exc, handler_body in stmt.get('handlers') or []:
            for sub in _walk_stmts(handler_body):
                yield sub


def _node_refs(node, name):
    """Dem so lan ('var', name) xuat hien trong 1 cay bieu thuc."""
    if not isinstance(node, tuple):
        return 0
    if len(node) == 2 and node[0] == 'var' and node[1] == name:
        return 1
    total = 0
    for part in node:
        if isinstance(part, tuple):
            total += _node_refs(part, name)
        elif isinstance(part, list):
            for sub in part:
                total += _node_refs(sub, name)
    return total


def _is_accum(stmt, name):
    """'name = name + <bieu thuc>' - phep don len chinh no."""
    if stmt.get('kind') != 'assign_scalar' or stmt.get('name') != name:
        return False
    rhs = stmt.get('rhs_node')
    return (isinstance(rhs, tuple) and len(rhs) == 4 and rhs[0] == 'binop'
            and rhs[1] == '+' and isinstance(rhs[2], tuple)
            and len(rhs[2]) == 2 and rhs[2][0] == 'var' and rhs[2][1] == name)


def _candidate_names(body):
    """Ten bien co it nhat mot phep don trong than vong lap."""
    names = []
    for stmt in _walk_stmts(body):
        if stmt.get('kind') != 'assign_scalar':
            continue
        name = stmt.get('name')
        if name and name not in names and _is_accum(stmt, name):
            names.append(name)
    return names


def _body_is_safe(body):
    """Dieu kien 3 va 4 - xem docstring module."""
    for stmt in _walk_stmts(body):
        if stmt.get('kind') in ('return', 'return_tuple', 'nested_def',
                                'yield_stmt'):
            return False
    return True


def _only_used_as_accumulator(body, name):
    """Dieu kien 2: trong than vong lap, 'name' chi xuat hien o dung cho
    toan hang trai cua phep don, khong o dau khac."""
    for stmt in _walk_stmts(body):
        accum = _is_accum(stmt, name)
        for key, node in stmt.items():
            if not (key.endswith('_node') or key == 'rhs_node'):
                continue
            hits = _node_refs(node, name)
            if accum and key == 'rhs_node':
                # Dung mot lan o ve trai cua '+' la hop le; nhieu hon la
                # co doc them o cho khac trong cung bieu thuc.
                if hits != 1:
                    return False
            elif hits:
                return False
        # Bi gan bang mot cach KHAC (vd 'name = f()') -> tu choi.
        if (stmt.get('name') == name and not accum
                and stmt.get('kind', '').startswith('assign')):
            return False
        if stmt.get('var') == name or stmt.get('target') == name:
            return False
    return True


def _declare_sb_locals(names, ctx, infer_scope):
    """Khai bao local StringBuilder an cho tung bien don. Goi lai duoc
    nhieu lan (moi luot mot cua lượt một co 'locals_decl' rieng)."""
    for name in names:
        sb_name = '__sb_' + name
        if sb_name in ctx['declared_names']:
            continue
        ctx['declared_names'].add(sb_name)
        sb_ta = ctx['TypeAnn']('str', 'strbuf')
        ctx['locals_decl'].append((sb_name, sb_ta))
        infer_scope.set(sb_name, sb_ta)


def plan_str_accum(stmt, ctx):
    """Goi tu fpw_for/fpw_while TRUOC khi duyet than vong lap.

    Neu tim duoc bien don an toan: cap phat local StringBuilder, doi cac
    cau lenh don thanh kind 'sb_append', va ghi danh sach vao chinh stmt
    de luc sinh ma biet phai dung khung truoc/sau vong lap.
    """
    body = stmt.get('body')
    if not body:
        return
    infer_scope = ctx['infer_scope']

    # PHAI LUY DANG: lượt một chay NHIEU LAN (co co che hoan lai/defer, xem
    # ctx['final_pass'] trong dict_type.py), moi lan mot 'locals_decl' MOI.
    # Lan dau da doi kind thanh 'sb_append' nen lan sau khong con nhan ra
    # mau nua -> local '__sb_x' khong duoc khai bao lai -> "bien chua duoc
    # khai bao" luc sinh ma. Nen neu da phan tich roi thi chi khai bao lai.
    if '__sb_vars' in stmt:
        _declare_sb_locals(stmt['__sb_vars'], ctx, infer_scope)
        return

    if not _body_is_safe(body):
        return
    chosen = []
    for name in _candidate_names(body):
        try:
            ta = infer_scope[name][2]
        except KeyError:
            continue                      # chua khai bao truoc vong lap
        if ta is None or ta.dtype != 'str' or ta.shape is not None:
            continue
        if not _only_used_as_accumulator(body, name):
            continue
        chosen.append(name)

    if not chosen:
        return
    _declare_sb_locals(chosen, ctx, infer_scope)
    for name in chosen:
        sb_name = '__sb_' + name
        for sub in _walk_stmts(body):
            if _is_accum(sub, name):
                # Dat 'value_node'/'sb_name' TRUOC khi doi 'kind': neu co
                # loi giua chung thi khong de lai cau lenh nua voi (kind
                # moi ma thieu truong) - rat kho truy khi do.
                sub['value_node'] = sub['rhs_node'][3]
                sub['sb_name'] = sb_name
                sub['kind'] = 'sb_append'
    stmt['__sb_vars'] = chosen


def emit_sb_setup(stmt, scope, body, ctx):
    """Truoc vong lap: sb = new StringBuilder(<gia tri hien tai>)."""
    for name in stmt.get('__sb_vars') or []:
        ctx['load_var_ref'](name, scope, body)
        body.append('    newobj instance void '
                    '[mscorlib]System.Text.StringBuilder::.ctor(string)')
        ctx['store_var']('__sb_' + name, scope, body)


def emit_sb_flush(stmt, scope, body, ctx):
    """Sau vong lap: <bien> = sb.ToString() - dong bo lai mot lan duy nhat."""
    for name in stmt.get('__sb_vars') or []:
        ctx['load_var_ref']('__sb_' + name, scope, body)
        body.append('    callvirt instance string '
                    '[mscorlib]System.Object::ToString()')
        ctx['store_var'](name, scope, body)


def codegen_sb_append(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """sb.Append(<bieu thuc>) - thay cho 'x = x + <bieu thuc>'.

    Append tra ve chinh StringBuilder do nen phai 'pop' bo khoi stack."""
    ctx['load_var_ref'](stmt['sb_name'], scope, body)
    ctx['compile_expr'](stmt['value_node'], scope, body, 'str', ctx)
    body.append('    callvirt instance class [mscorlib]System.Text.StringBuilder '
                '[mscorlib]System.Text.StringBuilder::Append(string)')
    body.append('    pop')


def fpw_sb_append(stmt, ctx):
    ctx['collect_ternary_temps'](stmt['value_node'])


register_stmt_codegen('sb_append', codegen_sb_append)
register_first_pass_walk('sb_append', fpw_sb_append)
