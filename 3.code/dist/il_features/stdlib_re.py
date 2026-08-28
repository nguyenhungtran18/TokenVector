# -*- coding: utf-8 -*-
"""re_match(pattern, s) / re_sub(pattern, repl, s) (Wave 2, 2026-07-29,
soan boi Gemini) - anh xa System.Text.RegularExpressions.Regex. Ten HAM
PHANG (khong 're.match'/'re.sub' co dau cham) - GIONG quy uoc da co cua
path_join/file_exists/read_file (khong mo phong 'module.func()' vi cu
phap DSL hien tai hieu 'x.y(...)' la METHOD_CALL tren 1 BIEN ten 'x' da
khai bao, khong phai goi ham module-level).

GIOI HAN DA BIET: re_match neo dau chuoi bang cach tu them '^' vao dau
pattern (Regex.IsMatch KHONG neo dau nhu Python re.match); re_sub's
'repl' la chuoi THUONG (khong dich backreference \\1 -> $1)."""


def compile_re_match(args, scope, out, dtype, ctx):
    """re_match(pattern, s) -> i32 (0/1) - .NET Regex.IsMatch(input, pattern)
    tim khop O BAT KY DAU (khac Python neo dau) nen phai tu noi '^' vao
    dau pattern truoc khi goi."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re.match(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[1], scope, out, 'str', ctx)
    out.append('    ldstr "^"')
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append('    call bool [System]System.Text.RegularExpressions.Regex::IsMatch(string, string)')


def compile_re_search(args, scope, out, dtype, ctx):
    """re_search(pattern, s) -> i32 (0/1) - .NET Regex.IsMatch(input, pattern)
    tim khop O BAT KY DAU trong chuoi, dung THANG (khong can tu them '^'
    nhu re_match) - day CHINH LA ngu nghia goc cua Python re.search()."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re_search(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[1], scope, out, 'str', ctx)
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call bool [System]System.Text.RegularExpressions.Regex::IsMatch(string, string)')


def compile_re_fullmatch(args, scope, out, dtype, ctx):
    """re_fullmatch(pattern, s) -> i32 (0/1) - Python re.fullmatch() doi
    hoi khop TOAN BO chuoi; Regex.IsMatch mac dinh chi can khop 1 phan nen
    tu neo CA HAI DAU ('^' + pattern + '$') truoc khi goi."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re_fullmatch(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[1], scope, out, 'str', ctx)
    out.append('    ldstr "^"')
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append('    ldstr "$"')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append('    call bool [System]System.Text.RegularExpressions.Regex::IsMatch(string, string)')


def compile_re_sub(args, scope, out, dtype, ctx):
    """re_sub(pattern, repl, s) -> str - .NET Regex.Replace(input, pattern,
    replacement) - CHU Y thu tu tham so KHAC Python (input truoc)."""
    if len(args) != 3:
        raise SyntaxError("il_codegen: re.sub(pattern, repl, s) can dung 3 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[2], scope, out, 'str', ctx)
    compile_expr(args[0], scope, out, 'str', ctx)
    compile_expr(args[1], scope, out, 'str', ctx)
    out.append('    call string [System]System.Text.RegularExpressions.Regex::Replace(string, string, string)')


def compile_re_split(args, scope, out, dtype, ctx):
    """re_split(pattern, s) -> list[str] - .NET Regex.Split(input,
    pattern) tra thang string[], la 1 IEnumerable<string> hop le de dua
    thang vao List<string> constructor - giong het cach _push_os_list_files
    (stdlib_os.py) da lam voi Directory.GetFiles(). CHU Y thu tu tham so
    KHAC Python (input truoc, giong re_sub)."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re_split(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']
    compile_expr(args[1], scope, out, 'str', ctx)
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call string[] [System]System.Text.RegularExpressions.Regex::Split(string, string)')
    out.append('    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor(class [mscorlib]System.Collections.Generic.IEnumerable`1<!0>)')


