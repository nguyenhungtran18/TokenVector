# BAN GIAO 2026-10-09 (phien 4) — list() + tuple() XONG

**Nguoi viet**: phien opencode thu 4 trong ngay.
**Trang thai xuat phat**: gate ~96/118, NEG 6/31, vong tu-host IL_IDENTICAL.
**Trang thai ket thuc**: gate ~99/118, NEG 6/31, vong tu-host IL_IDENTICAL.

---

## 1. Da lam trong phien nay

| # | Viec | Ket qua | Commit |
|---|---|---|---|
| 1 | `record_method_name_collision_test` | 18/18 PASS (truoc do BUILDFAIL) | `d9c98c5` |
| 2 | Chap nhan `-> "None"` (tra ve vo huong) | `record_init_runs_test` BUILDFAIL -> 9/11 | `be058ea` |
| 3 | Port `list()` constructor | `list_ctor_test` 10/10 PASS | `77ec891` |
| 4 | Port `tuple()` constructor | `tuple_ctor_test` 10/10 PASS | `d062de9` |

Luu y: `fstring_bigint_test` 12/12 PASS duoc phat hien da xong truoc phien nay
(khong can sua gi) — chi ghi nhan trong plan.

---

## 2. Chi tiet ky thuat (doc truoc khi sua lai)

### 2.1. `record_method_name_collision` — macro `dict.update` chiem Record (d9c98c5)

**Hien tuong**: `b = Bag(0)` roi `b.update(other)` (other la bien int) bao
`len() hien CHI ho tro list/dict/... ('__iterlist0_src' co dtype='int')`.

**Nguyen nhan**: macro TEXT-LEVEL `try_expand_dict_update` (dict_type.tkv)
match moi cau `X.update(Y)` va viet lai thanh `for k in Y: X[k] = Y[k]`.
Voi `Y` la bien int, macro van chay -> sinh ra `for k in <int>:` -> desugar
tao bien an `__iterlist0_src` -> `len()` khong biet kieu.

**Cach sua** (khong sua macro thanh thong minh hon, ma cho no TU CHOI):
1. Them getter `is_known_record_var(name) -> "i32"` trong `control_flow.tkv`
   (doc global `_known_record_vars` da co tu truoc).
2. Trong `try_expand_dict_update`, neu receiver (ten ben trai) nam trong
   `_known_record_vars` -> `return None` (decline, de method_call_stmt xu ly).

**Tai sao dung duoc**: `_expand_macros` (il_codegen.tkv:~5257) da quet truoc
tap bien la record (tham so kieu record + local gan tu constructor record)
va goi `set_known_record_vars` TRUOC khi macro chay.

**Regression da check**: `d = {"a": 1}; extra = {"b": 2}; d.update(extra)`
van cho `len(d) == 2`.

### 2.2. `-> "None"` / `-> None` (be058ea)

`record_init_runs_test` khai `def __init__(self, a: "i32") -> "None":`.
Parser `parse_type_ann` trong `typed_dsl_parser.tkv` chi nhan
`DTYPES` + alias + record + extern-class; `None` khong nam trong do -> loi
`Ky vong dtype (f32/f64/i32/i64/str), gap 'None'`.

**Cach sua**: them nhanh giong `bool` — `None` -> `TypeAnn('i32', None)`.
Ham van return 0 nhu cu. Sua 6 dong, khong anh huong loi nao khac.

**Con lai**: 2/11 fail (`field cua base (qua __init__ base)` got 0 exp 103,
`field rieng: __init__ con bi bo qua` got 6 exp 3) — can port
`_ctor_init_body_il` (than `__init__` phai chay THAT, hien bi bo qua).
Day la feature vua, khong phai sua 1 dong.

### 2.3. `list()` constructor (77ec891)

**Hien tuong**: `a = list()` bao `list(X) trong bieu thuc can X la 1 BIEN
list/set/dict hoac loi goi ham tra list`.

**Da port** (trong `il_features/list_type.tkv`):
- `_LIST_CALL_RE = ^list\(([^()]*)\)\s*$` va `_BIEN_DON_RE = ^\w+$`
- `try_rhs_list_call(rhs, name, known_shapes) -> "i32"` — RHS parser:
  - `list()` -> stmt `assign_list_new` (tai dung duong `[]` san co)
  - `list(ys)` -> stmt `assign_list_from(name, src)`, co bao loi ro rang neu
    argument khong phai dang `\w+`
