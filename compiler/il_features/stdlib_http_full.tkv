# -*- coding: utf-8 -*-
"""http_request(method, url, payload, headers) -> dict[str,str] (2026-08-03).

Bit con thieu cuoi cung cua HTTP: DOC DUOC ma trang thai va header TRA VE.
Cac ham http_get/http_post/... dung System.Net.WebClient - lop do KHONG
cho biet status code, va nem WebException voi moi ma >= 400 (chuong trinh
chet thay vi doc duoc "404"). Ham nay dung HttpWebRequest/HttpWebResponse
truc tiep + BAT WebException de van lay duoc response ben trong no.

KET QUA la 1 dict[str,str] (DSL nay chua co cach tra ve 1 record do
builtin dinh nghia). Cac khoa:
    "status"          -> "200" / "404" ...
    "body"            -> than phan hoi (chuoi)
    "header:<ten>"    -> gia tri header TRA VE, <ten> viet THUONG
Vi du: r = http_request("GET", url, "", h) ; code = r["status"]

'method' phai la CHUOI HANG ("GET"/"POST"/...) - co y: trinh bien dich
dua vao no de biet CO ghi than yeu cau hay khong (GET/DELETE/HEAD thi
khong), quyet dinh nay khong the hoan lai toi luc chay.

HEADER HAN CHE cua HttpWebRequest: 4 header pho bien (Content-Type,
Accept, User-Agent, Referer) BAT BUOC dat qua property rieng - dat qua
Headers.Set() se nem ArgumentException. Vong lap sinh ra o day tu re
nhanh cho 4 cai do (so ten da ha thuong luc CHAY). Cac header han che
CON LAI (Host, Connection, Content-Length, Range, Expect, Date,
If-Modified-Since, Transfer-Encoding, Proxy-Connection) VAN se nem loi
neu nguoi dung dat - ghi ro, khong giau.

DA XAC MINH THAT chu ky BCL truoc khi viet IL (PowerShell reflection):
WebRequest::Create(string)->WebRequest, HttpWebRequest::set_Method(string),
GetRequestStream()->Stream, HttpWebResponse::get_StatusCode()->HttpStatusCode,
get_Headers()->WebHeaderCollection, WebResponse::GetResponseStream()->Stream,
WebException::get_Response()->WebResponse, WebHeaderCollection::get_AllKeys()
->string[], ::Get(string)->string, StreamWriter::.ctor(Stream)."""
from il_dispatch import register_expr_builtin
from typed_dsl_parser import TypeAnn

_HTTP_REQ = 'class [System]System.Net.HttpWebRequest'
_HTTP_RESP = 'class [System]System.Net.HttpWebResponse'
_DICT_SS = 'class [mscorlib]System.Collections.Generic.Dictionary`2<string, string>'
_LIST_STR = 'class [mscorlib]System.Collections.Generic.List`1<string>'
_KVP_SS = 'valuetype [mscorlib]System.Collections.Generic.KeyValuePair`2<string, string>'
_LIST_KVP = f'class [mscorlib]System.Collections.Generic.List`1<{_KVP_SS}>'

# Header BAT BUOC dat qua property rieng cua HttpWebRequest (dat qua
# Headers.Set se nem ArgumentException) - ten da ha thuong de so sanh.
_RESTRICTED_SETTERS = [
    ('content-type', 'set_ContentType'),
    ('accept', 'set_Accept'),
    ('user-agent', 'set_UserAgent'),
    ('referer', 'set_Referer'),
]

_METHODS_WITH_BODY = {'POST', 'PUT', 'PATCH'}


def _method_literal(args):
    if len(args) != 4:
        raise SyntaxError(
            'il_codegen: http_request(method, url, payload, headers) can dung 4 tham so')
    node = args[0]
    if node[0] != 'str_lit':
        raise SyntaxError(
            'il_codegen: http_request() can tham so DAU la CHUOI HANG ("GET"/"POST"/...) '
            '- trinh bien dich dua vao no de biet co ghi than yeu cau hay khong')
    return node[1].strip('"').upper()


