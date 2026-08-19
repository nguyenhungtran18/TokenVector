# -*- coding: utf-8 -*-
"""stdlib_http.py - Plug-and-Play module cho HTTP GET/POST via System.Net.WebClient

Cung cap:
- http_get(url) -> str
- http_post(url, payload) -> str            (Content-Type: application/json)
- http_post_type(url, payload, ctype) -> str  (tu chon Content-Type)
- http_put(url, payload, ctype) -> str
- http_delete(url) -> str
- http_get_h/http_post_h/http_put_h/http_delete_h(..., headers) -> str
  (headers: "dict[str,str]" - header TUY Y: Authorization, User-Agent,
  X-API-Key...)

GIAI DOAN 3 (2026-08-03) - "HTTP day du" theo ke hoach: truoc do CHI co
GET + POST voi Content-Type CO DINH 'application/json', khong goi noi
API dung form-urlencoded/text/xml, va khong co PUT/DELETE (2 dong tu bat
buoc cua REST). Tat ca dung CHUNG WebClient::UploadString - da xac minh
THAT chu ky UploadString(string address, string method, string data)
truoc khi viet IL, va kiem chung bang 1 HTTP server THAT chay cuc bo
(test/verify/http_post_test.py doc lai method + Content-Type + body ma
server NHAN DUOC, khong chi "khong crash").

HEADER TUY Y (2026-08-03, cung Giai doan 3, sau khi owner chi ra rang
"chi set duoc Content-Type" tren thuc te chan gan het API that - khong gan
noi 'Authorization: Bearer <token>'): cac ban *_h nhan 1
"dict[str,str]" va set TUNG cap vao WebClient.Headers. Dict duoc chuyen
thanh List<KeyValuePair<string,string>> bang newobj List`1::.ctor(
IEnumerable`1<!0>) - CUNG ky thuat dict.items() da dung (xem
dict_items_list.py), KHONG can Enumerator thu cong. 'Content-Type:
application/json' van duoc set TRUOC vong lap nen dict CO THE ghi de no.

GIOI HAN, ghi ro: khong doc duoc status code/header tra ve (loi HTTP >= 400 NEM exception -
WebException - bat duoc bang 'except Exception:'), khong timeout tuy
chinh, khong upload nhi phan (chi chuoi).

TU 2026-08-03 (Giai doan 0.2 nhom 8): ca hai dang ky qua register_expr_builtin
nen goi duoc o MOI vi tri bieu thuc ('return http_post(u, p)',
'http_get(u) + "!"'). http_post BO HAN duong ASSIGN_RHS_PARSERS/
FIRST_PASS_WALK/STMT_CODEGEN cu (chi chay duoc o RHS 1 phep gan don le, va
tach 2 tham so bang 1 regex greedy - tach NHAM khi url/payload
tu chua dau ','); http_get bo 2 nhanh if/elif rieng trong il_codegen.py
(_expr_call + _infer_dtype). Tham so nay do CHINH parser bieu thuc tach nen
dau ',' trong chuoi "..." khong con lam tach nham."""

from il_dispatch import register_expr_builtin


