# HANDOFF 2026-10-11 - star-args, keyword tren method, coerce container

**Trang thai khi ban giao**: gate **117/118**, **NEG 31/31**, `vong` **IL_IDENTICAL**
(132 file), parity 119/119, dang_ky 0 violation, lint 8/8, ext_smoke 4/4.

> Handler cuoi: `PLAN-TU-HOST.md` (da viet lai ngay - ban cu bi double-encode
> khong khoi phuc duoc).

---

## 1. Con lai 2 test

### 1.1 `nested_literal_test` - BUILDFAIL

```
il_codegen: dict literal '{k: v, ...}' hien chi dung duoc khi kieu dict da biet
```

Test can 7 dang: list chua dict, list chua set, dict co gia tri la list/dict/set,
set chua list, long 3 cap.

Port tu Python (`compiler/il_features/{list,dict,set}_type.tkv`) can lam:

1. `dict_literal_spec_of(pairs, ...)` - suy `dict[K,V]` tu noi dung literal (de quy).
2. `codegen_expr_dict_literal` - `newobj Dictionary<K,V>` + `dup`/key/val/`set_Item`.
3. `codegen_expr_set_literal` - tuong tu cho HashSet.
4. `list_literal_elem_spec_of` - nhan them nhanh `dict_literal` / `set_literal`
   (Python list_type.tkv:577-627).
5. `il_list_elem_ilstr` - chap nhan CHUOI MANG SHAPE, uyen cho `il_container_type_of_spec`.
6. `il_container_type_of_spec` ban tu-host **CHUA co nhanh `set[...]`**.
7. Duong GAN `d = {...}` da co san (macro text `try_expand_dict_literal` trong
   `tuple_type.tkv`) - nen phan lon cong viec la o duong **bieu thuc**.

Bootstrap Python de doi chieu:
`dist\tkvc.exe build tests\nested_literal_test.tkv --entry run` -> 7/7 PASS.

### 1.2 `p6_vectorize_test` - ILFAIL (`stobj`, `_vstart`, `_tstart`)

Test PASS runtime (duong scalar dung) nhung IL thieu kieu hieu vector hoa.
Can port `_p6_vectorize_while` tu Python sang
`compiler_bootstrap/compiler/il_features/control_flow.tkv`.
Gate kiem bang `--emit-il` va do chuoi trong `.il` (xem `$ilChecks` trong
`tools/testkit_gate.ps1`).

---

## 2. Da lam trong phien nay

| Muc | Ket qua |
|---|---|
| `f(*xs)` / `f(**kw)` | `star_args_test` 11/11, `star_kwargs_test` 11/11 |
| 5 negative star | `star_args_dynamic_src`, `star_kwargs_duplicate`, `star_kwargs_dynamic_src`, `star_kwargs_list_src`, `star_kwargs_unknown_key` |
| Keyword argument tren method (`Box(5).two(a=1)`) | sua `_parse_call_args_m` dung `_parse_one_call_arg` |
| Crash `k2(z=1)` | comprehension ghep trong f-string -> gom ra bien truoc (4 noi) |
| `parity_pin_test` | bat container coerce `list[int]` <-> `list[i32]` |

File moi: `compiler_bootstrap/compiler/il_features/call_star_args.tkv`
(khai trong `compiler_src/ds_gop.txt`, 132 file).

---

## 3. Bai hoc - DOC TRUOC KHI SUA SOURCE

1. **KHONG BAO GIO `Get-Content -Raw | Set-Content -Encoding UTF8`** tren file
   `.tkv`. PS 5.1 doc bang CP1252 -> double-encode + BOM; byte undefined mat
   khong khoi phuc. Chi dung `edit`/`write`.
2. **`dist\tkvc-tv.exe` hong -> khoi phuc tu IL**:
   `ilasm build\selfhost\tv2s.il /output=C:\Temp\restore.exe`
   (`C:\Windows\Microsoft.NET\Framework\v4.0.30319\ilasm.exe`), roi
   `Copy-Item` ve `dist\tkvc-tv.exe`.
3. **Bootstrap bang STUB** khi compiler hien tai khong compile duoc module moi
   (module that -> stub `return body_lines` -> `vong` -> khoi phuc module ->
   `vong` lai). KHONG dung `dist\tkvc.exe`: khong ho tro module-level container.
4. `vong.exe` bao loi o `g1` = `dist` hong; o `g2` = compiler vua sua co bug.
5. Doc `expr_layout.tkv` truoc khi dung `ea_*`: `'index:1'` la **str** (ten bien)
   chu khong phai node - doc `ea_nut` vao se chet `FormatException`.
6. ValueTuple khong co indexer: `_f(...)[1]` -> bo tuple ra bien.
