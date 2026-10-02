# -*- coding: utf-8 -*-
"""Phase 9i (2026-08-28): marshal 2 chieu 'array[array[T]]' (jagged .NET
T[][]) <-> 'list[list[T]]' TokenVector (List<List<T>>) cho
__tkv_extern_class__. KHONG co method BCL nao lam viec nay truc tiep
(khac 1 cap - List<T>.ToArray()/List<T>::.ctor(IEnumerable<T>) co san) -
phai phat 1 VONG LAP IL THAT, PHONG THEO CHINH XAC phong cach nhan/bien
dem cua compiler/il_features/control_flow.py::codegen_for (ctx['label_
counter']/ctx['prefix']).

4 bien cuc bo scratch dat ten co dinh, cap phat 1 LAN cho CA HAM qua
scratch_locals() - PHONG THEO CHINH XAC tien le il_features/int_type.py
(SCRATCH_A/scratch_locals(), xem il_codegen.py:3697-3728 - noi TAT CA
scratch_locals() cua moi module duoc gop vo dieu kien vao locals_decl).
2 bien 'object' (__arr2d_src/__arr2d_dst) giu tham chieu List<List<T>>
HOAC T[][] BAT KY (T thay doi tuy tham so/return dtype cu the) - doc lai
PHAI castclass ve dung kieu, giong het tien le dtype 'thread' dung
'object' + castclass ve Task<T> cu the (xem il_core.py:9-18)."""

SCRATCH_SRC = '__arr2d_src'
SCRATCH_DST = '__arr2d_dst'
SCRATCH_I = '__arr2d_i'
SCRATCH_N = '__arr2d_n'


def scratch_locals():
    """(ten, dtype) cac local can khai bao trong MOI ham (vo dieu kien,
    dong bo voi int_type.scratch_locals() - xem docstring module nay)."""
    return [(SCRATCH_SRC, 'object'), (SCRATCH_DST, 'object'),
            (SCRATCH_I, 'i32'), (SCRATCH_N, 'i32')]


def _il_types(inner_elem, extern_class_defs):
    import il_codegen
    il_elem = il_codegen._il_array_elem_type(inner_elem, extern_class_defs)
    list1_il = f"class [mscorlib]System.Collections.Generic.List`1<{il_elem}>"
    list2_il = f"class [mscorlib]System.Collections.Generic.List`1<{list1_il}>"
    arr2d_il = f"{il_elem}[][]"
    return il_elem, list1_il, list2_il, arr2d_il


def emit_arg_marshal_loop(inner_elem, extern_class_defs, ctx, out):
    """Chieu ARG: dinh stack dang la 1 List<List<T>> (T = inner_elem) -
    sau khi ham chay xong, dinh stack la 1 T[][] (da castclass) san sang
    nap vao vi tri tham so .NET khai 'T[][]'.

    Idiom TAI DUNG nguyen ven cho TUNG PHAN TU trong vong lap:
    'callvirt instance !0[] List1<T>::ToArray()' - CHINH LA dong da co
    san trong _compile_extern_object_arg's nhanh 'array[' 1 cap (xem
    il_codegen.py, truoc Phase 9i), chi lap lai N lan (N = List<List<T>>.
    Count) thay vi goi 1 lan."""
    il_elem, list1_il, list2_il, arr2d_il = _il_types(inner_elem, extern_class_defs)
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx['prefix']
    start_lbl = f'{prefix}_arr2d_arg{n}_start'
    end_lbl = f'{prefix}_arr2d_arg{n}_end'
    out.append(f"    stloc '{SCRATCH_SRC}'")
    out.append(f"    ldloc '{SCRATCH_SRC}'")
    out.append(f'    castclass {list2_il}')
    out.append(f'    callvirt instance int32 {list2_il}::get_Count()')
    out.append(f"    stloc '{SCRATCH_N}'")
    out.append(f"    ldloc '{SCRATCH_N}'")
    out.append(f'    newarr {il_elem}[]')
    out.append(f"    stloc '{SCRATCH_DST}'")
    out.append('    ldc.i4.0')
    out.append(f"    stloc '{SCRATCH_I}'")
    out.append(f'  {start_lbl}:')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append(f"    ldloc '{SCRATCH_N}'")
    out.append(f'    bge {end_lbl}')
    out.append(f"    ldloc '{SCRATCH_DST}'")
    out.append(f'    castclass {arr2d_il}')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append(f"    ldloc '{SCRATCH_SRC}'")
    out.append(f'    castclass {list2_il}')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append(f'    callvirt instance !0 {list2_il}::get_Item(int32)')
    out.append(f'    callvirt instance !0[] {list1_il}::ToArray()')
    out.append('    stelem.ref')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f"    stloc '{SCRATCH_I}'")
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f"    ldloc '{SCRATCH_DST}'")
    out.append(f'    castclass {arr2d_il}')


def emit_return_marshal_loop(inner_elem, extern_class_defs, ctx, out):
    """Chieu RETURN: dinh stack dang la 1 T[][] (gia tri tra ve THAT SU
    tu callvirt/call method .NET) - sau khi ham chay xong, dinh stack la
    1 List<List<T>> (da castclass) - dtype PHIA TOKENVECTOR cua
    'array[array[T]]' la 'list[list[T]]' (_tokenvector_facing_dtype).

    Idiom TAI DUNG nguyen ven cho TUNG PHAN TU: 'newobj instance void
    List1<T>::.ctor(class ...IEnumerable1<!0>)' - CHINH LA dong da co san
    trong _marshal_extern_return_array 1 cap (khong cast, T[] tu cai dat
    IEnumerable<T>), lap lai N lan (N = do dai T[][] ngoai) roi Add() vao
    List<List<T>> ket qua."""
    il_elem, list1_il, list2_il, arr2d_il = _il_types(inner_elem, extern_class_defs)
    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx['prefix']
    start_lbl = f'{prefix}_arr2d_ret{n}_start'
    end_lbl = f'{prefix}_arr2d_ret{n}_end'
    out.append(f"    stloc '{SCRATCH_SRC}'")
    out.append(f"    ldloc '{SCRATCH_SRC}'")
    out.append(f'    castclass {arr2d_il}')
    out.append('    ldlen')
    out.append('    conv.i4')
    out.append(f"    stloc '{SCRATCH_N}'")
    out.append(f'    newobj instance void {list2_il}::.ctor()')
    out.append(f"    stloc '{SCRATCH_DST}'")
    out.append('    ldc.i4.0')
    out.append(f"    stloc '{SCRATCH_I}'")
    out.append(f'  {start_lbl}:')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append(f"    ldloc '{SCRATCH_N}'")
    out.append(f'    bge {end_lbl}')
    out.append(f"    ldloc '{SCRATCH_DST}'")
    out.append(f'    castclass {list2_il}')
    out.append(f"    ldloc '{SCRATCH_SRC}'")
    out.append(f'    castclass {arr2d_il}')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append('    ldelem.ref')
    out.append(f'    newobj instance void {list1_il}::.ctor(class '
                f'[mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')
    out.append(f'    callvirt instance void {list2_il}::Add(!0)')
    out.append(f"    ldloc '{SCRATCH_I}'")
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f"    stloc '{SCRATCH_I}'")
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f"    ldloc '{SCRATCH_DST}'")
    out.append(f'    castclass {list2_il}')
