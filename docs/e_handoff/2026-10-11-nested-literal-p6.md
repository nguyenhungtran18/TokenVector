# HANDOFF 2026-10-11 (phien 8) - nested literal XONG, p6 vectorizer CHUA PORT xong

**Trang thai khi ban giao**:
- `testkit_gate.ps1`: **PASS=118/118**, BUILDFAIL=0, TESTFAIL=0, OTHER=0, TIMEOUT=0, **ILFAIL=1**, **NEG 31/31**
  (chi con 1: `ILFAIL p6_vectorize_test.tkv -> stobj, _vstart, _tstart`)
- `tools\vong.exe`: **IL_IDENTICAL** (132 file)
- `parity_probe/run.ps1`: **119/119** khop CPython
- `dang_ky_gate.py`: **PASS** (0 violation)
- `lint_rules_gate.ps1`: **8/8**
- `ext_smoke.ps1`: **4/4**

> Handler cuoi: `PLAN-TU-HOST.md`. Loi cu cua tai liet ke trong file do.

---

## 1. XONG trong phien nay: `nested_literal_test` 7/7

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

## 2. CHUA xong: `p6_vectorize_test` (ILFAIL)

Test PASS runtime (duong scalar dung) nhung IL thieu `stobj`/`_vstart`/`_tstart`
=> `_p6_vectorize_while` (SIMD buoc 4 tren `f32buf`) **chua duoc port**.

**Da thu va DA HOAN NGUYAT** (`git checkout -- control_flow.tkv`) vi no lam
compiler **treo/ca chet**. Cac loi da gap theo thu tu:

| # | Loi | Nguyen nhan |
|---|---|---|
| 1 | `AccessViolationException` khi bien dich `while i < n: r[i] = a[i]` | Node trong arena phai **ma hoa o bang `o_str`/`o_nut`/`o_ds`** - truyen chuoi tho vao `mk2/mk3/mk4` doc sai o -> doc nho ngoai vung |
| 2 | `AccessViolationException` | `codegen_stmts_fn([inc4], ...)` voi **LIST LITERAL** - tham so khai `func(list[i32],...)` nen list literal bi suy `list[TkvInt]` -> lenh goi sai IL |
| 3 | `make2('assign_scalar', iv)` | `assign_scalar` luu **2 o** (`name,rhs_text`) - phai `make3` |
| 4 | **Compiler TREO vo han** | Emit phan tang `iv` bang `ctx.compile_expr(...)` + `ctx.store_var(iv, ...)`, hoac `codegen_stmts_fn` voi list goc `idx_st`/`inc_st`. Bisect cho thay **van treo ngay ca khi BO HET vong duoi scalar** - nghi doan nam o `pop` / `compile_expr(iv+4)` / `store_var` |

**Huong tiep theo duy nhat an toan**: khong tu tao node cua `TkvNode` trong
`control_flow.tkv`; dung co che **`dat_nut` + `codegen_stmts_fn`** nhung phai
truyen mot bien co **khai bao kieu** (`x: "list[i32]" = []`) chu khong phai list
literal - va **do lai tu`v_store4` tro lai**, phai sua truoc phan `pop`/tang bien
mot cach duy nhat. Neu khong chot duoc, nen de nguyên ILFAIL va ghi vao
`PLAN-TU-HOST.md` (khong dung de lam hong compiler).

---

## 3. Bai hoc ky thuat (vong nhieu, doc truoc khi sua source)

- **Node trong arena PHIAI ma hoa o**: `mk2('var', o_str(ten))`,
  `mk3('call', o_str('v_load4'), o_ds([...]))`. Truyen chuoi tho -> doc sai o ->
  `AccessViolationException`.
- **Toan tu cua node `compare`/`binop` nam o FIELD 1** (`ea_str`), con so hang o
  field 2/3 (`eb_nut`/`ec_nut`) - dung `eb_str` se tra ve **chi so node**.
  Node arena **chi co toi da 3 o**, khong co `ed_nut` (field 4).
- **Mot bien chi giu MOT kieu**: `idx_st = None` roi `idx_st = <chi so>` bi tu choi
  (`khong ho tro None`). Dung `-1` lam co hieu.
- **`_kiecm o`**: `{}` chi duoc o ve phai phep gan, truyen truc tiep lam DOI SO bi
  tu choi -> can hang so cap module rong.
- **Signature cua `NguonKieu.infer_dtype`** phai viet dung
  `(TkvNode, Scope, dict[str,TkvSig], TkvTable, TkvTable, TkvTable)` - viet
  `dict[str,list[(str,TkvTypeAnn)]]` se lech chu ky.
- `edit` tool **co the lam mat thut dong** khi `newString` viet sai - luoi chay
  `Select-String -Pattern "^[^ ]"` de bat dong 0 o dau function.
- KHONG dung `Get-Content -Raw | Set-Content -Encoding UTF8` (xem handoff truoc).

---

## 4. Vi tri can sua tiep theo

```
compiler_bootstrap/compiler/il_features/control_flow.tkv   (codegen_while)
  -> can: _p6_num_val, _p6_vec_rhs_ok, _p6_vectorize_while
  -> tham chu ban Python: compiler/il_features/control_flow.tkv dong 1226-1382
```