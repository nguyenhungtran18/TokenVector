# -*- coding: utf-8 -*-
"""pickle (Phase 4 backlog, phien 5, 2026-08-11) - CHI ho tro luu/doc 1
GIA TRI VO HUONG (i32/i64/f64/str) qua file: pickle_dump_i32(v, path)/
pickle_load_i32(path)->i32 (tuong tu i64/f64/str). KHONG ho tro list/
dict/record/nested object - thu hep pham vi co y thuc, quyet dinh cua
nguoi dung.

Dinh dang nhi phan dung System.IO.BinaryWriter/BinaryReader - TU DINH
NGHIA, KHONG phai byte THAT cua CPython pickle protocol (2 runtime
KHONG doc duoc file cua nhau). CHAP NHAN duoc: bai test doi chieu
CPython cua du an chi can round-trip DUNG trong CHINH 1 runtime (dump
roi load lai NGAY trong cung 1 chuong trinh/cung 1 ngon ngu), khong can
byte-for-byte giong nhau giua TokenVector va CPython."""
from il_dispatch import register_expr_builtin

_SPECS = {
    'i32': ('int32', 'ReadInt32'),
    'i64': ('int64', 'ReadInt64'),
    'f64': ('float64', 'ReadDouble'),
    'str': ('string', 'ReadString'),
}


def _make_dump(dtype, il_type):
    def _codegen(call_args, scope, body, ctx):
        if len(call_args) != 2:
            raise SyntaxError(f"il_codegen: pickle_dump_{dtype}(value, path) nhan dung 2 tham so")
        ctx['compile_expr'](call_args[1], scope, body, 'str', ctx)
        body.append('    ldc.i4.2')  # System.IO.FileMode.Create
        body.append('    newobj instance void [mscorlib]System.IO.FileStream::.ctor'
                     '(string, valuetype [mscorlib]System.IO.FileMode)')
        body.append('    newobj instance void [mscorlib]System.IO.BinaryWriter::.ctor'
                     '(class [mscorlib]System.IO.Stream)')
        body.append('    dup')
        ctx['compile_expr'](call_args[0], scope, body, dtype, ctx)
        body.append(f'    callvirt instance void [mscorlib]System.IO.BinaryWriter::Write({il_type})')
        body.append('    callvirt instance void [mscorlib]System.IO.BinaryWriter::Close()')
    return _codegen


def _temps_load(dtype):
    def _temps(node, ctx):
        args = node[2]
        key = id(args)
        ctx['declare_named'](f'__pkl_load{key}_tmp', ctx['TypeAnn'](dtype, None))
    return _temps


def _make_load(dtype, il_type, read_method):
    def _codegen(args, scope, out, out_dtype, ctx):
        if len(args) != 1:
            raise SyntaxError(f"il_codegen: pickle_load_{dtype}(path) nhan dung 1 tham so")
        key = id(args)
        _, tmp_idx, _ = scope[f'__pkl_load{key}_tmp']
        ctx['compile_expr'](args[0], scope, out, 'str', ctx)
        out.append('    ldc.i4.3')  # System.IO.FileMode.Open
        out.append('    newobj instance void [mscorlib]System.IO.FileStream::.ctor'
                    '(string, valuetype [mscorlib]System.IO.FileMode)')
        out.append('    newobj instance void [mscorlib]System.IO.BinaryReader::.ctor'
                    '(class [mscorlib]System.IO.Stream)')
        out.append('    dup')
        out.append(f'    callvirt instance {il_type} [mscorlib]System.IO.BinaryReader::{read_method}()')
        out.append(f'    stloc.s {tmp_idx}')
        out.append('    callvirt instance void [mscorlib]System.IO.BinaryReader::Close()')
        out.append(f'    ldloc.s {tmp_idx}')
        if out_dtype:
            ctx['widen_if_needed'](dtype, out_dtype, out)
    return _codegen


DUMP_STMT_CODEGEN = {}
for _dtype, (_il_type, _read) in _SPECS.items():
    DUMP_STMT_CODEGEN[f'pickle_dump_{_dtype}'] = _make_dump(_dtype, _il_type)
    register_expr_builtin(f'pickle_load_{_dtype}', _make_load(_dtype, _il_type, _read), _dtype,
                           temps_fn=_temps_load(_dtype))
