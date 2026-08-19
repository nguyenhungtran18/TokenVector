# -*- coding: utf-8 -*-
"""Giao AlphaAI (Groq) sinh SONG SONG 1 lo ham DSL dung tu vung DA CO SAN
(string/dict/list/try-except/tuple - moi them trong session nay, CHUA
tung duoc AlphaAI dung thu) - CHAY NEN trong khi Claude lam khoang trong
#1 (method that tren record). Script nay CHI kiem tra AlphaAI sinh dung
CU PHAP (compile qua gen_il_function that) - CHUA doi chieu CPython that
(buoc do lam RIENG sau, thu cong, truoc khi tinh la xong - dung nguyen
tac 'khong tin mu ket qua AI')."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from alphaai_codegen import generate_and_verify

TASKS = [
    # LUU Y: day la dinh dang chu ky THO cua typed_dsl_parser (dtype
    # KHONG ngoac kep, vd 's: str') - KHAC dinh dang Python annotation
    # dung trong file .tkv ('s: "str"') - bug that tim thay: ban dau viet
    # nham dinh dang .tkv o day, khien parse_typed_signature nem
    # SyntaxError NGAY TU CHINH KY TU (khong phai loi cua AlphaAI).
    ('count_vowels_str(s: str) -> i32:',
     'Dem so ky tu nguyen am (a, e, i, o, u - chu thuong) trong chuoi s, tra ve so luong.'),
    ('most_frequent_char(s: str) -> str:',
     'Tim ky tu XUAT HIEN NHIEU NHAT trong chuoi s (dung dict dem tan suat tung ky tu), '
     'tra ve ky tu do dang 1 chuoi do dai 1. Neu s rong, tra ve chuoi rong "".'),
    ('fib_sum_upto(n: i32) -> i32:',
     'Tinh day Fibonacci (0, 1, 1, 2, 3, 5, ...) co n so dau tien (dung list de luu day so), '
     'roi tra ve TONG cua ca day (dung vong lap qua list de cong don).'),
    ('safe_divide_report(a: f32, b: f32) -> str:',
     'Chia a cho b trong khoi try. Neu b = 0 se nem ZeroDivisionError - bat loi do bang '
     '"except ZeroDivisionError:" va tra ve chuoi "loi: chia cho 0". Neu khong loi, tra ve '
     'chuoi "ket qua: " noi voi str(ket qua chia).'),
    ('range_stats(n: i32) -> (i32, i32):',
     'Duyet i tu 0 den n-1. Dem SO LUONG i sao cho i lon hon n chia 2 (dung phep so sanh, '
     'KHONG dung phep chia lay du vi DSL khong ho tro %) vao 1 bien dem, va TONG tat ca i '
     'thoa dieu kien do vao 1 bien tong khac. Tra ve (tong, dem) dang tuple 2 phan tu.'),
]

results = []
for sig_line, desc in TASKS:
    print(f'--- {sig_line}')
    r = generate_and_verify(desc, sig_line, provider='groq', max_attempts=3)
    print(f'    success={r["success"]} attempts={len(r["attempts"])}')
    if not r['success']:
        print(f'    LOI CUOI CUNG: {r["error"]}')
    results.append({'signature': sig_line, 'task': desc, 'success': r['success'],
                     'attempts_used': len(r['attempts']), 'body_lines': r['body_lines'],
                     'error': r['error']})

out_path = Path(__file__).parent / 'alphaai_batch_port_results.json'
out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
n_ok = sum(1 for r in results if r['success'])
print(f'\n=== TONG: {n_ok}/{len(results)} sinh+compile THANH CONG (cu phap) ===')
print(f'Ket qua chi tiet: {out_path}')
