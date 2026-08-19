# -*- coding: utf-8 -*-
"""Muc #3 ke hoach phien truoc: chay AI-port QUY MO LON HON (15-20 ham
that, khong phai 5 ham nhu lan truoc) tren tu vung DA CO SAN (string/
dict/list/tuple/try-except/toan tu moi: %, +=, not, raise) - CHUA dung
record (AlphaAI chua ho tro ctx records, gioi han da biet). Do thoi gian
+ ty le thanh cong THAT (khong doan mo) de dua vao STATUS.md muc #4."""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from alphaai_codegen import generate_and_verify

# 18 ham, 3 nhom: xu ly chuoi, cau truc du lieu (list/dict dong), toan
# hoc/logic co dieu kien - deu dung THUAN tu vung da xac nhan hoat dong.
TASKS = [
    ('count_digits(s: str) -> i32:',
     'Dem so ky tu la chu so (0-9) trong chuoi s, tra ve so luong.'),
    ('reverse_str(s: str) -> str:',
     'Tra ve chuoi s theo thu tu NGUOC LAI (dung vong lap duyet tu cuoi ve dau, '
     'noi tung ky tu vao 1 chuoi ket qua).'),
    ('count_word_occurrence(s: str, ch: str) -> i32:',
     'Dem so lan ky tu ch (chuoi do dai 1) xuat hien trong chuoi s.'),
    ('is_palindrome(s: str) -> i32:',
     'Kiem tra chuoi s co doi xung (palindrome) khong, tra ve 1 neu co, 0 neu khong '
     '(so sanh ky tu dau voi ky tu cuoi, dan vao giua).'),
    ('longest_run_char(s: str) -> i32:',
     'Tim do dai day con lien tiep DAI NHAT gom cung 1 ky tu lap lai trong chuoi s, '
     'tra ve do dai do (i32). Neu s rong tra ve 0.'),
    ('char_freq_max(s: str) -> i32:',
     'Dung dict dem tan suat tung ky tu trong chuoi s, tra ve TAN SUAT LON NHAT '
     '(so lan xuat hien nhieu nhat cua 1 ky tu bat ky). Neu s rong tra ve 0.'),
    ('unique_char_count(s: str) -> i32:',
     'Dung dict de danh dau ky tu da gap, tra ve SO LUONG ky tu KHAC NHAU trong chuoi s.'),
    ('list_sum(n: i32) -> i32:',
     'Tao 1 list rong, dung vong lap them cac so tu 0 den n-1 vao list (moi so nhan 2), '
     'roi tra ve TONG tat ca phan tu trong list (duyet lai list de cong don).'),
    ('list_max(a: i32, b: i32, c: i32) -> i32:',
     'Tao 1 list rong, them 3 so a, b, c vao list, roi duyet list de tim va tra ve GIA TRI '
     'LON NHAT trong 3 so do.'),
    ('list_count_even(n: i32) -> i32:',
     'Tao list gom cac so tu 0 den n-1, duyet list va dem so luong phan tu CHAN '
     '(dung phep chia lay du % voi 2), tra ve so dem do.'),
    ('dict_sum_values(a: i32, b: i32, c: i32) -> i32:',
     'Tao 1 dict rong, gan d["x"]=a, d["y"]=b, d["z"]=c, roi tra ve TONG 3 gia tri '
     'trong dict (doc lai tung khoa).'),
    ('dict_has_key_report(a: i32, key_present: i32) -> str:',
     'Tao 1 dict rong, gan d["val"]=a. Neu key_present khac 0 THEM gan d["extra"]=1. '
     'Kiem tra "extra" in d, neu co tra ve chuoi "co extra", neu khong tra ve "khong co extra".'),
    ('list_of_squares_sum(n: i32) -> i32:',
     'Tao list rong, dung vong lap them binh phuong tung so tu 0 den n-1 vao list, '
     'roi duyet list de tra ve TONG tat ca binh phuong do.'),
    ('gcd_like_mod(a: i32, b: i32) -> i32:',
     'Dung vong lap while: trong khi b khac 0, tinh r = a chia lay du cho b (dung %), '
     'gan a = b, gan b = r. Khi vong lap ket thuc tra ve a (gia tri GCD kieu Euclid).'),
    ('clamp_report(x: i32, lo: i32, hi: i32) -> str:',
     'Neu x < lo, tra ve chuoi "duoi min: " noi voi str(lo). Neu x > hi, tra ve chuoi '
     '"tren max: " noi voi str(hi). Neu khong, tra ve chuoi "trong khoang: " noi voi str(x).'),
    ('safe_index_report(n: i32, idx: i32) -> str:',
     'Tao list gom cac so tu 0 den n-1. Trong khoi try, neu idx < 0 hoac idx >= n thi '
     'TU NEM raise IndexError("chi so ngoai pham vi"). Bat loi bang except IndexError: '
     'tra ve chuoi "loi: chi so khong hop le". Neu khong loi, tra ve "gia tri: " noi voi '
     'str(list[idx]).'),
    ('count_not_equal(a: i32, n: i32) -> i32:',
     'Tao list gom cac so tu 0 den n-1, duyet list va DEM so phan tu MA khong bang a '
     '(dung "not (phan_tu == a)"), tra ve so dem do.'),
    ('running_total_capped(n: i32, cap: i32) -> i32:',
     'Dung 1 bien tong bat dau tu 0, vong lap i tu 0 den n-1: tong += i (gan rut gon). '
     'Neu tong > cap thi break ra khoi vong lap ngay. Tra ve tong cuoi cung.'),
]

assert len(TASKS) == 18

results = []
t_start_all = time.perf_counter()
for sig_line, desc in TASKS:
    print(f'--- {sig_line}')
    t0 = time.perf_counter()
    r = generate_and_verify(desc, sig_line, provider='groq', max_attempts=3)
    dt = time.perf_counter() - t0
    print(f'    success={r["success"]} attempts={len(r["attempts"])} time={dt:.1f}s')
    if not r['success']:
        print(f'    LOI CUOI CUNG: {r["error"]}')
    results.append({'signature': sig_line, 'task': desc, 'success': r['success'],
                     'attempts_used': len(r['attempts']), 'body_lines': r['body_lines'],
                     'error': r['error'], 'time_sec': round(dt, 1)})

total_time = time.perf_counter() - t_start_all
out_path = Path(__file__).parent / 'alphaai_batch_port_18_results.json'
out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
n_ok = sum(1 for r in results if r['success'])
first_try_ok = sum(1 for r in results if r['success'] and r['attempts_used'] == 1)
print(f'\n=== TONG: {n_ok}/{len(results)} sinh+compile THANH CONG (cu phap that) ===')
print(f'=== Thanh cong NGAY LAN DAU: {first_try_ok}/{len(results)} ===')
print(f'=== Tong thoi gian: {total_time:.1f}s (trung binh {total_time/len(results):.1f}s/ham) ===')
print(f'Ket qua chi tiet: {out_path}')
