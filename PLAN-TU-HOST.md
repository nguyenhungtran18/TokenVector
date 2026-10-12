# PLAN: TokenVector Tu-Host Day Du (118/118 + NEG 31/31)

**Ngay bat dau**: 08/10/2026
**Cap nhat cuoi**: 11/10/2026 (phien 8)
**Trang thai**: Gate **118/118** (PASS=118, BUILDFAIL=0, TESTFAIL=0, OTHER=0, TIMEOUT=0, ILFAIL=1), **NEG 31/31**, `vong` **IL_IDENTICAL** (132 file).
Gate khac: parity **119/119**, dang_ky **PASS** (0 violation), lint **8/8**, ext_smoke **4/4**.

> **File nay da duoc VIET LAI ngay 11/10/2026.** Ban cu bi double-encode
> (UTF-8 -> CP1252 -> UTF-8) tu mot lan `Set-Content -Encoding UTF8` o phien
> truoc; mot so byte undefined-trong-CP1252 da mat khong khoi phuc duoc
> (thay bang `?`). Noi dung duoc giu lai, chu ky chuan hoa lai.

---

## Con lai (1 muc)

| Test | Loai | Nguyen nhan |
|---|---|---|
| `p6_vectorize_test` | ILFAIL | Chua port `_p6_vectorize_while` (SIMD step-4 `v_load4`/`v_store4`) tu Python sang `control_flow.tkv`. Test PASS runtime (duong scalar dung) nhung IL khong co `stobj`/`_vstart`/`_tstart` |

Da **HOAN NGUYAT** mot lan port p6 (11/10) vi no lam compiler **treo vo han /
AccessViolation**. Chi tiet 4 loi da gap + huong tiep theo: xem
`docs/e_handoff/2026-10-11-nested-literal-p6.md` muc 2.

---

## Phien 11/10 (phien 8): nested literal - XONG 7/7

Gate **117/118 -> 118/118** (PASS het), NEG giu **31/31**. Chi con ILFAIL p6.

Port day du container literal long nhau: `set_lit` node moi trong parser,
`dict_lit`/`set_lit` o vi tri bieu thuc, suy kieu `ta_to_spec`/`ta_tu_spec`,
`HashSet` qua `[System.Core]`, va 6 loi "bien dich xong nhung doc nho RAM" lien
quan den `elem_ta`. Xem handoff muc 1.

---

## Phien 11/10: da xong

### 1. `f(*xs)` / `f(**kw)` - XONG 11/11 + 11/11, NEG 5/5

Khong port theo kieu Python (AST). Ly do da gap that:

1. Row arena cua TokenVector la **chuoi bat bien**; `stmt_row.dat_nut` chi ghi
   duoc khi truong co mat trong `_LAYOUT`, con `assign_scalar` luu ve phai bang
   VAN BAN (`rhs_text`) nen moi lan ghi de deu phai nho qua `_MEMO_NUT` - noi do
   khong duoc `_expand_macros` dat lai giua 2 pass.
2. Cay `dict`/`list` long nhau cua Python la danh sach TkvNode; `_expand_node`
   dang de quy tren dict khong co kieu tinh ngay duoc.

Giai phap: **module o tang VAN BAN** -
`compiler_bootstrap/compiler/il_features/call_star_args.tkv`, goi tu
`gen_il_function`/`gen_il_generator_function` TRUOC `_expand_macros`.

- Quet **CA THANH HAM 1 LAN** (noi cac dong bang `chr(10)`) chu khong tung dong:
  lenh goi nhieu dong, chuoi nhieu dong va comment deu khong quet dung khi
  tach theo tung dong. `expand_star_args_in_lines(body_lines, func_name)`.
- Phat hien `*`/`**` chi khi ky tu da emit gan nhat (bo khoang trang) la `(` hoac
  `,` - tach duoc `f(*xs)` khoi `a * b` / `xs[i] * n` / `res = a*b`.
- Bieu thuc nguon duoc quet lai de quy truoc khi phan loai, nen long nhau
  (`f(*g(*[1, 2]))`) chay.
- Nguon: list/dict literal ngay tai choi goi, hoac bien gan DUNG MOT literal
  trong ham nay va khong xuat hien o cho khac. Nguon khac bi tu choi bang thong
  diep khop nguyen van ban `nguon '*'/'**' phai la list/dict literal`.
