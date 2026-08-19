# -*- coding: utf-8 -*-
"""Closure that (Buoc 4 - "closure that, khong phai function reference hep",
2026-07-29) - xem project-tokenvector-wave2-status memory, phan "checkpoint
tach session" cho toan bo boi canh/risk-analysis/spike da xac minh TRUOC
khi viet file nay.

Slice DAU TIEN (2026-07-29) + slice THU HAI (2026-07-29, nhieu bien bi
bat): CHINH XAC 1 def long / 1 ham ngoai, N>=1 bien bi bat (MOI bien PHAI
la LOCAL cua ham ngoai - gan qua '=' thuong, KHONG phai tham so - khai bao
TRUOC def long trong thu tu van ban nguon), ham long 0+ tham so rieng
kieu scalar. tkv_compile.py's _rewrite_nested_defs() da xu ly truoc: header
'def ten(...) -> "kieu":' bi doi thanh khong dau ngoac kep (giong sig_line
top-level) va dong 'nonlocal x, y, ...' bi xoa (chi la yeu cau cu phap
CPython that, khong can o day) - file nay CHI thay dong 'def ten(...) ->
kieu:' DA duoc doi dang do.

Van CHUA ho tro (danh gia lai o slice sau, xem project-tokenvector-wave2-
status memory): tra closure RA NGOAI ham ngoai (lam gia tri tra ve/tham so
cua ham khac) - closure CHI dung NOI BO trong chinh ham ngoai da tao no;
def long long nhau (nested-nested); bat mang/list/dict/record (chi scalar).

Kien truc (dung LAI toan bo ha tang da xac minh qua spike THAT
probe_closure.il - xem memory): 1 REFERENCE TYPE nho ("cell", 1 field 'v')
cho MOI bien bi bat - dung CHUNG theo dtype tren CA chuong trinh (xem
_cell_class_name trong il_codegen.py); 1 REFERENCE TYPE khac ("closure")
MOI diem 'def long', giu tham chieu toi cac cell no bat, co 1 instance
method la than ham long that su; goi qua bien dung 'ldftn instance ... +
newobj Func`N::.ctor(object, native int)' (GIONG Buoc 2 function reference
nhung KHONG ldnull ma nap THE HIEN closure that)."""
from typed_dsl_parser import parse_typed_signature
from il_dispatch import register_line_parser, register_first_pass_walk, register_stmt_codegen


def try_parse_nested_def(line, lines, pos, indent_level, sig, known_shapes, parse_block_fn):
    """Nhan dien 1 dong 'def ten(...) -> kieu:' (DA duoc tkv_compile.py's
    _rewrite_nested_defs() doi ve dang khong dau ngoac kep, giong het quy
    uoc sig_line top-level) NGAY BEN TRONG than 1 ham khac - phan con lai
    (sau 'def ') parse duoc THANG qua parse_typed_signature (tai dung toan
    bo tokenizer/parser co san, khong phat minh cu phap moi)."""
    if not line.startswith('def '):
        return None
    nested_sig = parse_typed_signature(line[len('def '):])
    pos += 1
    if pos >= len(lines) or lines[pos][0] <= indent_level:
        raise SyntaxError(f"il_codegen: 'def {nested_sig.name}(...):' khong co than khoi (block rong)")
    body, pos = parse_block_fn(lines, pos, lines[pos][0], nested_sig, {})
    return {'kind': 'nested_def', 'nested_sig': nested_sig, 'body': body}, pos


