# -*- coding: utf-8 -*-
"""cJSON P/Invoke Plugin cho TokenVector (Added by Gemini - 2026-08-07)
Tuong tu nhu stdlib_sqlite.py, plugin nay mo cong FFI toi thu vien cJSON.dll (C)
giup TokenVector co the xu ly JSON o toc do C-native ma khong can thu vien Python.

Hien tai ho tro 4 ham co ban (doi ten tien to 'cjson_' 2026-08-11 - ten cu
'json_get_str' trung voi stdlib_json_get.py's json_get_str(chuoi, key)->str,
import sau trong tkv_compile.py nen am tham DE len ban dang ky truoc, gay
loi kieu du lieu neu goi json_get_str tuong chuoi-tho ma thuc chat chay theo
API handle cua cjson):
- cjson_parse(chuoi) -> i64 (Tra ve handle con tro object)
- cjson_get_obj(handle, key) -> i64 (Tra ve con tro cua mot thuoc tinh con)
- cjson_get_str(handle, key) -> str (Tra ve chuoi cua mot thuoc tinh)
- cjson_delete(handle) -> i32 (Giai phong bo nho)
"""
import re
from il_dispatch import register_expr_builtin

# Regex check xem nguoi dung co dung cJSON khong
_USES_CJSON_RE = re.compile(r'\bcjson_(parse|get_obj|get_str|delete)\(')

# Khai bao P/Invoke cho CIL
CJSON_PINVOKE_DECL_LINES = [
    '  // --- BEGIN GEMINI ADDED CODE: cJSON P/Invoke Declarations ---',
    '  .method public hidebysig static pinvokeimpl("cJSON.dll" as "cJSON_Parse" cdecl)',
    '      int64 __cjson_parse(string value) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("cJSON.dll" as "cJSON_GetObjectItem" cdecl)',
    '      int64 __cjson_get_object_item(int64 obj, string key) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("cJSON.dll" as "cJSON_GetStringValue" cdecl)',
    '      string __cjson_get_string_value(int64 item) cil managed preservesig {}',
    '  .method public hidebysig static pinvokeimpl("cJSON.dll" as "cJSON_Delete" cdecl)',
    '      int32 __cjson_delete(int64 item) cil managed preservesig {}',
    '  // --- END GEMINI ADDED CODE ---'
]

def uses_cjson(body_lines):
    """Kiem tra xem than ham co dung cJSON khong."""
    for raw in body_lines:
        if _USES_CJSON_RE.search(raw):
            return True
    return False

def _class_name(ctx):
    return (ctx or {}).get('class_name') or 'Program'

def push_cjson_parse(args, scope, out, dtype, ctx):
    if len(args) != 1: raise SyntaxError("cjson_parse can 1 tham so (string)")
    arg0 = args[0]()
    if arg0 != 'str': raise SyntaxError("cjson_parse can tham so string")
    out.append(f'    call int64 {_class_name(ctx)}::__cjson_parse(string)')
    return 'i64'

def push_cjson_get_obj(args, scope, out, dtype, ctx):
    if len(args) != 2: raise SyntaxError("cjson_get_obj can 2 tham so (handle, key)")
    arg0 = args[0]()
    arg1 = args[1]()
    if arg0 != 'i64' or arg1 != 'str': raise SyntaxError("cjson_get_obj can (i64, str)")
    out.append(f'    call int64 {_class_name(ctx)}::__cjson_get_object_item(int64, string)')
    return 'i64'

def push_cjson_get_str(args, scope, out, dtype, ctx):
    if len(args) != 2: raise SyntaxError("cjson_get_str can 2 tham so (handle, key)")
    arg0 = args[0]() # push handle
    arg1 = args[1]() # push key
    if arg0 != 'i64' or arg1 != 'str': raise SyntaxError("cjson_get_str can (i64, str)")

    # Lay object truoc, sau do lay string
    out.append(f'    call int64 {_class_name(ctx)}::__cjson_get_object_item(int64, string)')
    out.append(f'    call string {_class_name(ctx)}::__cjson_get_string_value(int64)')
    return 'str'

def push_cjson_delete(args, scope, out, dtype, ctx):
    if len(args) != 1: raise SyntaxError("cjson_delete can 1 tham so (handle)")
    arg0 = args[0]()
    if arg0 != 'i64': raise SyntaxError("cjson_delete can tham so i64")
    out.append(f'    call int32 {_class_name(ctx)}::__cjson_delete(int64)')
    return 'i32'

# Dang ky cac ham vao he thong
register_expr_builtin('cjson_parse', push_cjson_parse, 'i64')
register_expr_builtin('cjson_get_obj', push_cjson_get_obj, 'i64')
register_expr_builtin('cjson_get_str', push_cjson_get_str, 'str')
register_expr_builtin('cjson_delete', push_cjson_delete, 'i32')