def temps_http_request(node, ctx):
    args = node[2]
    TypeAnn = ctx['TypeAnn']
    p = f'__hreq{id(args)}'
    ctx['declare_named'](f'{p}_req', TypeAnn('[System]System.Net.HttpWebRequest', 'refclass'))
    ctx['declare_named'](f'{p}_resp', TypeAnn('[System]System.Net.HttpWebResponse', 'refclass'))
    ctx['declare_named'](f'{p}_result', TypeAnn('str', 'dict', key_dtype='str'))
    ctx['declare_named'](f'{p}_status', TypeAnn('i32', None))
    ctx['declare_named'](f'{p}_keys', TypeAnn('str', 'list'))
    ctx['declare_named'](f'{p}_i', TypeAnn('i32', None))
    ctx['declare_named'](f'{p}_key', TypeAnn('str', None))
    # Vong lap set header YEU CAU: dung lai cach cua stdlib_http.py
    kv_ta = TypeAnn('str', 'dict_kvpair', 'str')
    ctx['declare_named'](f'{p}_items', TypeAnn('str', 'list', elem_ta=kv_ta))
    ctx['declare_named'](f'{p}_hi', TypeAnn('i32', None))
    ctx['declare_named'](f'{p}_pair', kv_ta)


def _emit_apply_request_headers(args, scope, out, ctx, p, req_idx):
    """Duyet dict header, dat vao request. 4 header han che di qua property
    rieng, con lai qua Headers.Set()."""
    _, items_idx, _ = scope[f'{p}_items']
    _, i_idx, _ = scope[f'{p}_hi']
    _, pair_idx, _ = scope[f'{p}_pair']
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    pre = f"{ctx['prefix']}_hreqh{n}"
    start_lbl, end_lbl, next_lbl = f'{pre}_start', f'{pre}_end', f'{pre}_next'

    ctx['compile_expr'](args[3], scope, out, 'str', ctx)
    out.append(f'    newobj instance void {_LIST_KVP}::.ctor(class '
               '[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    stloc.s {items_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {items_idx}')
    out.append(f'    callvirt instance int32 {_LIST_KVP}::get_Count()')
    out.append(f'    bge {end_lbl}')
    out.append(f'    ldloc.s {items_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {_LIST_KVP}::get_Item(int32)')
    out.append(f'    stloc.s {pair_idx}')

    for j, (lower_name, setter) in enumerate(_RESTRICTED_SETTERS):
        skip_lbl = f'{pre}_notr{j}'
        out.append(f'    ldloca.s {pair_idx}')
        out.append(f'    call instance !0 {_KVP_SS}::get_Key()')
        out.append('    callvirt instance string [mscorlib]System.String::ToLowerInvariant()')
        out.append(f'    ldstr "{lower_name}"')
        out.append('    call bool [mscorlib]System.String::Equals(string, string)')
        out.append(f'    brfalse {skip_lbl}')
        out.append(f'    ldloc.s {req_idx}')
        out.append(f'    ldloca.s {pair_idx}')
        out.append(f'    call instance !1 {_KVP_SS}::get_Value()')
        out.append(f'    callvirt instance void [System]System.Net.HttpWebRequest::{setter}(string)')
        out.append(f'    br {next_lbl}')
        out.append(f'  {skip_lbl}:')

    out.append(f'    ldloc.s {req_idx}')
    out.append('    callvirt instance class [System]System.Net.WebHeaderCollection '
               '[System]System.Net.WebRequest::get_Headers()')
    out.append(f'    ldloca.s {pair_idx}')
    out.append(f'    call instance !0 {_KVP_SS}::get_Key()')
    out.append(f'    ldloca.s {pair_idx}')
    out.append(f'    call instance !1 {_KVP_SS}::get_Value()')
    out.append('    callvirt instance void [System]System.Net.WebHeaderCollection::Set(string, string)')
    out.append(f'  {next_lbl}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')