- Moi trong `compiler_src/ds_gop.txt` (132 file). Module KHONG dang ky gi.

### 2. Keyword argument tren method call - XONG

`_parse_call_args_m` (nhanh `.ten(...)` tren BIEU THUC) dung `parse_expr` truc
tiep nen `Box(5).two(a=1)` bao `ky vong ')', gap '='`, trong khi `obj.meth(k=v)`
va `f(k=v)` binh thuong. Da doi sang dung CHUNG `_parse_one_call_arg` voi 2
duong goi ham - ca 3 duong nay gio cung 1 parser tham so.

### 3. Crash `k2(z=1)` (keyword argument khong ton tai) - XONG

Bien dich `0xC0000005` (AccessViolation). Nguyen nhan: **comprehension ghep thang
trong f-string**. `f"{[x + '!' for x in xs]!r}"` bien dich xong nhung cho MANH
RONG rong; ben trong `kwarg_resolve` (`{[p.name for p in sig_params]!r}`) lam
compiler chet.

- Comprehension chi hop le khi la TOAN BO ve phai cua phep gan ra 1 TEN DON
  tren MOT dong (REFERENCE.md §7).
- Da boc ra bien truoc o 4 noi: `kwarg_resolve.tkv`, `il_codegen.tkv` (2 noi),
  `il_features/tuple_type.tkv`. Helper moi `_sao_join_str`.

### 4. `parity_pin_test` (container coerce) - XONG 117/118

`lit = [1, 2, 3]` khai `list[int]` (TkvInt) nen truyen vao tham so `list[i32]`
phai ep - .NET generic bat bien, truyen thang bien dich xong roi hong luc chay.

- Bat nhanh `elif ... _coerce_can(...)` trong `_expr_call` + `_emit_container_coerce`
  (sinh vong lap ghi tung phan tu vao list moi) + khai local an o first pass.
- **Khong index duoc ValueTuple** (`_list_coerce_pair(...)[1]`) - phai boc tuple
  ra bien (`_at, _need = ...`) qua helper `_coerce_can`.
- **Goc cua crash `Input string was not in a correct format`**: `_ta_tu_nhien_list`
  doc `ea_nut(arg_node)` cho node `'index'`, nhưng `expr_layout.tkv` khai
  `'index:1': 'str'` (TEN BIEN, khong phai node con). Doc sai field -> chet.
  Da doi sang `ea_str` cho ca `'index'` va `'slice'`.

---

## Bai hoc ky thuat (phien 11/10)

- [x] **TUYET DOI KHONG dung `Get-Content -Raw | Set-Content -Encoding UTF8`
  tren file nguon `.tkv`.** PowerShell 5.1 doc bang CP1252 nen file UTF-8 bi
  double-encode (mojibake `Tá»±`) **va** them BOM. Byte undefined-trong-CP1252
  (0x90, 0x81...) mat khong khoi phuc duoc. Chi dung `edit`/`write` tool.
  *Da vi pham chinh trong phien nay va ton 30 phut khoi phuc.*
- [x] **`dist\tkvc-tv.exe` co the KHOI PHUC tu IL** khi ban goc bi hong:
  `ilasm build\selfhost\tv2s.il /output=<moi>.exe` (Framework v4.0.30319).
  `tv2s.il` la IL cua fixed point gan nhat ma vong `IL_IDENTICAL` vua ganh.
- [x] **Bootstrap bang STUB khi compiler hien tai khong compile duoc module
  moi**: ghi module that thanh stub tra ve nguyen tham so, chay `vong` (g1/g2
  ra IL_IDENTICAL, `dist` = compiler goc), khoi phuc module that, chay `vong`
  lai. Khong dung `dist\tkvc.exe` (Python bootstrap) - no khong ho tro
  module-level container (`global` chi cho scalar).
- [x] `vong.exe` bao LOI o `g1` vs `g2` la 2 trang thai khac nhau: loi o `g1`
  = `dist` hong; loi o `g2` = compiler vua sua co bug. Doc dung `.log`.
- [x] Doc `expr_layout.tkv` truoc khi dung `ea_*` tren 1 node - layout quyet
  dinh field la `nut` hay `str`/`ds`, doc sai la chet khong bao loi.

