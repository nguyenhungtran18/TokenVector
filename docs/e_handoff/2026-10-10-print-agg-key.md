# BAN GIAO 2026-10-10 (phien 5) — print(sep=,end=) + key=/reverse=

**Nguoi viet**: phien opencode thu 5.
**Trang thai xuat phat**: gate 98/118, NEG 7/31, vong tu-host IL_IDENTICAL.
**Trang thai ket thuc**: gate **99/118**, NEG **10/31**, IL_IDENTICAL.

---

## 1. Da lam trong phien nay

| # | Viec | Ket qua | Commit |
|---|---|---|---|
| 1 | Port `print(sep=, end=)` | `kwargs_enumerate_test` 13/13 (truoc BUILDFAIL) | `1b071fc` |
| 2 | Port `key=`/`reverse=` cho min/max/sum/sorted | 3 NEG xanh, `agg_key_test` **van BUILDFAIL** (xem 2.4) | `2471670` |
| 3 | Bo macro `key_agg` (trung lap) | giup bo 1 nguon su that | `2471670` |

**Khong co regression**: 98 test PASS truoc phien van PASS sau phien.
3 NEG FAIL -> PASS, **0 NEG PASS -> FAIL**.

---

## 2. Chi tiet ky thuat (doc truoc khi sua lai)

### 2.1. `print(sep=, end=)` — thu tu HAI lenh `Console::Write`

Port tu `compiler/il_features/print_feature.tkv` sang TokenVector. Bai toan
nhieu nhat KHONG phai kiem tra xem `end` co ton tai, ma la **thu tu hai
lenh `call Write`**:

```
ldstr "A"                      <- doi so vua ghep xuong stack
call void Console::Write       <- lenh 1: DAY HET chuoi doi so (khong phai
                                 in - Write moi chi ghi ra)
ldstr ""                       <- bieu thuc `end`
call void Console::Write       <- lenh 2: moi la noi `end`
```

Neu chi ghi 1 lenh `Write` o cuoi (cach "dep" nhat la nghia) thi chuoi doi
so con treo tren ngan xep → CLR nem `InvalidProgramException` luc chay.
Da gap that, da sua. Comment trong file ghi ro dieu nay.

`print(end=...)` KHONG co doi so: chi 1 lenh `Write` (lenh dau se underflow).

### 2.2. Kwarg trong TokenVector

- Doc node: `ekind(a) == 'kwarg'`, ten = `ea_str(a)`, bieu thuc = `eb_nut(a)`.
- **KHONG dung dict `{ten: node}`** — kieu node (`TkvNode`) la alias cua so
  nguyen, khong gon nhu `str`. Thay bang 3 ham:
  `_kwarg_node(args, ten)` / `_co_kwarg(args, ten)` / `_tach_pos(...)`.
- Bien phu `sep_expr = None` roi gan se **khong chay** (first-pass kiem kieu
  bien). Doc lai tu `args_ds` moi lan dung.

### 2.3. `key=`/`reverse=` cho min/max/sum/sorted

Da port day du tu bootstrap Python sang `stdlib_aggregates.tkv` +
`stdlib_functional.tkv` (`emit_sort_by_key`, `sort_key_temp_names`).

**BA TAT KINH DIEN (da ton mat ~1.5 gio, ghi lai de khong lap):**

1. **`return <ham>()` trong ham khai bao void bi tu choi** →
   `ham: 'thieu return-type annotation'`. Phai tach:
   ```python
   _push_sum_key(...)
   return
   ```
2. **`{}` chi dung duoc o ve phai phep gan.** `func_table if func_table else {}`
   → loi `'{}' chi dung duoc o ve phai phep gan`. Phai `func_table or {}`.
3. **`Ctx` va `WalkCtx` KHONG cung layout.** Ham nhan `ctx: "Ctx"` ma duoc
   goi tu pass 1 se doc **SAI OFFSET** — `ctx.func_table` tra dict RONG ma
   KHONG bao loi. `_key_func` vì vay nhan `func_table: "dict[str,TkvSig]"`
   truc tiep thay vi con `ctx`.
4. **Comment co ngoac LECH se bi macro `minmax_2arg` quet trong TEXT** →
   `il_codegen: '(' o vi tri 60 khong co ')' dong khop`. Comment chay qua
   `_expand_macros` **truoc khi** duoc loai bo. Moi dong comment can CAN
   BANG ngoac.
5. **`il_tupleN_type` tra `class [mscorlib]System.Tuple\`N`** (REFERENCE),
   KHONG phai ValueTuple. `Item2` la **property** → phai
   `callvirt instance !1 {t}::get_Item2()`, `ldfld ::Item2` →
   `MissingFieldException` luc chay. (Cung loi nay con trong
   `list_methods_batch2.codegen_list_sort` — `.sort(key=g)` cung dang hong.)

**Macro `key_agg` (comprehension.tkv) da BIEN THANH DUONG DANH TINH THU HAI**
va da bo dang ky. Ly do: no viet lai `sorted(xs, key=f)` thanh
`__kN = list(xs)` + `__kN.sort(key=f)`, va `list(xs)` suy ra `i32` cho
`list[int]` → `fpw_list_sort` bao *"chu ky key ((int) -> int) khong khop"*.
Hai duong danh tinh cho cung mot tinh nang = moi fix phai lam 2 lan.

### 2.4. `agg_key_test` VAN FAIL — bug RIENG ve suy kieu list-literal

Sau khi port xong, 14/14 kiem tra chi con **1** chan:
```
il_codegen: sum(..., key=neg) - chu ky key ((int) -> int)
            khong khop dtype phan tu cua list (i32)
```