- `fpw_assign_list_from` + `codegen_assign_list_from`
- Dang ky 3 cho trong `bootstrap_list_type`

**BAT 1**: khong dung `re.match(r'^\w+$', src)` — `re.match` voi CHUOI MAU
khong hoat dong (gay loi `bien None chua duoc khai bao/tham so`). PHAI
compile regex thanh bien toan cuc truoc.

**BAT 2**: `m.groups()` khong dung duoc doc lap — compiler bao
`m.groups() chi dung duoc o ve phai cua mot phep gan giai nen`. Cach lam
dung: `src_tup = m.groups()` roi `src_tup[0]`. (Xem them 2.4 Bat 3.)

### 2.4. `tuple()` constructor (d062de9)

**Hien tuong**: `t = tuple([5, 6, 7])` bao `'p, q, r = ...' voi 1 gia tri ben
phai phai la 1 loi goi ham TRA VE TUPLE 3 phan tu`.

**Kien truc tu Python bootstrap giu nguyen**: `tuple` cua TokenVector la
`System.ValueTuple<T1..TN>` — SO PHAN TU CO DINH 2..7 biet luc bien dich.
Vi vay `tuple()` rong va `tuple(xs)` (xs la bien list) PHAI bao loi.

**Da port** (trong `il_features/tuple_type.tkv` + `stmt_row.tkv`):
- `_TUPLE_CALL_RE = ^tuple\((.*)\)\s*$`, `_BIEN_DON_RE_TC = ^\w+$`
- `try_rhs_tuple_call`:
  - `tuple()` -> raise (message CO chu "ValueTuple" — negative test
    `tuple_empty_call` doi chieu bang EXPECT-SUBSTRING)
  - `tuple(u)` -> stmt `assign_tuple_identity(name, u)`
  - `tuple([a, b, c])` -> doi VAN BAN thanh `(a, b, c)`, tra ve
    `assign_scalar(name, '(a, b, c)')` — tai dung nguyen duong codegen cua
    literal san co. Do dai duoc kiem tra bang `_tach_phay_muc0` (< 2 -> loi).
  - `tuple((a, b))` -> giu nguyen van ban (da la tuple literal)
  - con lai -> raise keo theo goi y
- `fpw_assign_tuple_identity` + `codegen_assign_tuple_identity`
- stmt kind `assign_tuple_identity` khai o **2 CHO** trong `stmt_row.tkv`:
  - `_LAYOUT` (bo nho truong): `"name,src"`
  - `_KHOA_LOGIC` (khoa logic cho ham duyet chung): `"kind,name,src"`
  Thieu `_KHOA_LOGIC` -> loi `Index was out of range` luc compile.

**BAT 3 (quan trong nhat cua phien)**: `known_shapes` CHI BAO GIO ghi
`'tuple'` — no chi ghi shape container (list/set/dict/bytearray/bytes/...),
vi `_result_container_shape` khong tra ve 'tuple'. Da thu them vao
`_result_container_shape` (il_codegen.tkv:5684):

```
if ekind(rhs_node) == 'tuple_lit':
    return 'tuple'
```

Ket qua: compile MAY CUOI giong hat loi `Index was out of range. Must be
non-negative...`. Da REVERT, khong bao gio lam lai theo cach nay. Nguyen nhan
chua biet that — kha nang co bo nao do index theo gia tri shape.

Giai phap cuoi: parser tra stmt identity cho MOI ten dang `\w+`, va FIRST
PASS (`fpw_assign_tuple_identity`) kiem tra kieu that qua `infer_scope`
(co day du thong tin). Loi van ro rang, chi la o luon khac.

---

## 3. Gate hien tai (chua chay lai toan bo, so lieu tu tung test)

- Vong tu-host `tools\vong.exe`: **IL_IDENTICAL** (chay duoc lien tuc sau
  moi commit xong viec).
- Test da xac minh PASS: `record_method_name_collision` 18/18,
  `list_ctor` 10/10, `tuple_ctor` 10/10, `fstring_bigint` 12/12,
  `record_init_runs` 9/11, `dict_literal`, `dict_update`, `counter`,
  `record_container_field`, `set_iteration`, `conditional_expr`.