---

## Phase 0-2: Da xong truoc do (tom tat)

- **0.1** Generator `list[...]` overflow (label_counter/stack infer sai) - XONG 07/10.
- **0.2** Star-args (`call_star_args`) - XONG 11/10 (xem tren).
- **0.3** Record method KeyError (`Bag.add` vs `set.add`) - XONG 08/10.
- **1** Ternary-argument garbage (`_expr_ternary` + `_infer_literal_dtype`) - XONG 09/10, `question_ternary_test` 9/9.
- **2.1** `list()` constructor (77ec891) - `list_ctor_test` 10/10.
- **2.2/2.3** `tuple()` constructor + `tuple([a,b,c])` (d062de9) - `tuple_ctor_test` 10/10.
- **2.2b** `c ? a : b` chay qua duong `tkv_compile`; file `il_features/question_ternary.tkv`
  van la **CODE CHET** (git-tracking nhung khong co trong `ds_gop.txt`).
- **2.2c** `print(sep=, end=)` (1b071fc) - `kwargs_enumerate_test` 13/13.
- **2.2d** `key=`/`reverse=` cho min/max/sum/sorted (2471670) - bo dang ky macro `key_agg`.
- **2.2e** Khoi phuc `infer_literal_dtype` (32246a0) - `[3,1,2]` la `list[int]` chu khong phai `list[i32]`.
- **2.2f** Multi-for / multi-if comprehension (2fcd2b3) - 17/17.
- **2.4** `yield from` + `return <gia tri>` tu generator - `generator_yield_from_test` 10/10.
- **2.5** `try/except/else` - `try_except_else_test` 10/10.
- **3.1a** Record `__init__` noi vao `.ctor` (phuong an A) - `record_init_runs_test` 11/11.
- **3.2** `__lt__` cho record - `record_lt_test` 16/16.
- **3.4** `getattr`/`setattr`/`format`, decorator tuy bien, multiline string,
  `bool()`, set literal, generator lam doi so container - lần lượt xanh.

---

## Phase 3/4/5: Trang thai

- **Phase 3**: 117/118. Con `nested_literal_test` (BUILDFAIL) + `p6_vectorize_test` (ILFAIL).
- **Phase 4**: **NEG 31/31** - da dong.
- **Phase 5**:
  - [x] `testkit_gate.ps1`: 117/118, NEG 31/31
  - [x] `vong.exe`: IL_IDENTICAL on dinh
  - [x] `parity_probe/run.ps1`: 119/119 khop CPython
  - [x] `dang_ky_gate.py`: 0 violation
  - [x] `lint_rules_gate.ps1`: 8/8
  - [x] `ext_smoke.ps1`: 4/4
  - [ ] `docs/REPOSITORY-NOTES.md` + handoff cuoi
  - [ ] Commit

---

## Bai hoc ky thuat (phien 09/10 - 10/10, giu lai de doc)

- **KHONG BAO GIO dung `Set-Content -Encoding utf8`** tren file `.tkv` (nay la
  phien 11/10 da lap lai, xem tren).
- **STMT ROW MOI phai khai trong `stmt_row.tkv` CA 2 CHO**: `_LAYOUT` va
  `_KHOA_LOGIC`. Thieu cho nao la `lay_str()` tra `None` am tham.
- **`m.groups()` CHI unpack duoc**; `m.group(1)` khong ton tai. Regex 1 group ->
  tach tay (startswith/slice).
- **`Ctx` va `WalkCtx` KHONG cung layout.** Ham nhan `ctx: "Ctx"` ma duoc goi
  tu PASS 1 doc **SAI OFFSET** ma KHONG bao loi.
- **COMMENT CO NGOAC LECH se bi macro text-level quet** -> can can bang ngoac.
- **`il_tupleN_type` tra `Tuple\`N`** (reference), `Item2` la PROPERTY.
- Mot tinh nang **TOI DA 2 DUONG DANH TINH** = moi fix phai lam 2 lan
  (`sorted/min/max/sorted key=` ton tai ca macro text-level va builtin).

---

## Muc tieu cuoi

Gate 118/118, NEG 31/31, tat ca gates green, IL_IDENTICAL on dinh.
