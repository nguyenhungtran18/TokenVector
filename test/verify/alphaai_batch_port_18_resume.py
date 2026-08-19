# -*- coding: utf-8 -*-
"""Chay NOT phan con lai cua batch 18 ham (alphaai_batch_port_18.py) sau
khi Groq TPD reset - gom 10 ham bi 429 rate-limit LAN TRUOC (chua tung
goi duoc LLM) + 'unique_char_count' (that bai LAN TRUOC vi bug that cua
compiler, da sua trong il_codegen.py, dang thu lai). Merge ket qua vao
cung file JSON, khong ghi de cac ket qua 8 ham da THAT SU thanh cong/
that bai do gioi han ngon ngu that."""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from alphaai_codegen import generate_and_verify

# Cung noi dung TASKS voi alphaai_batch_port_18.py (giu nguyen mo ta) -
# chi loc lai cac chu ky can CHAY LAI.
ALL_TASKS = {
    'count_digits(s: str) -> i32:':
        'Dem so ky tu la chu so (0-9) trong chuoi s, tra ve so luong.',
    'reverse_str(s: str) -> str:':
        'Tra ve chuoi s theo thu tu NGUOC LAI (dung vong lap duyet tu cuoi ve dau, '
        'noi tung ky tu vao 1 chuoi ket qua).',
    'unique_char_count(s: str) -> i32:':
        'Dung dict de danh dau ky tu da gap, tra ve SO LUONG ky tu KHAC NHAU trong chuoi s.',
    'list_max(a: i32, b: i32, c: i32) -> i32:':
        'Tao 1 list rong, them 3 so a, b, c vao list, roi duyet list de tim va tra ve GIA TRI '
        'LON NHAT trong 3 so do.',
    'list_count_even(n: i32) -> i32:':
        'Tao list gom cac so tu 0 den n-1, duyet list va dem so luong phan tu CHAN '
        '(dung phep chia lay du % voi 2), tra ve so dem do.',
    'dict_sum_values(a: i32, b: i32, c: i32) -> i32:':
        'Tao 1 dict rong, gan d["x"]=a, d["y"]=b, d["z"]=c, roi tra ve TONG 3 gia tri '
        'trong dict (doc lai tung khoa).',
    'dict_has_key_report(a: i32, key_present: i32) -> str:':
        'Tao 1 dict rong, gan d["val"]=a. Neu key_present khac 0 THEM gan d["extra"]=1. '
        'Kiem tra "extra" in d, neu co tra ve chuoi "co extra", neu khong tra ve "khong co extra".',
    'list_of_squares_sum(n: i32) -> i32:':
        'Tao list rong, dung vong lap them binh phuong tung so tu 0 den n-1 vao list, '
        'roi duyet list de tra ve TONG tat ca binh phuong do.',
    'gcd_like_mod(a: i32, b: i32) -> i32:':
        'Dung vong lap while: trong khi b khac 0, tinh r = a chia lay du cho b (dung %), '
        'gan a = b, gan b = r. Khi vong lap ket thuc tra ve a (gia tri GCD kieu Euclid).',
    'clamp_report(x: i32, lo: i32, hi: i32) -> str:':
        'Neu x < lo, tra ve chuoi "duoi min: " noi voi str(lo). Neu x > hi, tra ve chuoi '
        '"tren max: " noi voi str(hi). Neu khong, tra ve chuoi "trong khoang: " noi voi str(x).',
    'safe_index_report(n: i32, idx: i32) -> str:':
        'Tao list gom cac so tu 0 den n-1. Trong khoi try, neu idx < 0 hoac idx >= n thi '
        'TU NEM raise IndexError("chi so ngoai pham vi"). Bat loi bang except IndexError: '
        'tra ve chuoi "loi: chi so khong hop le". Neu khong loi, tra ve "gia tri: " noi voi '
        'str(list[idx]).',
    'count_not_equal(a: i32, n: i32) -> i32:':
        'Tao list gom cac so tu 0 den n-1, duyet list va DEM so phan tu MA khong bang a '
        '(dung "not (phan_tu == a)"), tra ve so dem do.',
    'running_total_capped(n: i32, cap: i32) -> i32:':
        'Dung 1 bien tong bat dau tu 0, vong lap i tu 0 den n-1: tong += i (gan rut gon). '
        'Neu tong > cap thi break ra khoi vong lap ngay. Tra ve tong cuoi cung.',
}

RESUME_SIGS = [
    'unique_char_count(s: str) -> i32:',
    'list_max(a: i32, b: i32, c: i32) -> i32:',
    'list_count_even(n: i32) -> i32:',
    'dict_sum_values(a: i32, b: i32, c: i32) -> i32:',
    'dict_has_key_report(a: i32, key_present: i32) -> str:',
    'list_of_squares_sum(n: i32) -> i32:',
    'gcd_like_mod(a: i32, b: i32) -> i32:',
    'clamp_report(x: i32, lo: i32, hi: i32) -> str:',
    'safe_index_report(n: i32, idx: i32) -> str:',
    'count_not_equal(a: i32, n: i32) -> i32:',
    'running_total_capped(n: i32, cap: i32) -> i32:',
]

results_path = Path(__file__).parent / 'alphaai_batch_port_18_results.json'
existing = {r['signature']: r for r in json.loads(results_path.read_text(encoding='utf-8'))}

new_results = []
t_start_all = time.perf_counter()
for sig_line in RESUME_SIGS:
    desc = ALL_TASKS[sig_line]
    print(f'--- {sig_line}')
    t0 = time.perf_counter()
    r = generate_and_verify(desc, sig_line, provider='groq', max_attempts=3)
    dt = time.perf_counter() - t0
    print(f'    success={r["success"]} attempts={len(r["attempts"])} time={dt:.1f}s')
    if not r['success']:
        print(f'    LOI CUOI CUNG: {r["error"]}')
    entry = {'signature': sig_line, 'task': desc, 'success': r['success'],
              'attempts_used': len(r['attempts']), 'body_lines': r['body_lines'],
              'error': r['error'], 'time_sec': round(dt, 1)}
    new_results.append(entry)
    existing[sig_line] = entry  # cap nhat ngay, khong doi het vong lap

total_time = time.perf_counter() - t_start_all

# Ghi lai theo DUNG thu tu 18 ham goc.
ordered = list(existing.values())
results_path.write_text(json.dumps(ordered, ensure_ascii=False, indent=2), encoding='utf-8')

n_ok_resume = sum(1 for r in new_results if r['success'])
n_ok_total = sum(1 for r in ordered if r['success'])
print(f'\n=== LAN NAY (11 ham resume): {n_ok_resume}/{len(RESUME_SIGS)} thanh cong ===')
print(f'=== TONG CA 18 HAM: {n_ok_total}/18 thanh cong ===')
print(f'=== Thoi gian lan resume: {total_time:.1f}s ===')
print(f'Ket qua chi tiet: {results_path}')
