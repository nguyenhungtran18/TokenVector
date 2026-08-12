# -*- coding: utf-8 -*-
"""Logic parse+codegen rieng cua string (Phase 1 buoc 5, 2026-07-28).
Khong co regex rieng (string chi la scalar assign binh thuong, dung
chung 'assign_scalar' o core) - file nay CHI so huu phan _compile_expr:
tag 'str_lit' (dang ky TRUC TIEP, tach biet hoan toan voi cac tag
khac); va cac NHANH string long trong tag dung chung ('index'/'call'
qua len()/str()/'binop'/'compare') - noi tag do van O CORE (dispatch
theo dtype/shape la logic chung cho nhieu kieu du lieu), file nay chi
so huu THAN cua nhanh string, duoc core goi lai qua ham rieng. Dung
chung quy uoc dependency-injection qua `ctx` nhu cac buoc truoc."""
from il_core import emit_index_value
from il_dispatch import register_expr_codegen


def compile_str_lit(node, scope, out, dtype, ctx=None):
    """EXPR_CODEGEN entry TRUC TIEP cho tag 'str_lit' - tach biet hoan
    toan (khong chia se dispatch voi kieu nao khac)."""
    out.append(f'    ldstr {node[1]}')  # node[1] van con ca dau ngoac kep tu tokenizer


def compile_index_str(name, indices, scope, out, ctx):
    """Nhanh string cua tag 'index' (s[i]) - goi tu il_codegen.py's
    _expr_index khi type_ann.dtype=='str' va shape is None. Python that:
    KET QUA la 1 chuoi do dai 1 (KHONG co kieu char rieng, khac .NET).
    String's indexer that su (get_Chars) tra ve System.Char (khac
    String) nen phai chuyen doi: lay char roi dung constructor
    String(char, int32 count) de duoc lai 1 chuoi that (count=1) - tranh
    phai lay dia chi 1 char tam (Char.ToString() la instance method tren
    value type, cung han che nhu ToString() so/gioi han o cho khac trong
    file nay)."""
    if len(indices) != 1:
        raise SyntaxError(f"il_codegen: string '{name}' chi ho tro 1 chi so (vd {name}[i])")
    ctx['load_var_ref'](name, scope, out)
    emit_index_value(name, indices[0], scope, out, ctx,
                      'callvirt instance int32 [mscorlib]System.String::get_Length()')
    out.append('    callvirt instance char [mscorlib]System.String::get_Chars(int32)')
    out.append('    ldc.i4.1')
    out.append('    newobj instance void [mscorlib]System.String::.ctor(char, int32)')


def compile_len_str(arg_name, scope, out, dtype, ctx):
    """Nhanh string cua len() (goi tu il_codegen.py's _expr_call).
    String.Length - CHI SO thuoc tinh (get_Length), khac List/Dictionary
    dung get_Count() - ten khac nhau THAT su trong BCL, khong phai loi
    danh may."""
    ctx['load_var_ref'](arg_name, scope, out)
    out.append('    callvirt instance int32 [mscorlib]System.String::get_Length()')
    ctx['widen_if_needed']('i32', dtype, out)


def compile_binop_concat(op, left, right, scope, out, ctx):
    """Nhanh string cua tag 'binop' (noi chuoi '+') - goi tu
    il_codegen.py's _expr_binop khi operand_dtype=='str'."""
    if op == '*':
        # '"-" * n' (2026-08-03) - lap chuoi, giong Python. BCL khong co
        # String::Repeat; dung StringBuilder(string, int32 capacity)?
        # KHONG - cach ngan gon va da co san: String::Concat(
        # IEnumerable) qua Enumerable.Repeat can System.Core + generic
        # phuc tap. Chon cach RE NHAT ma van dung: string.Replace tren 1
        # chuoi n ky tu do String::.ctor(char, int32) tao ra chi lam duoc
        # voi 1 KY TU - nen o day dung StringBuilder::Insert(int32,
        # string, int32 count) - co san, dung cho chuoi DAI TUY Y.
        left_node, right_node = left, right
        left_dtype = ctx['infer_dtype'](left_node, scope, ctx.get('func_table'),
                                        ctx.get('records'), ctx.get('record_methods'))
        if left_dtype != 'str':
            # 'n * "-"' - Python cho phep ca 2 chieu.
            left_node, right_node = right_node, left_node
        out.append('    newobj instance void [mscorlib]System.Text.StringBuilder::.ctor()')
        out.append('    ldc.i4.0')
        ctx['compile_expr'](left_node, scope, out, 'str', ctx)
        ctx['compile_expr'](right_node, scope, out, 'i32', ctx)
        out.append('    callvirt instance class [mscorlib]System.Text.StringBuilder '
                   '[mscorlib]System.Text.StringBuilder::Insert(int32, string, int32)')
        out.append('    callvirt instance string [mscorlib]System.Object::ToString()')
        return
    if op != '+':
        raise SyntaxError(f"il_codegen: string chi ho tro '+' (noi chuoi) va '*' (lap), "
                          f"khong ho tro '{op}'")
    compile_expr = ctx['compile_expr']
    compile_expr(left, scope, out, 'str', ctx)
    compile_expr(right, scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.String::Concat(string, string)')


def compile_compare_str(op, left, right, scope, out, ctx):
    """Nhanh string cua tag 'compare' - goi tu il_codegen.py's
    _expr_compare khi operand_dtype=='str'. 'ceq' tren 2 THAM CHIEU
    string la so sanh DANH TINH (identity), khong phai so sanh GIA TRI -
    phai dung String::Equals cho ==/!=; >,<,>=,<= dung
    String.CompareOrdinal (so sanh theo ma Unicode tung ky tu, GIONG het
    ngu nghia Python that cho chuoi ASCII/thuong dung - da xac minh THAT
    qua probe_str_compare.il: '0'<'9' -> True, 'z'>'a' -> True)."""
    compile_expr = ctx['compile_expr']
    if op in ('==', '!='):
        compile_expr(left, scope, out, 'str', ctx)
        compile_expr(right, scope, out, 'str', ctx)
        out.append('    call bool [mscorlib]System.String::Equals(string, string)')
        if op == '!=':
            out.append('    ldc.i4.0')
            out.append('    ceq')
        return
    compile_expr(left, scope, out, 'str', ctx)
    compile_expr(right, scope, out, 'str', ctx)
    out.append('    call int32 [mscorlib]System.String::CompareOrdinal(string, string)')
    out.append('    ldc.i4.0')
    compare_opcode, compare_negated = ctx['compare_opcode'], ctx['compare_negated']
    if op in compare_opcode:
        out.append(f'    {compare_opcode[op]}')
    else:
        out.append(f'    {compare_negated[op]}')
        out.append('    ldc.i4.0')
        out.append('    ceq')


# 'str_lit' la tag DOC LAP (khong chia se voi bat ky kieu nao khac) -
# dang ky TRUC TIEP tai day, khac cac ham compile_* o tren (nhung cai do
# van la NHANH long trong tag dung chung o core, khong tu dang ky).
register_expr_codegen('str_lit', compile_str_lit)
