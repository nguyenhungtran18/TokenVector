# -*- coding: utf-8 -*-
"""json_get_str(json_text, key) -> str (2026-07-30) - phan bu cho
json_dumps() (chi ghi, chua co doc) - hang muc gia tri cao nhat khi doi
chieu voi thu vien chuan Python (json.loads con thieu hoan toan). GIOI
HAN CO Y THUC (khong phai json.loads TONG QUAT - kieu tinh khong the tra
ve object dong): CHI trich 1 truong CAP 1 dang chuoi tu 1 JSON object
PHANG (khong ho tro long nhau/mang), qua Regex "key":"value" - dung
System.Text.RegularExpressions (DA co san extern 'System' tu re_match/
re_sub, KHONG can them assembly). Neu khong khop, tra ve chuoi rong.
Da xac minh THAT chu ky Match/Groups/Group qua PowerShell reflection
truoc khi viet (Regex.Match(string,string)->Match, Match.get_Success()/
get_Groups()->GroupCollection, GroupCollection.get_Item(int32)->Group,
Group.get_Value()->string - deu la REFERENCE TYPE, khong can dia chi).

TU 2026-08-03 (Giai doan 0.2 nhom 8): dang ky qua register_expr_builtin nen
goi duoc o MOI vi tri bieu thuc ('return json_get_str(t, k)'); duong
ASSIGN_RHS_PARSERS/FIRST_PASS_WALK/STMT_CODEGEN cu da BO HAN. Nho vay khong
con phai tach 2 tham so bang tay (_split_top_level_comma_2 muon tu
stdlib_sqlite.py, nay da xoa) - parser bieu thuc tach dung san."""
from il_dispatch import register_expr_builtin


def temps_json_get_str(node, ctx):
    """2 hidden local: chuoi pattern ghep tu key, va doi tuong Match. Khoa
    id(node[2]) = id(danh sach tham so) - xem ghi chu o stdlib_json.py."""
    args = node[2]
    ctx['declare_named'](f'__jsongs{id(args)}_pattern', ctx['TypeAnn']('str', None))
    ctx['declare_named'](f'__jsongs{id(args)}_match', ctx['TypeAnn']('', 'regex_match'))


def push_json_get_str(args, scope, out, dtype, ctx):
    if len(args) != 2:
        raise SyntaxError("il_codegen: json_get_str(json_text, key) can dung 2 tham so")
    compile_expr = ctx['compile_expr']
    _, pattern_idx, _ = scope[f'__jsongs{id(args)}_pattern']
    _, match_idx, _ = scope[f'__jsongs{id(args)}_match']

    ctx['label_counter'][0] += 1
    n = ctx['label_counter'][0]
    nomatch_lbl = f"{ctx['prefix']}_jsongs{n}_nomatch"
    end_lbl = f"{ctx['prefix']}_jsongs{n}_end"

    # pattern = "\"" + key + "\"\s*:\s*\"([^\"]*)\""  (BUG THAT phat hien
    # qua test dau tien: ban dau THIEU dau '"' MO DAU truoc key, khien
    # regex sai hoan toan, khong khop bat ky JSON nao - da sua bang cach
    # ghep RO RANG tung phan, kiem tra tay chuoi ket qua truoc khi ghi).
    out.append('    ldstr "\\""')
    compile_expr(args[1], scope, out, 'str', ctx)
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append('    ldstr "\\"\\s*:\\s*\\"([^\\"]*)\\""')
    out.append('    call string [mscorlib]System.String::Concat(string, string)')
    out.append(f'    stloc.s {pattern_idx}')

    compile_expr(args[0], scope, out, 'str', ctx)
    out.append(f'    ldloc.s {pattern_idx}')
    out.append('    call class [System]System.Text.RegularExpressions.Match '
               '[System]System.Text.RegularExpressions.Regex::Match(string, string)')
    out.append(f'    stloc.s {match_idx}')

    out.append(f'    ldloc.s {match_idx}')
    out.append('    callvirt instance bool [System]System.Text.RegularExpressions.Match::get_Success()')
    out.append(f'    brfalse {nomatch_lbl}')

    out.append(f'    ldloc.s {match_idx}')
    out.append('    callvirt instance class [System]System.Text.RegularExpressions.GroupCollection '
               '[System]System.Text.RegularExpressions.Match::get_Groups()')
    out.append('    ldc.i4.1')
    out.append('    callvirt instance class [System]System.Text.RegularExpressions.Group '
               '[System]System.Text.RegularExpressions.GroupCollection::get_Item(int32)')
    out.append('    callvirt instance string [System]System.Text.RegularExpressions.Group::get_Value()')
    out.append(f'    br {end_lbl}')
    out.append(f'  {nomatch_lbl}:')
    out.append('    ldstr ""')
    out.append(f'  {end_lbl}:')


register_expr_builtin('json_get_str', push_json_get_str, 'str',
                       temps_fn=temps_json_get_str)
