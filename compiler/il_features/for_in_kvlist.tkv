# -*- coding: utf-8 -*-
"""'for k, v in items_list:' (2026-07-29, phan con lai cua dict.items()-
as-assign, xem dict_items_list.py) - macro TEXT-LEVEL, giong HET tinh
than 'for_in_list' cua control_flow.py (khai trien THANH VAN BAN sang
dang for-range+doc-chi-so+attr da co san, KHONG can codegen rieng).

Regex CHI khop khi container la 1 TEN BIEN TRAN (KHONG co '.items()' o
cuoi) - phan biet VOI 'for k, v in d.items():' da co san TRUOC do trong
dict_type.py's try_parse_for_in_dict_items (regex do BAT BUOC co
'.items()' o cuoi) - 2 regex loai tru lan nhau theo cau truc, KHONG
trung/danh chan nhau (macro nay chay TRUOC line-parser trong pipeline,
nhung vi khong khop cu phap co '.items()' nen dict-for-loop van hoat
dong nguyen ven qua duong cu).

Khai trien:
    for k, v in items_list:
        <than khoi>
thanh:
    for __iterkv{n}_idx in range(len(items_list)):
        __iterkv{n}_pair = items_list[__iterkv{n}_idx]
        k = __iterkv{n}_pair.key
        v = __iterkv{n}_pair.value
        <than khoi>

Khong kiem tra 'items_list' co THAT la List<KeyValuePair<K,V>> o day
(thuan text, chua co known_shapes du lieu shape sau) - neu sai (vd dung
tren 1 list thuong), loi se lo RO RANG sau o '.key'/'.value' (compile_attr
bao 'chi dung duoc tren... shape=dict_kvpair', khong am tham)."""
import re

from il_dispatch import register_macro_expander

_FOR_IN_KVLIST_RE = re.compile(r'^for\s+(\w+)\s*,\s*(\w+)\s+in\s+(\w+)\s*:\s*$')

_me_for_in_kvlist_counter = [0]


def try_expand_for_in_kvlist(line):
    stripped = line.strip()
    ind = ' ' * (len(line) - len(line.lstrip(' ')))
    m = _FOR_IN_KVLIST_RE.match(stripped)
    if not m:
        return None
    key_var, val_var, container = m.groups()
    n = _me_for_in_kvlist_counter[0]
    _me_for_in_kvlist_counter[0] += 1
    idx = f'__iterkv{n}_idx'
    pair = f'__iterkv{n}_pair'
    return (
        f'{ind}for {idx} in range(len({container})):\n'
        f'{ind}    {pair} = {container}[{idx}]\n'
        f'{ind}    {key_var} = {pair}.key\n'
        f'{ind}    {val_var} = {pair}.val'
    )


register_macro_expander('for_in_kvlist', try_expand_for_in_kvlist)