def _collect_var_names(node, names):
    """Duyet DE QUY 1 node bieu thuc (tuple dang ('tag', ...con)) thu thap
    MOI ten bien ('var', ten) xuat hien o BAT KY do sau nao - tong quat
    (khong can biet tung tag cu the) vi MOI node con sau vi tri 0 (tag)
    deu la 1 con (tuple/list/scalar) co the duyet tiep.

    B3 (Phase C.1, 2026-07-29): node 'call' la ('call', ten_ham, args) -
    ten_ham la 1 CHUOI THO (khong boc trong ('var', ten)) nen truoc gio bi
    BO SOT hoan toan khoi phan tich bien tu do - vd 'return f(x)' (goi 1
    THAM SO/local kieu 'func' TRUC TIEP lam callee) khong bao gio thay 'f'
    la ung vien capture. Them ten_ham vao 'names' nhu 1 UNG VIEN (an toan:
    loc loi da co san o fpw_nested_def CHI giu lai ten nao THAT SU nam
    trong declared_names cua ham ngoai - ten ham toan cuc/toan hoc thuong
    (len/sqrt/ham top-level khac) se tu dong bi loai vi khong trung ten
    bien nao da khai bao)."""
    if isinstance(node, tuple):
        if node and node[0] == 'var':
            names.add(node[1])
            return
        if node and node[0] == 'call' and isinstance(node[1], str):
            names.add(node[1])
        for child in node[1:]:
            _collect_var_names(child, names)
    elif isinstance(node, list):
        for child in node:
            _collect_var_names(child, names)


def _collect_stmt_var_names(stmts, names):
    """Duyet 1 danh sach Stmt (dict co key 'kind') thu thap MOI ten bien
    THAM CHIEU (doc) LAN GAN (target) xuat hien - dung de phan tich bien tu
    do (Buoc 4, muc 3 trong checkpoint): SO SANH voi bien da khai bao o ham
    NGOAI, KHONG can cu phap 'nonlocal' rieng o tang nay (da bi
    tkv_compile.py xoa truoc do, chi la yeu cau cu phap CPython)."""
    for stmt in stmts:
        if not isinstance(stmt, dict):
            continue
        for key, val in stmt.items():
            if key == 'kind':
                continue
            if key == 'name' and isinstance(val, str):
                names.add(val)
                continue
            if isinstance(val, list) and val and isinstance(val[0], dict) and 'kind' in val[0]:
                _collect_stmt_var_names(val, names)  # 'body'/'else_body' - 1 khoi Stmt long nhau
            elif isinstance(val, (list, tuple)):
                for item in val:
                    _collect_var_names(item, names)
            elif isinstance(val, tuple):
                _collect_var_names(val, names)


