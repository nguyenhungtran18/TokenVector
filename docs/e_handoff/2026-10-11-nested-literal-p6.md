# HANDOFF 2026-10-11 (phien 8) - GATE PASS 118/118 + NEG 31/31

**Trang thai khi ban giao**:
- `testkit_gate.ps1`: **GATE: PASS (118/118, NEG 31/31)** — BUILDFAIL=0,
  TESTFAIL=0, OTHER=0, TIMEOUT=0, **ILFAIL=0**
- `tools\vong.exe`: **IL_IDENTICAL** (132 file)
- `parity_probe/run.ps1`: **119/119**
- `dang_ky_gate.py`: **PASS** (0 violation)
- `lint_rules_gate.ps1`: **8/8**
- `ext_smoke.ps1`: **4/4**

> Handler cuoi: `PLAN-TU-HOST.md`.

---

## 1. Xong: `nested_literal_test` 7/7

Gate 117/118 -> 118/118. Chi tiet port o muc 3.

---

## 2. Xong (lan 3): `p6_vectorize_test` 17/17 + IL day du

`ILFAIL` 1 -> 0. Gate in **GATE: PASS**.

### Loi CHOT duoc sau 2 lan hoan nguyen

| # | Loi | Nguyen nhan |
|---|---|---|
| 1 | `AccessViolationException` | Node arena la CHI SO (i32); moi o con cua `mk2/mk3/mk4` (khai `str`) phai boc **`o_nut(node)`** |
| 2 | `NullReferenceException` luc chay | Dieu kien vong vector phai bien dich o **kieu THAT cua bien dem** (`scope.tra(iv).ta.dtype`), **KHONG** hard-code `'i32'`. `i` trong test la `int` = TkvInt (16 byte) -> ghi 4 byte vao local 16 byte, truong `big` con rong -> `NullReferenceException` |
| 3 | Toan tu sai | `compare`/`binop`: toan tu o **FIELD 1** (`ea_str`), so hang o field 2/3 (`eb_nut`/`ec_nut`); arena chi co toi da 3 o (khong co `ed_nut`) |
| 4 | Treo khi truyen list | `o_ds` nhan `list[TkvNode]`; moi danh sach moi phai la bien co **khai bao kieu**, khong dung list literal. Tuong tu cho `codegen_stmts_fn` |
| 5 | Bien 1 kieu | `idx_st = None` roi `idx_st = <chi so>` bi tu choi — dung `-1` lam co hieu |

**Ghi chu quan trong**: goc cua loi #2 KHONG phai intrinsic. Da probe
`v_load4`/`v_store4` goi TRUC TIEP tu nguon nguoi viet — chay dung binh thuong.
Goc cua loi #2 la **kieu cua bieu thuc do moi sinh ra**, khong phai ham.

### Port da dua vao `control_flow.tkv`

`_p6_num_is_one`, `_p6_var_is`, `_p6_vec_rhs_ok`, `_p6_is_f32buf`,
`_p6_chi_so_la_iv`, `_p6_viet_lai_rhs`, `_p6_vectorize_while` + moi noi goi
dau tien trong `codegen_while`. Van toan bo quy tac "hoi nghi = tu choi" cua ban
Python (chi nhan `i < n` voi hai bien tran, than DUNG HAI lenh, moi `f[i]` dung
chung `iv`, ve phai chi gom `v_load4` + `+ - * /`).

### Biet khi nao phai HOAN NGUYAT

Neu port P6 lam compiler **treo vo han** hoac bien dich sai (test FAIL), revert
ngay (`git checkout -- compiler_bootstrap/compiler/il_features/control_flow.tkv`)
va giu gate o trang thai da xanh - con ILFAIL hon la lam hong compiler.

---

## 3. Port `nested_literal_test` (chi tiet muc 1 cua ban giao truoc)

Test can 7 dang container literal long nhau. Da port day du:

