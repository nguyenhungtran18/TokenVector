# -*- coding: utf-8 -*-
"""xml_encode_name(s) - System.Xml.XmlConvert::EncodeName(string). Ham
NHO, KHONG phai muc tieu chinh - dung de KIEM CHUNG THAT co che mo rong
'__tkv_extern_assembly__' (Wave 3, 2026-07-29, xem tkv_compile.py's
_parse_program_ast + project-tokenvector-wave2-status memory): assembly
'System.Xml' KHONG nam trong 3 assembly luon co san (mscorlib/System/
System.Core) - PHAI khai bao qua '__tkv_extern_assembly__ = "System.Xml"'
trong file .tkv thi ham nay moi assemble+chay duoc (da tu xac minh THAT
bang ilasm.exe: extern bare KHONG publickeytoken/version THAT BAI
FileNotFoundException luc chay, phai co token+ver chuan .NET Framework)."""

from il_dispatch import register_expr_builtin


def compile_xml_encode_name(args, scope, out, dtype, ctx):
    if len(args) != 1:
        raise SyntaxError("il_codegen: xml_encode_name(s) chi nhan dung 1 tham so")
    ctx['compile_expr'](args[0], scope, out, 'str', ctx)
    out.append('    call string [System.Xml]System.Xml.XmlConvert::EncodeName(string)')


register_expr_builtin('xml_encode_name', compile_xml_encode_name, 'str')
