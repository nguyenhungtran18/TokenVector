# -*- coding: utf-8 -*-
"""lst.pop() (2026-07-29) - soan nhap boi Gemini, dung khop chu ky method_call
that ngay lan dau, khong bug. Trả về + xoá PHẦN TỬ CUỐI, KHÔNG dùng local ẩn
hay 'dup' - lấy item TRƯỚC (list chưa đổi), rồi tính lại Count-1 (an toàn vì
Count chưa đổi) để gọi RemoveAt() sau.

GIOI HAN DA BIET: chi ho tro dang KHONG tham so (list.pop(i) co chi so
KHONG duoc ho tro). List rong -> .NET nem ArgumentOutOfRangeException luc
CHAY (khac IndexError cua Python) - khong tu vay."""


def compile_list_method_pop(node, scope, out, dtype, ctx):
    obj_name, args = node[1], node[3]
    if len(args) != 0:
        raise SyntaxError("il_codegen: lst.pop() hien chi ho tro dang khong tham so")
    _, _, ta = scope[obj_name]
    if ta.shape != 'list':
        raise SyntaxError(f"il_codegen: '{obj_name}.pop()' can '{obj_name}' la list")
    list_type = ctx['il_type_str'](ta, (ctx or {}).get('records'))
    load_var_ref = ctx['load_var_ref']

    # Buoc 1: lay phan tu cuoi (idx=Count-1), list CHUA thay doi.
    load_var_ref(obj_name, scope, out)
    load_var_ref(obj_name, scope, out)
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append('    ldc.i4.1')
    out.append('    sub')
    out.append(f'    callvirt instance !0 {list_type}::get_Item(int32)')

    # Buoc 2: tinh lai idx (an toan vi list chua doi tu Buoc 1), RemoveAt.
    load_var_ref(obj_name, scope, out)
    load_var_ref(obj_name, scope, out)
    out.append(f'    callvirt instance int32 {list_type}::get_Count()')
    out.append('    ldc.i4.1')
    out.append('    sub')
    out.append(f'    callvirt instance void {list_type}::RemoveAt(int32)')

    ctx['widen_if_needed'](ta.dtype, dtype, out)