| File | Thay doi |
|---|---|
| `compiler_bootstrap/compiler/il_core.tkv` | Parse `{` **khong co `:`** -> node moi `set_lit` (truoc bat buoc `expect_op(':')`) |
| `compiler_bootstrap/compiler/expr_layout.tkv` | `'set_lit:1': 'ds'` |
| `compiler_bootstrap/compiler/il_features/list_type.tkv` | `_split_container_spec`, `ta_tu_spec`, `ta_to_spec`, `ta_elem_spec`, `_fold_spec_widen`, `dict_literal_spec_of`, `_spec_elem_lit`, `_spec_ds_lit`, `_spec_container_literal_of`, `codegen_expr_dict_lit` (thay stub), `codegen_expr_set_lit` (moi); `il_list_elem_ilstr` chap nhan shape-string; `il_container_type_of_spec` them `set[...]` |
| `compiler_bootstrap/compiler/il_features/comprehension.tkv` | Macro `try_expand_set_literal` chi bo qua khi `_tach_phay_ngoai` tra **DUNG MOT** phan tu bat dau bang `[`/`{` |
| `compiler_bootstrap/compiler/il_features/dict_type.tkv` | `find_first_dict_assign_value_ta` nhan them `d[k] = <container literal>` |
| `compiler_bootstrap/compiler/il_features/set_type.tkv` | `declare_set` lay `elem_ta` day du; `codegen_set_add` / `codegen_assign_set_new` / `codegen_assign_frozenset_*` dung `il_type_str` thay `il_set_type(ta.dtype)` |
| `compiler_bootstrap/compiler/il_features/set_to_list.tkv` | `_to_list_return_ta` giu `elem_ta` |
| `compiler_bootstrap/compiler/il_codegen.tkv` | `il_type_str` cho `shape_ten in ('set','frozenset')` de quy qua `elem_ta` |

### Bai hoc - 6 loi "bien dich xong nhung hong bo nho" (dung 1 kieu goc)

1. **`HashSet` nam o `[System.Core]`, KHONG phai `[mscorlib]`** nhu `List`/`Dictionary`
   -> `TypeLoadException`.
2. **`HashSet<T>.Add` tra `bool`, khac `List<T>.Add` (void)** -> phai `pop` sau moi
   `Add`, neu khong set tren stack se ban.
3. **`ta.dtype` chi la LEAF** - `TypeAnn('int','list', elem_ta=<dict>)` co `dtype='int'`.
   Moi noi goi `il_set_type(ta.dtype)` se sinh `HashSet<TkvInt>` lech voi local khai
   `HashSet<List<TkvInt>>` -> `AccessViolationException`. Dung `ctx.il_type_str(ta)`.
4. **`ta_list_spec` chi de quy 1 tang `list[...]`** - voi phan tu `dict`/`set` no tra
   `list[int]`, ghi sai kieu vao `List<Dictionary<..>>` -> doc nho RAM trong
   `Dictionary::FindEntry`. Da thay bang `ta_to_spec` (de quy ca 3 loai, giong Python).
5. **`value_dtype_spec_for_ta` co dieu kien "chi khi phan tu la list"** -> bo, chuyen
   sang `ta_to_spec` cho moi container (dieu kien cu chuyen nhan GIA TRI dict la
   dtype cua GIA TRI, khong phai khoa).
6. **`_spec_ds_lit` phai de quy cho phan tu la container literal** - `[{"n":1},{"n":2}]`
   (long 3 cap) se tra `''` neu chi nhan hang so/chuoi.

---

## 4. Bai hoc ky thuat chung (vong nhieu)
- Node trong arena PHAI ma hoa o: `mk2('var', o_str(ten))`,
  `mk3('call', o_str('v_load4'), o_ds(args))`. Truyen chuoi tho -> doc sai o ->
  `AccessViolationException`.
- **Bieu thuc do bien dich SANG PHAI dung kieu cua noi no se GAN VAO**, khong
  hard-code: `ctx.compile_expr(node, ..., 'i32', ctx)` roi `store_var` vao mot
  local kieu `int` se lam hong bo nho.
- Toan tu cua node `compare`/`binop` nam o FIELD 1 (`ea_str`), con so hang o
  field 2/3 (`eb_nut`/`ec_nut`) - dung `eb_str` se tra ve **chi so node**.
  Node arena **chi co toi da 3 o**, khong co `ed_nut` (field 4).
- **Mot bien chi ghu MOT kieu**: `idx_st = None` roi `idx_st = <chi so>` bi tu choi
  (`khong ho tro None`). Dung `-1` lam co hieu.
- **MOI danh sach truyen cho 1 tham so co khai bao kieu phai la bien da khai
  bao kieu** - truyen list literal se bi suy sai (`list[TkvInt]`) va lam lenh
  goi sinh IL sai / treo.
- `edit` tool **co the lam mat thut dong** khi `newString` viet sai - luoi chay
  `Select-String -Pattern "^[^ ]"` de bat dong 0 o dau function.
- KHONG dung `Get-Content -Raw | Set-Content -Encoding UTF8` (xem handoff truoc).

---

## 5. Muc tieu: DA DAT

Gate 118/118 + NEG 31/31 + IL_IDENTICAL + tat ca gate phu xanh.