`xsum = [3, 1, 2]`:
- `dist\tkvc.exe` (bootstrap Python): suy ra `list[int]` → khop → PASS 14/14.
- `dist\tkvc-tv.exe` (tu-host): suy ra `list[i32]` → **khong khop**.

Day la **suy kieu sai list-literal**, KHONG phai loi cua `key=`. Docstring
`CLAUDE.md` ghi *"a list literal's dtype is `int`"* — cau do **SAI** cho
compiler tu-host.

**Da khoanh vong tim** (khong sua duoc an toan trong phien nay):
`declare_list_literal` → `list_literal_elem_spec_of` →
`nk.infer_dtype(el, ...)` tra `'i32'` cho node `('num','3')`, trong khi
`_literal_dtype_fallback` (cua chinh file do) tra `'int'`. Phai so sanh
`_infer_dtype` nhanh `num` cua `compiler/il_codegen.tkv` voi ban
`compiler_bootstrap/...` — **blast radius rat lon**: doi element dtype cua
MOI list-literal trong MOI file.

Kiem chung nhanh (2 file, khong can rebuild):
```
# tkvc-tv: loi "khong khop dtype phan tu cua list (i32)"
# tkvc.exe: PASS 14/14
```

---

## 3. Gate hien tai (`%TEMP%\opencode\gate_s5b.log`)

```
PASS=99  BUILDFAIL=15  TESTFAIL=4  OTHER=0  TIMEOUT=0  ILFAIL=1  NEG=10/31
```

**TESTFAIL (4)**: `parity_pin_test`, `question_ternary_test`,
`record_init_runs_test`, `record_lt_test`
**BUILDFAIL (15)**: `agg_key`, `comprehension_multi_for`, `conditional_expr`,
`decorator_py_tree`, `funcvar`, `gap_exc_gen`, `generator_yield_from`,
`meta_format`, `multiline_string`, `nested_literal`, `py_builtins`,
`set_literal`, `star_args`, `star_kwargs`, `try_except_else`
**ILFAIL (1)**: `p6_vectorize_test` → `stobj, _vstart, _tstart`

**NEG con lai (21)**: `abs_complex`, `break_in_try_finally`, `cond_mixed_types`,
`datetime_args`, `del_on_string`, `del_variable`, `delattr_not_supported`,
`for_tuple_pairs_var`, `fstring_bad_spec`, `generator_return_no_gen_ret`,
`getattr_missing_field`, `module_var_without_global`, `reassign_int_str`,
`record_container_uninit`, `star_args_dynamic_src`, `star_kwargs_duplicate`,
`star_kwargs_dynamic_src`, `star_kwargs_list_src`, `star_kwargs_unknown_key`,
`str_tuple`, `yield_from_bad_source`

**Xanh them trong phien nay**: `agg_bad_kwarg_name`, `agg_key_signature`,
`sorted_reverse_non_bool`.

---

## 4. Viec tuc an (phien sau) — theo thu tu khuyen nghi

1. **`xsum = [3, 1, 2]` phai la `list[int]`, khong phai `list[i32]`**
   (mo khoa `agg_key_test`). Bat buoc chay `tools\testkit_gate.ps1` +
   `tools\parity_probe\run.ps1` sau khi sua — blast radius lon.
2. **Multi-for comprehension** (`comprehension_multi_for_test`) —
   macro `_FOR_IN_LIST_RE` chi match 1 vong for.
3. **`question_ternary_test`** (TESTFAIL) + file chua track
   `compiler_bootstrap/compiler/il_features/question_ternary.tkv`.
4. **`p6_vectorize_test` ILFAIL** — vector hoa khong con chay.
5. Con lai trong `PLAN-TU-HOST.md` Phase 2 (`yield from`, `try/except/else`)
   va Phase 4 (21 NEG).

---

## 5. Quy uoc can nho

- Khong sua trong `compiler/`, `dist/`, `build/` — content la Python.
- `tokenvector-grammar` la submodule dirty co san — **khong stage/commit**.
- Sau MOI commit: `tools\vong.exe`, muc tieu `IL_IDENTICAL`.
  `IL KHAC NHAU` **khong phai loi** — `vong` tu thang cap `g2` vao `tv2s`,
  chay lai 1 lan la ra `IL_IDENTICAL`.
- Doc loi tu `build\selfhost\g2.exe.log` (hoac `g1.exe.log`).
- Comment trong compiler phai **can bang ngoac** (xem 2.3 #4).
- Ham nhan `ctx: "Ctx"` chi dung o **pass 2** (xem 2.3 #3).

---

## 6. File lien quan

- `compiler_bootstrap/compiler/il_features/print_feature.tkv` — `compile_print`, `_lay_kwarg`, `_emit_sep`, `_emit_str_arg`
- `compiler_bootstrap/compiler/il_features/stdlib_aggregates.tkv` — `_has_kwarg`, `_tach_pos`, `_key_func`, `_push_minmax_key`, `_push_sum_key`, `_push_sorted_key`, `_reverse_node_check`, `_sum_result_dtype`
- `compiler_bootstrap/compiler/il_features/stdlib_functional.tkv` — `sort_key_temp_names`, `emit_sort_by_key`, `_ds_phong_so`
- `compiler_bootstrap/compiler/il_features/comprehension.tkv` — macro `key_agg` **da bo dang ky**
- `compiler_bootstrap/compiler/il_features/stdlib_itertools.tkv` — ghi chu `enumerate(start)` do `comprehension.tkv` lo
- `compiler_bootstrap/compiler/il_features/list_type.tkv` — `list_literal_elem_spec_of` (noi can sua cho muc 4.1)
- `PLAN-TU-HOST.md` — tieu do ghep