def _findall_temps(node, ctx):
    """FIRST PASS: khai 3 local an cho re_findall(pattern, s) - 'mc'
    (MatchCollection tra ve tu Regex.Matches, giu de doc Count + indexer
    nhieu lan khong tinh lai), 'result' (List<string> tich luy ket qua),
    'i' (chi so vong lap i32). Dung lai NGUYEN co che declare_named/
    id(args)-khoa da dung cho sample()/shuffle() o RandomSeed Task 3."""
    args = node[2]
    if len(args) != 2:
        return
    TypeAnn = ctx['TypeAnn']
    ctx['declare_named'](f'__refa{id(args)}_mc', TypeAnn('', 'regex_matches'))
    ctx['declare_named'](f'__refa{id(args)}_result', TypeAnn('str', 'list'))
    ctx['declare_named'](f'__refa{id(args)}_i', TypeAnn('i32', None))


def compile_re_findall(args, scope, out, dtype, ctx):
    """re_findall(pattern, s) -> list[str] - Regex.Matches(input,
    pattern) tra ve MatchCollection (KHONG the dua thang vao List<string>
    constructor nhu re_split - moi phan tu la 1 Match, can trich .Value
    tung phan tu qua vong lap chi so, xem spec 2026-08-12-re-findall-
    split-design.md). GIOI HAN DA BIET: pattern co group con ((...)) tra
    .Value CUA CA MATCH, khong phai tuple cac group - giong gioi han
    repl-la-string-thuong cua re_sub, chap nhan duoc."""
    if len(args) != 2:
        raise SyntaxError("il_codegen: re_findall(pattern, s) can dung 2 tham so")
    compile_expr = ctx['compile_expr']

    mc_idx = scope[f'__refa{id(args)}_mc'][1]
    result_idx = scope[f'__refa{id(args)}_result'][1]
    i_idx = scope[f'__refa{id(args)}_i'][1]

    # mc = Regex.Matches(s, pattern)
    compile_expr(args[1], scope, out, 'str', ctx)
    compile_expr(args[0], scope, out, 'str', ctx)
    out.append('    call class [System]System.Text.RegularExpressions.MatchCollection '
                '[System]System.Text.RegularExpressions.Regex::Matches(string, string)')
    out.append(f'    stloc.s {mc_idx}')

    # result = new List<string>()
    out.append('    newobj instance void class [mscorlib]System.Collections.Generic.List`1<string>::.ctor()')
    out.append(f'    stloc.s {result_idx}')

    # i = 0
    out.append('    ldc.i4.0')
    out.append(f'    stloc.s {i_idx}')

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    prefix = ctx.get('prefix', 'refa')
    start_lbl = f'{prefix}_refa{n}_start'
    end_lbl = f'{prefix}_refa{n}_end'

    out.append(f'  {start_lbl}:')
    out.append(f'    ldloc.s {i_idx}')
    out.append(f'    ldloc.s {mc_idx}')
    out.append('    callvirt instance int32 [System]System.Text.RegularExpressions.MatchCollection::get_Count()')
    out.append(f'    bge {end_lbl}')

    # result.Add(mc[i].Value)
    out.append(f'    ldloc.s {result_idx}')
    out.append(f'    ldloc.s {mc_idx}')
    out.append(f'    ldloc.s {i_idx}')
    out.append('    callvirt instance class [System]System.Text.RegularExpressions.Match '
                '[System]System.Text.RegularExpressions.MatchCollection::get_Item(int32)')
    out.append('    callvirt instance string [System]System.Text.RegularExpressions.Match::get_Value()')
    out.append('    callvirt instance void class [mscorlib]System.Collections.Generic.List`1<string>::Add(!0)')

    # i = i + 1; goto start
    out.append(f'    ldloc.s {i_idx}')
    out.append('    ldc.i4.1')
    out.append('    add')
    out.append(f'    stloc.s {i_idx}')
    out.append(f'    br {start_lbl}')
    out.append(f'  {end_lbl}:')
    out.append(f'    ldloc.s {result_idx}')


from il_dispatch import register_expr_builtin

register_expr_builtin('re_match', compile_re_match, 'i32')
register_expr_builtin('re_search', compile_re_search, 'i32')
register_expr_builtin('re_fullmatch', compile_re_fullmatch, 'i32')
register_expr_builtin('re_sub', compile_re_sub, 'str')
register_expr_builtin('re_split', compile_re_split, 'str', return_shape='list')
register_expr_builtin('re_findall', compile_re_findall, 'str', return_shape='list', temps_fn=_findall_temps)