def fpw_nested_def(stmt, ctx):
    """First-pass-walk cho kind='nested_def' - phan tich bien tu do (Buoc 4
    muc 3) NGAY tai day (ctx['declared_names'] dung luc nay CHINH LA tap
    bien cua ham ngoai da khai bao TRUOC do trong thu tu van ban nguon -
    dung vi walk() xu ly stmts THEO DUNG THU TU nguon), roi dang ky
    metadata closure (muc 4+5) vao stmt/ctx de _stmt codegen (STMT_CODEGEN)
    va _expr_call (il_codegen.py) dung sau.

    Slice thu hai (2026-07-29): N>=1 bien bi bat (KHONG con gioi han =1) -
    danh sach `stmt['captures']` giu THU TU ON DINH (sorted theo ten) de
    ca .ctor cua closure class VA diem goi newobj (codegen_nested_def) sinh
    tham so THEO DUNG 1 THU TU duy nhat, khong lech nhau."""
    nested_sig = stmt['nested_sig']
    nested_stmts = stmt['body']
    outer_sig = ctx['sig']

    param_names = {p.name for p in nested_sig.params}
    all_names = set()
    _collect_stmt_var_names(nested_stmts, all_names)
    candidates = all_names - param_names
    captured = sorted(n for n in candidates if n in ctx['declared_names'])

    if not captured:
        raise SyntaxError(
            f"il_codegen: ham long '{nested_sig.name}' khong bat bien nao tu ham ngoai "
            f"'{outer_sig.name}' - neu chi can truyen 1 ham nhu 1 gia tri, dung 'function "
            f"reference' (tham so kieu 'func', xem Wave 3), khong can closure that")

    outer_param_names = {p.name for p in outer_sig.params}
    captures = []
    for captured_name in captured:
        captured_ta = ctx['infer_scope'][captured_name][2]
        is_param = captured_name in outer_param_names
        if captured_ta.shape is None:
            # Scalar - CHI ho tro bat 1 LOCAL (co che cell/boxed cu, Buoc 4) -
            # bat 1 THAM SO scalar van chua ho tro (can 1 co che box-tai-
            # entry rieng cho tham so, ngoai pham vi b3 - xem ghi chu B3
            # ben duoi).
            if is_param:
                raise SyntaxError(
                    f"il_codegen: bien bi bat '{captured_name}' la THAM SO VO HUONG cua ham "
                    f"ngoai '{outer_sig.name}' - closure that CHI ho tro bat THAM SO neu no la "
                    f"kieu THAM CHIEU (list/dict/set/tuple/record/func - xem B3), tham so VO "
                    f"HUONG van CHI bat duoc qua 1 LOCAL (gan qua '=')")
            cell_class = ctx['cell_class_name'](captured_ta.dtype)
            captures.append((captured_name, captured_ta, cell_class, 'boxed'))
        else:
            # B3 (2026-07-29, xem project-tokenvector-wave2-status memory):
            # kieu THAM CHIEU (list/dict/set/tuple/record/refclass/func) DA
            # LA reference-type san trong CIL - KHONG can boxing/cell nhu
            # scalar (chia se-qua-tham-chieu co san), bat TRUC TIEP (field
            # giu THANG gia tri) - ho tro CA local LAN tham so cua ham ngoai
            # (dung cho pattern "nhan 1 callback 'func', tra ve 1 closure
            # dung callback do", vd 'compose(f)'). Gioi han da biet: neu
            # bien nay bi GAN LAI (=) SAU khi closure duoc tao, closure GIU
            # THAM CHIEU CU (khong co cell chia se như scalar) - it gap
            # trong thuc te (thuong chi doc, khong gan lai callback).
            captures.append((captured_name, captured_ta, None, 'direct'))

    closure_class = f"{outer_sig.name}__{nested_sig.name}__Closure"

    for captured_name, _, _, mode in captures:
        if mode == 'boxed':
            # CHI local moi vao boxed_names (param 'direct' KHONG bao gio o
            # day - gia tri THANG doc qua ldarg binh thuong, khong box).
            ctx['boxed_names'].add(captured_name)
    stmt['captures'] = captures
    stmt['closure_class'] = closure_class

    hidden_local = f'__closure_{nested_sig.name}'
    closure_ta = ctx['TypeAnn'](closure_class, 'refclass')
    ctx['declare_named'](hidden_local, closure_ta)
    stmt['hidden_local'] = hidden_local

    ctx['nested_closures'][nested_sig.name] = {
        'closure_class': closure_class, 'hidden_local': hidden_local, 'nested_sig': nested_sig,
    }


def _gen_cell_class_il(cell_class, il_type):
    return [
        f'.class public auto ansi {cell_class} extends [mscorlib]System.Object',
        '{',
        f'  .field public {il_type} v',
        '  .method public hidebysig specialname rtspecialname instance void '
        f'.ctor({il_type} v0) cil managed',
        '  {',
        '    .maxstack 8',
        '    ldarg.0',
        '    call instance void [mscorlib]System.Object::.ctor()',
        '    ldarg.0',
        '    ldarg.1',
        f'    stfld {il_type} {cell_class}::v',
        '    ret',
        '  }',
        '}',
    ]