def compile_http_get(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: http_get(url) chi nhan dung 1 tham so")
    out.append('    newobj instance void [System]System.Net.WebClient::.ctor()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    callvirt instance string [System]System.Net.WebClient::DownloadString(string)')


def _push_upload(args, scope, out, ctx, method, ctype_node):
    """WebClient + Content-Type + UploadString(url, method, data). ctype_node
    = None nghia la dung 'application/json'."""
    out.append('    newobj instance void [System]System.Net.WebClient::.ctor()')
    out.append('    dup')
    out.append('    callvirt instance class [System]System.Net.WebHeaderCollection '
               '[System]System.Net.WebClient::get_Headers()')
    out.append('    ldstr "Content-Type"')
    if ctype_node is None:
        out.append('    ldstr "application/json"')
    else:
        ctx['compile_expr'](ctype_node, scope, out, 'str', ctx)
    out.append('    callvirt instance void [System]System.Net.WebHeaderCollection::Set(string, string)')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append(f'    ldstr "{method}"')
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    out.append('    callvirt instance string '
               '[System]System.Net.WebClient::UploadString(string, string, string)')


def push_http_post(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: http_post(url, payload) can dung 2 tham so "
                          "- muon tu chon Content-Type thi dung http_post_type(url, payload, ctype)")
    _push_upload(args, scope, out, ctx, 'POST', None)


def push_http_post_type(args, scope, out, dtype, ctx):
    if len(args) != 3:
        raise SyntaxError("il_codegen: http_post_type(url, payload, content_type) can dung 3 tham so")
    _push_upload(args, scope, out, ctx, 'POST', args[2])


def push_http_put(args, scope, out, dtype, ctx):
    if len(args) != 3:
        raise SyntaxError("il_codegen: http_put(url, payload, content_type) can dung 3 tham so")
    _push_upload(args, scope, out, ctx, 'PUT', args[2])


def push_http_delete(args, scope, out, dtype, ctx):
    """DELETE khong co than yeu cau -> UploadString voi data rong (dung
    CHUNG duong UploadString thay vi them 1 co che rieng)."""
    if len(args) != 1:
        raise SyntaxError("il_codegen: http_delete(url) chi nhan dung 1 tham so")
    out.append('    newobj instance void [System]System.Net.WebClient::.ctor()')
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    ldstr "DELETE"')
    out.append('    ldstr ""')
    out.append('    callvirt instance string '
               '[System]System.Net.WebClient::UploadString(string, string, string)')


# ---------------------------------------------------------------- header
_KVP_STR = ('valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2'
            '<string, string>')
_LIST_KVP_STR = (f'class [mscorlib]System.Collections.Generic.List`1<{_KVP_STR}>')


def _hdr_temps(node, ctx, prefix):
    """3 bien an cho vong lap set header: danh sach cap, chi so, va 1 o
    chua KeyValuePair (valuetype - can DIA CHI de goi get_Key/get_Value)."""
    args = node[2]
    TypeAnn = ctx['TypeAnn']
    kv_ta = TypeAnn('str', 'dict_kvpair', 'str')
    ctx['declare_named'](f'__{prefix}{id(args)}_items',
                         TypeAnn('str', 'list', elem_ta=kv_ta))
    ctx['declare_named'](f'__{prefix}{id(args)}_i', TypeAnn('i32', None))
    ctx['declare_named'](f'__{prefix}{id(args)}_pair', kv_ta)


def _push_apply_headers(args, hdr_node, scope, out, ctx, prefix):
    """Stack VAO: [WebClient]. Stack RA: [WebClient] (khong doi) - da set
    xong moi header trong dict. Client duoc GIU tren stack xuyen qua vong
    lap: do sau stack tai moi diem hop nhanh la NHU NHAU nen hop le."""
    _, items_idx, _ = scope[f'__{prefix}{id(args)}_items']
    _, i_idx, _ = scope[f'__{prefix}{id(args)}_i']
    _, pair_idx, _ = scope[f'__{prefix}{id(args)}_pair']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    start_lbl = f"{ctx['prefix']}_hdr{n}_start"
    end_lbl = f"{ctx['prefix']}_hdr{n}_end"

    ctx['compile_expr'](hdr_node, scope, out, 'str', ctx)
    out.append(f'    newobj instance void {_LIST_KVP_STR}::.ctor(class '
               '[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    stloc.s {items_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {items_idx}')
    out.append(f'    callvirt instance int32 {_LIST_KVP_STR}::get_Count()')
    out.append(f'    bge {end_lbl}')
    out.append('    dup')
    out.append('    callvirt instance class [System]System.Net.WebHeaderCollection '
               '[System]System.Net.WebClient::get_Headers()')
    out.append(f'    ldloc.s {items_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {_LIST_KVP_STR}::get_Item(int32)')
    out.append(f'    stloc.s {pair_idx}')
    out.append(f'    ldloca.s {pair_idx}')
    out.append(f'    call instance !0 {_KVP_STR}::get_Key()')
    out.append(f'    ldloca.s {pair_idx}')
    out.append(f'    call instance !1 {_KVP_STR}::get_Value()')
    out.append('    callvirt instance void '
               '[System]System.Net.WebHeaderCollection::Set(string, string)')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')


def _make_h_builtin(method, has_body, prefix):
    """Sinh 1 cap (temps_fn, codegen_fn) cho ban *_h cua 1 dong tu HTTP.
    has_body=False (GET/DELETE): (url, headers). True: (url, payload, headers)."""
    argc = 3 if has_body else 2
    sig_txt = ('(url, payload, headers)' if has_body else '(url, headers)')

    def temps_fn(node, ctx):
        _hdr_temps(node, ctx, prefix)

    def codegen_fn(args, scope, out, dtype, ctx):
        if len(args) != argc:
            raise SyntaxError(f'il_codegen: {prefix}{sig_txt} can dung {argc} tham so')
        out.append('    newobj instance void [System]System.Net.WebClient::.ctor()')
        if has_body:
            out.append('    dup')
            out.append('    callvirt instance class [System]System.Net.WebHeaderCollection '
                       '[System]System.Net.WebClient::get_Headers()')
            out.append('    ldstr "Content-Type"')
            out.append('    ldstr "application/json"')
            out.append('    callvirt instance void '
                       '[System]System.Net.WebHeaderCollection::Set(string, string)')
        _push_apply_headers(args, args[argc - 1], scope, out, ctx, prefix)
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        if method == 'GET':
            out.append('    callvirt instance string '
                       '[System]System.Net.WebClient::DownloadString(string)')
            return
        out.append(f'    ldstr "{method}"')
        if has_body:
            ctx['compile_expr'](args[1], scope, out, 'str', ctx)
        else:
            out.append('    ldstr ""')
        out.append('    callvirt instance string '
                   '[System]System.Net.WebClient::UploadString(string, string, string)')

    return temps_fn, codegen_fn


for _name, _method, _has_body in [('http_get_h', 'GET', False),
                                   ('http_post_h', 'POST', True),
                                   ('http_put_h', 'PUT', True),
                                   ('http_delete_h', 'DELETE', False)]:
    _temps, _codegen = _make_h_builtin(_method, _has_body, _name)
    register_expr_builtin(_name, _codegen, 'str', temps_fn=_temps)


register_expr_builtin('http_get', compile_http_get, 'str')
register_expr_builtin('http_post', push_http_post, 'str')
register_expr_builtin('http_post_type', push_http_post_type, 'str')
register_expr_builtin('http_put', push_http_put, 'str')
register_expr_builtin('http_delete', push_http_delete, 'str')
