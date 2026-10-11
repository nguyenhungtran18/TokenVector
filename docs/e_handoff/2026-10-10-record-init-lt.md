# BAN GIAO 2026-10-10 (phien 6) — record `__init__` + record `__lt__`

**Nguoi viet**: phien opencode thu 6.  
**Diem xuat phat**: HEAD `d720731`, gate **103/118**, NEG **10/31**, vong tu-host IL_IDENTICAL.  
`record_init_runs_test` 9/11, `record_lt_test` 14/16.

**Trang thai ket thuc**: gate **105/118**, NEG **10/31**, IL_IDENTICAL.  
Cac gate khac: parity 119/119, `dang_ky_gate` PASS, `lint_rules_gate` 8/8, `ext_smoke` 4/4.

**Chua commit** trong phien nay. Chinh sua dang nam trong working tree.

---

## 1. Da lam trong phien nay

| # | Viec | Ket qua | Gate |
|---|---|---|---|
| 1 | Port than `__init__` vao `.ctor` | `record_init_runs_test` 11/11 | 103 → 104 |
| 2 | Port nhanh `__lt__` cho so sanh record | `record_lt_test` 16/16 | 104 → 105 |

---

## 2. Ky thuat quan trong

### 2.1. Record `__init__` — da chon phuong an (A)

Ban tu-host truoc day bien dich `__init__` thanh method CIL rieng, roi
`_expr_call` tao `.ctor` roi goi them method do. Hai he qua sai:

- `Base::.ctor` khi ke thua khong chay than __init__ cua Base.
- `.ctor` va `__init__` khong cung so thu tu tham so neu них lech nhau.

Gio da chuyen sang kieu bootstrap Python: than __init__ duoc **noi vao `.ctor`**.

Cac file va diem chinh:

- `compiler_bootstrap/tkv_compile.tkv`
  - `DinhNghiaLop` them `init_sig`, `init_body`.
  - `_extract_record_def` boc `__init__` CO chu thich kieu.
  - `ChuongTrinh` them `record_init_sigs`, `record_init_bodies`.
  - `extract_program_file` go ca record cua file import.
  - `compile_tkv_cli` loc record nao noi duoc vao `.ctor`:
    ham `il_codegen._init_noi_vao_ctor(...)`.
    Neu noi duoc thi bo `__init__` khoi `record_methods_raw`.

- `compiler_bootstrap/compiler/il_codegen.tkv`
  - Them `_init_noi_vao_ctor`, `_split_method_il`, `_ctor_init_body_il`.
  - `gen_record_types(...)` nhan `record_init_sigs`, `record_init_bodies`.
  - `.ctor` tinh `.locals`, `.maxstack` tu than __init__ da dich, roi noi than do vao sau khi gan field.

Ham `_init_noi_vao_ctor(...)` chi tra 1 khi:

- Record khong co base field vo huong (neu co thi bo than va giu `.ctor` tu gan field).
- So tham so `__init__` bang so field non-container.
- Kieu tham so khop kieu field.
- Khong co tham so mac dinh (de tranh keyword argument; nhung truong hop nay giu nguyen co che cu).

**BAT LON da mat nhieu thoi gian**: khong sua `record_methods_raw` bang `.get()` roi
append tuple cu. Do se bi loi:

`Attempted to access an element as a type incompatible with the array`

Phai dung truy cap dict truc tiep va tuple-unpack:

```python
for _sig_line, _body_lines, _is_static in record_methods_raw[_rname]:
    if _ten_truoc_ngoac(_sig_line) != '__init__':
        _mr_moi.append((_sig_line, _body_lines, _is_static))
```

Neu co loi runtime kha nghi trong compiler tu host, them `print("MARK ...")`
tam vao `compile_tkv_cli`, `gen_record_types`, `gen_il_function`
de biet dang o phase nao. Nho xoa tat ca MARK truoc khi chay gate.

### 2.2. Record `__lt__` — port tu bootstrap Python

Truoc day nhanh record chi xu ly `==`/`!=`. Cac phep `<`, `>`, `<=`, `>=`
roi xuong duong so hoc chung va co the tra ket qua lech.

Da them trong `compiler_bootstrap/compiler/il_features/operators.tkv`:

- `<`: `left.__lt__(right)`
- `>`: `right.__lt__(left)`
- `<=`: `right.__lt__(left)` roi phu dinh
- `>=`: `left.__lt__(right)` roi phu dinh

Record phai co:

```python
def __lt__(self, other: "RecordCungKieu") -> "i32":
```

Test da phu truong hop RHS la `Record(...` inline, vi du `a < P(1)`.

---

## 3. Gia cua ngoai khong dung duoc ngay

- `D:\TokenVector.Data\tools\datagate.ps1` hien dang tro den duong cu:
  `D:\TokenVector\3.code\dist\tkvc.exe`. Vi vay chay DataGate hien FAIL
  vi khong tim thay compiler, khong phai do phien nay.

- `D:\TokenVector.Inference\tv\tests\inference_tests.tkv` build truc tiep bang
  `dist\tkvc-tv.exe` dang fail ngay ca tren baseline sach:
  `shape[0] khong hop le (shape=[])`. Khong phai regression.

---

## 4. Viec tuc an (phien sau)

Thu tu khuyen nghi:

1. `try_except_else_test` — test BUILDFAIL co ve gan voi da sua `try/except/else` truoc day.
2. `conditional_expr`, `star_args`, `star_kwargs`, `nested_literal`, `set_literal`.
3. `p6_vectorize_test` ILFAIL.
4. 21 NEG con lai (hien 10/31).
5. Wire hoac xoa `question_ternary.tkv` van la file chet trong `compiler_bootstrap`.
6. Nho chay lai tung gate sau moi thay dai:
   - `tools\vong.exe`
   - `tools\testkit_gate.ps1`
   - `tools\parity_probe\run.ps1`
   - `python tools\dang_ky_gate.py`
   - `tools\lint_rules_gate.ps1`
   - `tools\ext_smoke.ps1`

---

## 5. Quy uoc can nho

- Khong sua trong `compiler/`, `dist/`, `build/` khi chua can thiet.
- `tokenvector-grammar` dang dirty co san — khong stage/commit.
- Sau khi sua compiler, phai chay `tools\vong.exe` toi khi IL_IDENTICAL.
  Neu bi `IL KHAC NHAU` o vong dau, chay lai thuong la on dinh.
- Neu sua file trong `compiler_bootstrap/...` nhung chi goi truc tiep `dist\tkvc-tv.exe`
  tren `build\selfhost\tv_gop.tkv` co the dang dung nguon cu. Hay chay `vong`
  de gop lai nguon.
- Trong compiler, comment phai can bang ngoac.

---

## 6. File lien quan

- `compiler_bootstrap/tkv_compile.tkv`
- `compiler_bootstrap/compiler/il_codegen.tkv`
- `compiler_bootstrap/compiler/il_features/operators.tkv`
- `PLAN-TU-HOST.md`
- `tests/record_init_runs_test.tkv`
- `tests/record_lt_test.tkv`
- `build/selfhost/g1.exe.log`
- `build/selfhost/g2.exe.log`