def _emit_dict_set(out, result_idx, key_emit, value_emit):
    out.append(f'    ldloc.s {result_idx}')
    key_emit()
    value_emit()
    out.append(f'    callvirt instance void {_DICT_SS}::set_Item(!0, !1)')


def push_http_request(args, scope, out, dtype, ctx):
    method = _method_literal(args)
    p = f'__hreq{id(args)}'
    _, req_idx, _ = scope[f'{p}_req']
    _, resp_idx, _ = scope[f'{p}_resp']
    _, result_idx, _ = scope[f'{p}_result']
    _, status_idx, _ = scope[f'{p}_status']
    _, keys_idx, _ = scope[f'{p}_keys']
    _, i_idx, _ = scope[f'{p}_i']
    _, key_idx, _ = scope[f'{p}_key']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    pre = f"{ctx['prefix']}_hreq{n}"
    after_lbl, hstart_lbl, hend_lbl = f'{pre}_after', f'{pre}_hstart', f'{pre}_hend'
    rethrow_lbl = f'{pre}_haveresp'

    out.append(f'    newobj instance void {_DICT_SS}::.ctor()')
    out.append(f'    stloc.s {result_idx}')

    # req = (HttpWebRequest)WebRequest.Create(url); req.Method = "<METHOD>"
    ctx['compile_expr'](args[1], scope, out, 'str', ctx)
    out.append('    call class [System]System.Net.WebRequest '
               '[System]System.Net.WebRequest::Create(string)')
    out.append('    castclass [System]System.Net.HttpWebRequest')
    out.append(f'    stloc.s {req_idx}')
    out.append(f'    ldloc.s {req_idx}')
    out.append(f'    ldstr "{method}"')
    out.append('    callvirt instance void [System]System.Net.WebRequest::set_Method(string)')

    _emit_apply_request_headers(args, scope, out, ctx, p, req_idx)

    if method in _METHODS_WITH_BODY:
        # StreamWriter tren request stream; Close() day du lieu di.
        out.append(f'    ldloc.s {req_idx}')
        out.append('    callvirt instance class [mscorlib]System.IO.Stream '
                   '[System]System.Net.WebRequest::GetRequestStream()')
        out.append('    newobj instance void [mscorlib]System.IO.StreamWriter::.ctor('
                   'class [mscorlib]System.IO.Stream)')
        out.append('    dup')
        ctx['compile_expr'](args[2], scope, out, 'str', ctx)
        out.append('    callvirt instance void [mscorlib]System.IO.TextWriter::Write(string)')
        out.append('    callvirt instance void [mscorlib]System.IO.TextWriter::Close()')

    # try { resp = req.GetResponse() } catch (WebException e) { resp = e.Response }
    # -> ma loi >= 400 KHONG lam chuong trinh chet, van doc duoc status/body.
    out.append('    .try')
    out.append('    {')
    out.append(f'      ldloc.s {req_idx}')
    out.append('      callvirt instance class [System]System.Net.WebResponse '
               '[System]System.Net.WebRequest::GetResponse()')
    out.append('      castclass [System]System.Net.HttpWebResponse')
    out.append(f'      stloc.s {resp_idx}')
    out.append(f'      leave {after_lbl}')
    out.append('    }')
    out.append('    catch [System]System.Net.WebException')
    out.append('    {')
    out.append('      callvirt instance class [System]System.Net.WebResponse '
               '[System]System.Net.WebException::get_Response()')
    out.append('      dup')
    out.append(f'      brtrue {rethrow_lbl}')
    # Loi KHONG co phan hoi (DNS sai, khong ket noi duoc) - nem tiep, vi
    # khong co gi de doc; giau di se thanh "status rong" kho hieu.
    out.append('      pop')
    out.append('      rethrow')
    out.append(f'    {rethrow_lbl}:')
    out.append('      castclass [System]System.Net.HttpWebResponse')
    out.append(f'      stloc.s {resp_idx}')
    out.append(f'      leave {after_lbl}')
    out.append('    }')
    out.append(f'  {after_lbl}:')

    # result["status"] = (int)resp.StatusCode
    out.append(f'    ldloc.s {resp_idx}')
    out.append('    callvirt instance valuetype [System]System.Net.HttpStatusCode '
               '[System]System.Net.HttpWebResponse::get_StatusCode()')
    out.append(f'    stloc.s {status_idx}')
    _emit_dict_set(
        out, result_idx,
        lambda: out.append('    ldstr "status"'),
        lambda: (out.append(f'    ldloca.s {status_idx}'),
                 out.append('    call class [mscorlib]System.Globalization.CultureInfo '
                            '[mscorlib]System.Globalization.CultureInfo::get_InvariantCulture()'),
                 out.append('    call instance string [mscorlib]System.Int32::ToString('
                            'class [mscorlib]System.IFormatProvider)')))

    # result["body"] = new StreamReader(resp.GetResponseStream()).ReadToEnd()
    _emit_dict_set(
        out, result_idx,
        lambda: out.append('    ldstr "body"'),
        lambda: (out.append(f'    ldloc.s {resp_idx}'),
                 out.append('    callvirt instance class [mscorlib]System.IO.Stream '
                            '[System]System.Net.WebResponse::GetResponseStream()'),
                 out.append('    newobj instance void [mscorlib]System.IO.StreamReader::.ctor('
                            'class [mscorlib]System.IO.Stream)'),
                 out.append('    callvirt instance string [mscorlib]System.IO.TextReader::ReadToEnd()')))

    # keys = new List<string>(resp.Headers.AllKeys); moi key -> "header:<ten>"
    out.append(f'    ldloc.s {resp_idx}')
    out.append('    callvirt instance class [System]System.Net.WebHeaderCollection '
               '[System]System.Net.WebResponse::get_Headers()')
    out.append('    callvirt instance string[] '
               '[System]System.Net.WebHeaderCollection::get_AllKeys()')
    out.append(f'    newobj instance void {_LIST_STR}::.ctor(class '
               '[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    stloc.s {keys_idx}')
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'  {hstart_lbl}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    callvirt instance int32 {_LIST_STR}::get_Count()')
    out.append(f'    bge {hend_lbl}')
    out.append(f'    ldloc.s {keys_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    callvirt instance !0 {_LIST_STR}::get_Item(int32)')
    out.append(f'    stloc.s {key_idx}')
    _emit_dict_set(
        out, result_idx,
        lambda: (out.append('    ldstr "header:"'),
                 out.append(f'    ldloc.s {key_idx}'),
                 out.append('    callvirt instance string '
                            '[mscorlib]System.String::ToLowerInvariant()'),
                 out.append('    call string [mscorlib]System.String::Concat(string, string)')),
        lambda: (out.append(f'    ldloc.s {resp_idx}'),
                 out.append('    callvirt instance class [System]System.Net.WebHeaderCollection '
                            '[System]System.Net.WebResponse::get_Headers()'),
                 out.append(f'    ldloc.s {key_idx}'),
                 out.append('    callvirt instance string '
                            '[System]System.Net.WebHeaderCollection::Get(string)')))
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {hstart_lbl}')
    out.append(f'  {hend_lbl}:')
    out.append(f'    ldloc.s {resp_idx}')
    out.append('    callvirt instance void [System]System.Net.WebResponse::Close()')
    out.append(f'    ldloc.s {result_idx}')


register_expr_builtin('http_request', push_http_request, 'str',
                       return_ta=TypeAnn('str', 'dict', key_dtype='str'),
                       temps_fn=temps_http_request)