- Con FAIL (da biet, khong phai regression moi):
  - `conditional_expr_test`, `set_literal_test` — hang so float
    (`'1.5' kieu 'int' chi ho tro dang thap phan`)
  - `kwargs_enumerate_test` — `AST node khong ro: 1000351`
  - `agg_key_test` — `AST node khong ro: 1000699`
  - `comprehension_multi_for_test` — `ternary dang Python thieu 'else'`
  - `record_method_name_collision` con 2/11 o `record_init_runs`
  - `decorator_py_tree_test` — signature wrapper khong khop (int/i32)
  - `funcvar_test` — `reduce` signature (int/i32), can thiet ke type system
  - `list_literal_test.tkv` KHONG TON TAI (dung coi dau hieu khi scan bang vong lap!)

---

## 4. Viec tuc an (phien sau)

Theo thu tu khuyen nghi:

1. **Chay gate day du truoc khi sua gi khac**:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\testkit_gate.ps1`
   (nen chay nen `Start-Process`, log ra `%TEMP%\opencode\gate*.log`).

2. **`enumerate(start)` + `print(sep=, end=)`** (`kwargs_enumerate_test`) —
   parser `il_core._parse_one_call_arg` da tra `('kwarg', ten, expr)` dung tu
   2026-08-28; thieu o tang su dung cua stdlib. Can kiem tra
   `stdlib_itertools.tkv`.

3. **`key=` / `reverse=` cho min/max/sum/sorted** (`agg_key_test`) —
   macro text-level `min/max` trong `stdlib_aggregates.tkv` dem dau phay nen
   `max(xs, key=f)` bi viet lai thanh ternary `(xs > (key=f) ? xs : (key=f))`.
   Can detect kwarg va decline (giong cach da sua cho dict.update).

4. **Multi-for comprehension** (`comprehension_multi_for_test`) —
   macro `_FOR_IN_LIST_RE` chi match 1 vong for; vong thu hai bi long vao
   ITERABLE.

5. **Ternary-arg garbage** (Phase 1) — `pick(c ? 10 : 20)` ra rac
   `5238616/9564008/23713280`. Da thu sua `_expr_ternary` (infer natural
   dtype + `_widen_if_needed`) -> crash native `0xC0000005` trong
   `gen_il_function`. Da REVERT, giu ban on dinh.

6. **Viec con lai trong PLAN-TU-HOST.md** Phase 2 (question_ternary,
   yield from, try/except/else) va Phase 3/4.

---

## 5. Quy uoc can nho

- Khong sua trong `compiler/`, `dist/`, `build/` — content la Python.
- `tokenvector-grammar` la submodule dirty co san — khong stage/commit.
- Sau MOI commit xong viec, chay `tools\vong.exe` va muc tieu
  `IL_IDENTICAL` (chay 1 lan thuong du neu khong co thay doi codegen).
- Doc loi tu `build\selfhost\g1.exe.log` / `g2.exe.log` (vong.exe chi bao
  `LOI dich ... xem ...log`).
- Neu gap loi `bien None chua duoc khai bao/tham so` hoac
  `Index was out of range` — nghi TRUOC: regex chua compile, hoac
  `.groups()` doc lap, hoac stmt kind thieu `_LAYOUT`/`_KHOA_LOGIC`.
- `m.group(1)` hoat dong tot; `m.groups()` chi dung duoc khi gan vao bien
  truoc, hoac unpack `a, b = m.groups()`.

---

## 6. File lien quan

- `D:\TokenVector\compiler_bootstrap\compiler\il_features\list_type.tkv` — `try_rhs_list_call`, `fpw_assign_list_from`, `codegen_assign_list_from`
- `D:\TokenVector\compiler_bootstrap\compiler\il_features\tuple_type.tkv` — `try_rhs_tuple_call`, `fpw_assign_tuple_identity`, `codegen_assign_tuple_identity`
- `D:\TokenVector\compiler_bootstrap\compiler\il_features\control_flow.tkv` — `is_known_record_var`
- `D:\TokenVector\compiler_bootstrap\compiler\il_features\dict_type.tkv` — `try_expand_dict_update` (guard record)
- `D:\TokenVector\compiler_bootstrap\compiler\typed_dsl_parser.tkv` — nhanh `None`
- `D:\TokenVector\compiler_bootstrap\compiler\stmt_row.tkv` — `_LAYOUT` + `_KHOA_LOGIC`
- `D:\TokenVector\PLAN-TU-HOST.md` — tieu do ghep