def _gen_closure_class_il(closure_class, captures, nested_sig, nested_stmts, ctx):
    """captures: list[(ten_bien, TypeAnn, ten_cell_class_hoac_None, mode)]
    THEO 1 THU TU CO DINH (xem fpw_nested_def) - mode='boxed' (scalar, field
    kieu 'class {cell_class}', xem _gen_cell_class_il) hoac mode='direct'
    (B3, 2026-07-29 - kieu THAM CHIEU nhu list/dict/record/func, field GIU
    THANG gia tri, kieu field = il_type_str(ta) - KHONG can cell). MOI bien
    bi bat la 1 field rieng, .ctor nhan DU tham so THEO DUNG thu tu do
    (giong pattern .ctor nhieu tham so cua record/tuple da co san)."""
    il_type_str = ctx['il_type_str']
    records = ctx.get('records')

    def _field_il_type(ta, cell_class, mode):
        return f'class {cell_class}' if mode == 'boxed' else il_type_str(ta, records)

    ctor_params_il = ', '.join(f'{_field_il_type(ta, cclass, mode)} {name}'
                               for name, ta, cclass, mode in captures)
    lines = [
        f'.class public auto ansi {closure_class} extends [mscorlib]System.Object',
        '{',
    ]
    for name, ta, cclass, mode in captures:
        lines.append(f'  .field public {_field_il_type(ta, cclass, mode)} {name}')
    lines.append('  .method public hidebysig specialname rtspecialname instance void '
                 f'.ctor({ctor_params_il}) cil managed')
    lines.append('  {')
    lines.append('    .maxstack 8')
    lines.append('    ldarg.0')
    lines.append('    call instance void [mscorlib]System.Object::.ctor()')
    for i, (name, ta, cclass, mode) in enumerate(captures):
        lines.append('    ldarg.0')
        lines.append(f'    ldarg.s {i + 1}')
        lines.append(f'    stfld {_field_il_type(ta, cclass, mode)} {closure_class}::{name}')
    lines.append('    ret')
    lines.append('  }')
    closure_captures = [
        (name, ta, closure_class, None if mode == 'boxed' else il_type_str(ta, records))
        for name, ta, cclass, mode in captures
    ]
    method_lines = ctx['gen_il_function'](
        nested_sig, None, with_guards=False, func_table=ctx['func_table'],
        class_name=ctx['class_name'], records=ctx['records'], self_type_ann=None,
        record_methods=ctx['record_methods'], closure_captures=closure_captures,
        is_closure_method=True, extra_classes=ctx['extra_classes'],
        emitted_types=ctx['emitted_types'], pre_parsed_stmts=nested_stmts)
    lines.extend(method_lines)
    lines.append('}')
    return lines


def codegen_nested_def(stmt, scope, body, body_dtype, ctx, sig, codegen_stmts_fn):
    """STMT_CODEGEN cho 'nested_def' - (a) sinh (1 lan/chuong trinh, dedupe
    qua ctx['emitted_types']) cell class cho MOI dtype bi bat + closure
    class cua chinh 'def long' nay (chua than method, sinh DE QUY qua
    gen_il_function voi pre_parsed_stmts - KHONG parse lai tu text), gom
    vao ctx['extra_classes']; (b) tai DIEM 'def ten():' nay (giong Python
    that - nested def "thuc thi" tao 1 function object MOI gan voi CAC
    cell HIEN CO cua cac bien bi bat), tao 1 THE HIEN closure va luu vao 1
    local an (hidden_local) de cac loi goi 'ten()' sau do (xem _expr_call
    trong il_codegen.py) dung lai."""
    captures = stmt['captures']
    closure_class = stmt['closure_class']
    nested_sig = stmt['nested_sig']
    hidden_local = stmt['hidden_local']

    il_type_str = ctx['il_type_str']
    records = ctx.get('records')

    def _field_il_type(ta, cclass, mode):
        return f'class {cclass}' if mode == 'boxed' else il_type_str(ta, records)

    emitted = ctx['emitted_types']
    for _, captured_ta, cell_class, mode in captures:
        if mode == 'boxed' and cell_class not in emitted:
            emitted.add(cell_class)
            ctx['extra_classes'].append(_gen_cell_class_il(cell_class, ctx['il_scalar'][captured_ta.dtype]))
    if closure_class not in emitted:
        emitted.add(closure_class)
        ctx['extra_classes'].append(_gen_closure_class_il(closure_class, captures, nested_sig, stmt['body'], ctx))

    ctor_params_il = ', '.join(f'{_field_il_type(ta, cclass, mode)} {name}'
                               for name, ta, cclass, mode in captures)
    for captured_name, _, _, mode in captures:
        if mode == 'boxed':
            ctx['load_boxed_cell_ref'](captured_name, scope, body)
        else:
            # B3 (2026-07-29): nap TRUC TIEP gia tri tham chieu (local hoac
            # THAM SO cua ham ngoai deu qua load_var_ref - kind='arg'/'local'
            # deu duoc _load_var_ref ho tro san).
            ctx['load_var_ref'](captured_name, scope, body)
    body.append(f'    newobj instance void {closure_class}::.ctor({ctor_params_il})')
    _, hidden_idx, _ = scope[hidden_local]
    body.append(f'    stloc.s {hidden_idx}')


register_line_parser('nested_def', try_parse_nested_def)
register_first_pass_walk('nested_def', fpw_nested_def)
register_stmt_codegen('nested_def', codegen_nested_def)
