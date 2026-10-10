# PLAN: TokenVector Tá»±-Host Äáº§y Äá»§ (118/118 + NEG 31/31)

**NgÃ y báº¯t Ä‘áº§u**: 08/10/2026
**Cáº­p nháº­t cuá»‘i**: 10/10/2026 (phien 5)
**Tráº¡ng thÃ¡i**: Gate **103/118** (them print(sep=,end=), key=/reverse=, khoi phuc infer_literal_dtype, multi-for/multi-if comprehension, fix ternary-arg garbage), NEG **10/31**, IL_IDENTICAL. Gate khac: parity 119/119, dang_ky 0, lint 8/8, ext_smoke 4/4

---

## Phase 0: Bug Fixes Cá»‘t LÃµi (Blockers) âœ…

### 0.1. Generator `list[...]` overflow âœ… XONG 07/10
- [x] XÃ¡c Ä‘á»‹nh root cause: `label_counter = [0]` vÃ  `stack = [0]` infer thÃ nh `List<TkvInt>` thay vÃ¬ `List<int32>`
- [x] ThÃªm helper `_zero_i32() -> "i32"` trong `tkv_lexer.tkv`
- [x] Thay `label_counter = [0]` â†’ `label_counter = [_zero_i32()]` (2 chá»— trong `il_codegen.tkv`)
- [x] Thay `stack = [0]` â†’ `stack = [_zero_i32()]` (trong `tkv_lexer.tkv::apply_layout`)
- [x] Xá»­ lÃ½ order-of-definition (tkv_lexer compile trÆ°á»›c il_codegen)
- [x] Verify: táº¥t cáº£ generator probes compile OK, vÃ²ng tá»±-host IL_IDENTICAL

### 0.2. Star-args port (`call_star_args`) âœ… XONG (phiÃªn trÆ°á»›c)
- [x] Module má»›i `call_star_args.tkv` (~530 dÃ²ng): `f(*xs)`, `f(**kw)`
- [x] Parser: `star`/`star2` nodes, hook á»Ÿ `_first_pass_collect_locals`
- [x] Marker `#__dictlit` phÃ¢n biá»‡t dict literal tháº­t vs tá»± xÃ¢y dáº§n
- [x] Fix `kwarg_resolve.tkv` crash native 0xc0000005
- [x] 5 star-negative tests xanh

### 0.3. Record method KeyError (`Bag.add` â†’ `set.add` nháº§m) âœ… XONG 08/10
- [x] XÃ¡c Ä‘á»‹nh root cause: `try_parse_set_add` khá»›p regex `x.add(...)` mÃ  khÃ´ng check shape, hijack record method statements
- [x] Port parse-time guard tá»« Python (2026-09-29): decline khi `known_shapes` xÃ¡c nháº­n kiá»ƒu khÃ¡c
- [x] Port `_record_stmt_fallback` vÃ o `list_type.tkv` (safety net codegen-time)
- [x] ThÃªm safety-net call vÃ o `codegen_set_add` + `codegen_list_append`
- [x] Verify: `Bag.add(3)` compile OK, cháº¡y Ä‘Ãºng (0+3=3)
- [x] VÃ²ng tá»±-host IL_IDENTICAL, gate 94/118 (khÃ´ng há»“i quy)

---

## Phase 1: Ternary-Argument Garbage ðŸ”„ ÄANG LÃ€M

### 1.1. Root cause Ä‘Ã£ xÃ¡c Ä‘á»‹nh âœ…
- [x] So sÃ¡nh IL: assignment dÃ¹ng `FromI64` Ä‘Ãºng, call-arg dÃ¹ng `ldc.i4` sai
- [x] NguyÃªn nhÃ¢n: branches compile theo outer dtype (`i32`) nhÆ°ng temp khai bÃ¡o `TkvInt` â†’ layout mismatch â†’ garbage
- [x] Return "Ä‘Ãºng" do may máº¯n (runtime lenient), call thÃ¬ garbage (strict stack)

### 1.2. Fix - XONG (ce33b74, 9/9)
- [x] Root cause THAT (doc `.il` moi bat): first-pass khai `__ternN` bang
      `_infer_dtype or _infer_literal_dtype or body_dtype` -> `'int'` (TkvInt),
      nhung `_expr_ternary` (pass 2) TU SUY LAI bang `_infer_dtype or dtype` -> `'i32'`.
      => nhanh ghi `ldc.i4 1; stloc.s __ternN`: ghi 4 byte vao slot 16 byte;
      `ldloc` nap 16 byte cho tham so int32 -> rac am thanh.
- [x] Fix: `_expr_ternary` dung DUNG chuoi suy luoi cua first-pass (them
      `_infer_literal_dtype(node)` giua `_infer_dtype` va fallback). 5 dong.
- [x] Verify: `pick(c ? 10 : 20)` / `pick(c ? 1 : 0)` tra dung; `b.add(c ? 3 : 4)` dung.
- [x] `question_ternary_test` **9/9**, gate 102/118 -> 103/118, IL_IDENTICAL.
- [ ] **GHI CHU**: bootstrap Python luu `tern_temp_of_id[id] = (slot, dtype)` de 2 pass
      KHONG tu suy dtype rieng. Da thu dua sang bang do trong ban tu-host, nhung
      TokenVector **KHONG cho unpack tuple tu DICT** (`'__hoist603' phai la 1
      list-cua-tuple`) - phai them 1 bang moi vao ca `Ctx` + `WalkCtx` + 2 noi
      `tao_ctx`. Chon `cung chuoi suy luoi` - it rui ro hon va du diff doc ngay.
- [ ] **`question_ternary.tkv` LA CODE CHET**: da git-tracking nhung KHONG co trong
      `compiler_src/ds_gop.txt` -> KHONG bao gio duoc bien dich. Tinh nang `?`
      chay qua duong khac (tkv_compile). Hoac wire vao ds_gop.txt, hoac xoa file.

---

## Phase 2: Port TÃ­nh NÄƒng CÃ²n Thiáº¿u â¬œ

### 2.0. BAI HOC KY THUAT (phien 09/10 - neu khong se mat hang gio)
- [x] **KHONG BAO GIO dung `Set-Content -Encoding utf8` (PowerShell 5.1) tren file `.tkv`** - no them BOM, compiler bao loi sai huong (`khong tokenize duoc`, `tuple lam bieu thuc`) khong lien quan gi den code. Dung read/write bytes trong Python hoac edit tool.
- [x] **STMT ROW MOI phai khai trong `compiler\stmt_row.tkv` CA 2 CHO**: `_LAYOUT` (~dong 557) va `_KHOA_LOGIC` (~dong 822). Thieu cho nao la `lay_str()` tra `None` am tham -> loi `bien None chua duoc khai bao` khong co so dong.
- [x] **`m.groups()` CHI unpack duoc** (`a, b = m.groups()`); `m.group(1)` KHONG ton tai. Regex 1 group -> tach tay (startswith/slice).
- [x] **`ctx.locals_decl.append((name, ta))` chi chay khi `ta` co kieu compiler suy duoc** (record field, tham so...). Local tu `TypeAnn(...)` khong infer duoc cho tuple -> g1 build OK nhung g1 compile tv_gop crash `Object reference not set`. Giai phap: append THANG bien nguon (`src_ta`).
- [x] **Dang ky codegen + fpw PHAI DU BO** cho stmt kind moi. Parser tao stmt ma khong co codegen -> crash `Object reference not set` khi compile lai tv_gop.
- [x] **`dist\tkvc-tv.exe` CO THE BI HONG**: sau 2 vong IL KHAC NHAU ma crash `Object reference not set` thi ban thang cap co bug codegen. Khoi phuc: `Copy-Item build\selfhost\g2x.exe dist\tkvc-tv.exe` (ban 08-Oct dung duoc) roi chay `tools\vong.exe` 2 lan (lan 1 co the bao IL KHAC NHAU, lan 2 phai ra IL_IDENTICAL). Chi ton khi nua phien bi crash.
- [x] **Debug nhanh**: doc `build\selfhost\g2.exe.log` (hoac g1.exe.log) lay loi gan nhat; TAMTAT tung registration de bisect nhanh hon chay lai vong 2 phut.

### 2.0c. BAI HOC KY THUAT (phien 10/10 - port `print` sep/end + `key=`)
- [x] **`return <ham>()` trong ham khai bao void BI TU CHOI** (`ham 'x': thieu return-type annotation`). Phai tach `<ham>()` roi `return` mot dong rieng.
- [x] **`{}` chi duoc o ve phai phep gan.** `func_table if func_table else {}` -> loi `'{}' chi dung duoc o ve phai phep gan`. Dung `func_table or {}`.
- [x] **`Ctx` va `WalkCtx` KHONG cung layout.** Ham nhan `ctx: "Ctx"` ma duoc goi tu PASS 1 doc **SAI OFFSET** (dict rong) ma KHONG bao loi. Ham dung ca 2 giai doan phai nhan `func_table: "dict[str,TkvSig]"` truc tiep. Day la ly do `sum(xs, key=f)` bao "'neg' khong phai bien kieu func" trong khi `map(neg, xs)` lai chay dung.
- [x] **COMMENT CO NGOAC LECH se bi macro `minmax_2arg` quet trong TEXT** -> `il_codegen: '(' ... khong co ')' dong khop`. Comment chay qua `_expand_macros` TRUOC khi duoc loai bo. Moi dong comment can CAN BANG ngoac.
- [x] **`il_tupleN_type` tra `class [mscorlib]System.Tuple\`N`** (reference), KHONG phai ValueTuple. `Item2` la PROPERTY -> `callvirt get_Item2()`, `ldfld ::Item2` -> `MissingFieldException` luc chay.
- [x] **Khong dung dict `{ten: node}` cho kwargs** - kieu node la alias cua so nguyen khong gon nhu `str`. Dung `_kwarg_node(args, ten)` / `_co_kwarg(args, ten)` doc lai tu danh sach tham so.
- [x] **Mot tinh nang TOI DA 2 DUONG DANH TINH = moi fix phai lam 2 lan.** `sorted/min/max(xs, key=f)` ton tai ca macro text-level `key_agg` (comprehension.tkv) va builtin. Da BO DANG KY macro - giu lai thi moi fix phai lam 2 lan.

### 2.2c. `print(sep=, end=)` - XONG (1b071fc)
- [x] Port `compile_print` tu Python bootstrap sang TokenVector; tach kwarg bang `ekind`/`ea_str`/`eb_nut`.
- [x] **Thu tu HAI lenh `Console::Write` la bat buoc**: lenh 1 day het chuoi doi so vua ghep xuong, lenh 2 moi noi `end`. Ghi 1 lenh se bo chuoi doi so tren ngan xep -> `InvalidProgramException` luc chay.
- [x] `kwargs_enumerate_test` 13/13 PASS. (`enumerate(xs, start)` da duoc macro `enumerate_start` trong comprehension.tkv lo tu truoc - khong can port.)

### 2.2d. `key=` / `reverse=` cho min/max/sum/sorted - PORT XONG, agg_key_test VAN FAIL (2471670)
- [x] `_has_kwarg` cho macro `minmax_2arg` (truoc day chi dem dau phay nen `max(xs, key=f)` bi viet lai thanh ternary roi parser bao loi tren `=`).
- [x] Port `_key_func` / `_push_minmax_key` / `_push_sum_key` / `_push_sorted_key` / `_reverse_node_check` / `_temps_sorted` / `_sum_result_dtype`.
- [x] Port `sort_key_temp_names` + `emit_sort_by_key` + `_ds_phong_so` vao stdlib_functional (dung chung voi `list.sort(key=g)`).
- [x] BO DANG KY macro `key_agg` (comprehension.tkv).
- [x] NEG xanh them: `agg_bad_kwarg_name`, `agg_key_signature`, `sorted_reverse_non_bool` (NEG 7/31 -> 10/31).

### 2.2e. Khoi phuc `infer_literal_dtype` - XONG (32246a0)
- [x] `xs = [3, 1, 2]` bi khai `List<int32>` thay vi `List<TkvInt>` -> moi noi so sanh chu ky lech 1 don (`sorted(xs, key=f)`).
- [x] **NGUYEN NHAN**: comment *"Bo hai nhanh CHET (2026-09-25)"* dung khi code con la PYTHON - `ctx` la dict CPython nen `ctx.get('infer_literal_dtype')` luon None. Trong ban tu-host `ctx` la OBJECT (`WalkCtx`) va truong do **CO THAT**.
- [x] `NguonKieu` + 2 truong (`infer_literal_dtype`, `co_infer_literal`); `nguon_kieu_walk` co=1, `nguon_kieu_ctx` (pass 2) co=0.
- [x] **BAT**: tham so kieu `'func'` KHONG chap nhan `None` lam doi so -> can ham stub `_infer_literal_khong_co`. Và kiem `func is not None` cung khong an toan -> dung co hieu `i32`.
- [x] **NHANH `contains_float_literal` (int-family -> `'f32'`) VAN CHUA dua lai** - no gan `'f32'` trong khi phan con lai compiler dung `'f64'`. Sua rieng cho nhanh do can mot phien rieng.
- [x] Gate 99/118 -> **101/118**, NEG khong doi, 0 regression. Xinh them `agg_key_test` 14/14 + `funcvar_test` + `parity_pin_test` (ca 3 cung loai lech int/i32).

### 2.2f. Multi-for / multi-if comprehension - XONG (2fcd2b3)
- [x] List-comp da ho tro N vong `for` tu 2026-09-30, nhung **dict/set** thì khong, va **nhieu `if` tren MOT vong `for`** thi khong.
- [x] `_mo_rong_nhieu_for` nhan them `kexpr`/`vexpr`/`loai` (`dict`/`set`/`list`) va co hieu `force` (cho phep ca 1 vong `for` khi chi co N dieu kien `if`).
- [x] `try_expand_dict_or_set_comp` goi `_mo_rong_nhieu_for` cho ca 2 nhanh dict va set.
- [x] **BAT BUOC: tach `if` phai quet MUC NGOAI, bo qua noi dung chuoi.** `re.search(r'\bif\b', s)` dem nham `if v == "if"` -> sinh ra `if v == ":` (sai cu phap, compiler tu-host crash). Them `_vi_tri_tu_khoa_ngoai(s, tu)` - ban tong quat cua `_vi_tri_for_ngoai`.
- [x] `comprehension_multi_for_test` 17/17 PASS, 0 regression. Gate 101/118 -> **102/118**.

### 2.1. `list()` constructor - XONG (77ec891)
- [x] Port `try_rhs_list_call` + `fpw_assign_list_from` + `codegen_assign_list_from`; stmt kind `assign_list_from` khai trong stmt_row.tkv (2 cho); `list_ctor_test` 10/10 PASS, IL_IDENTICAL.

### 2.2. `tuple()` constructor - XONG (d062de9)
- [x] `tuple([a, b, c])` tu LIST LITERAL, `tuple(t)` khi `t` da la tuple.
- [x] `try_rhs_tuple_call` + `fpw_assign_tuple_identity` + `codegen_assign_tuple_identity`;
      stmt kind `assign_tuple_identity` khai trong stmt_row.tkv (2 cho: `_LAYOUT` + `_KHOA_LOGIC`)
- [x] `tuple_ctor_test` 10/10 PASS, `tuple_empty_call` negative van bi tu choi (co "ValueTuple"), IL_IDENTICAL.
- [x] BAO GOM: `known_shapes` KHONG BAO GIO ghi 'tuple' (no chi ghi container) - da thu them
      vao `_result_container_shape` nhung lam gay loi "Index was out of range" -> DA REVERT.
      Giai phap cuoi: parser tra stmt identity, FIRST PASS kiem tra kieu that qua infer_scope.

### 2.2b. `question_ternary` (`c ? a : b`) - CHAY DUOC, nhung file la CODE CHET
- [x] `question_ternary_test` 9/9 (sau khi Phase 1 xong) - tien xu ly `X ? Y : Z`
      -> `Y if X else Z` chay qua duong `tkv_compile`, KHONG qua file trong `il_features`.
- [ ] **FILE `il_features/question_ternary.tkv` KHONG duoc bien dich**: da git-tracking
      nhung KHONG co trong `compiler_src/ds_gop.txt`. Hoac wire vao ds_gop.txt
      (khi do phai kiem no khong lam trung chuc nang), hoac xoa file de khong
      nham nguoi doc lai.
- [ ] `rewrite_question_ternary` can nhac: KHONG doi so dong (ke ca noi dung doc
      o ben trong nhanh) - `start_line` lech se bao sai choang.

### 2.3. `tuple()` tu list literal - XONG (d062de9)
- [x] Port `try_rhs_tuple_call` tu Python bootstrap
- [x] `tuple([...])` doi van ban thanh `(a, b, c)` roi di duong assign_scalar san co
- [x] Port `fpw_assign_tuple_identity` + `codegen_assign_tuple_identity`
- [x] `tuple_ctor_test` 10/10 PASS

### 2.4. `yield from` â¬œ
- [ ] Port `yield_from` statement parser
- [ ] Port codegen cho `yield from` trong generators
- [ ] Xá»­ lÃ½ `__gen_ret__` cho `return <value>` trong generator
- [ ] Rebuild, verify `generator_yield_from_test` pass

### 2.5. `try/except/else` â¬œ
- [ ] Port `else` clause handling cho try blocks
- [ ] TÃ¡ch nhÃ£n IL cho Ä‘Æ°á»ng "clean" vs "handler Ä‘Ã£ báº¯t"
- [ ] Rebuild, verify `try_except_else_test` pass

---

## Phase 3: CÃ¡c BUILDFAIL ÄÆ¡n Giáº£n â¬œ

### 3.1. Tests CON FAIL (sau gate 103/118, 10/10/2026)

**BUILDFAIL (11)**: `conditional_expr`, `decorator_py_tree`, `gap_exc_gen`,
`generator_yield_from`, `meta_format`, `multiline_string`, `nested_literal`,
`py_builtins`, `set_literal`, `star_args`, `star_kwargs`, `try_except_else`

**TESTFAIL (2)**:
- [ ] `record_init_runs_test`: 9/11. Con 2 case ke thua. **CAN PORT `record_init_bodies`** (xem 3.1a)
- [ ] `record_lt_test`: kiem tra lai (da 16/16 qua probe)

**DA XINH (gio gate 103/118)**:
- [x] `kwargs_enumerate_test` 13/13 (1b071fc) - `print(sep=,end=)`
- [x] `agg_key_test` 14/14 (2471670 + 32246a0) - `key=`/`reverse=` + `infer_literal_dtype`
- [x] `comprehension_multi_for_test` 17/17 (2fcd2b3) - multi-for/multi-if
- [x] `question_ternary_test` 9/9 (ce33b74) - ternary-arg garbage
- [x] `funcvar_test`, `parity_pin_test` (32246a0) - cung loai lech int/i32
- [x] `record_method_name_collision_test` 18/18, `set_iteration_test`,
      `record_container_field_test`, `fstring_bigint_test` 12/12 (phien truoc)

### 3.1a. `record_init_runs_test` 9/11 - HAI CO CHE KHAC NHAU (can QUYET DINH THOI)

**KHONG phai "port 2 ham".** Khi so sanh 2 compiler da thay ra co che
`__init__` cua ban tu-host **KHAC HOAN TOAN** voi bootstrap Python:

| | bootstrap Python | ban tu-host (`tkvc-tv`) |
|---|---|---|
| noi luu than `__init__` | **inline vao `.ctor`** (`record_init_bodies` + `_ctor_init_body_il`) | **bien dich `__init__` thanh method CIL that** |
| `__init__` khong chu thich kieu | van inline | **bo qua luc transpile** (`tkv_compile.tkv:1796`) |
| khoi tao record | `.ctor` (than da inline san) | `newobj .ctor` roi **goi them `__init__`** (`il_codegen.tkv:3916-3920` -> `_tao_record_qua_init`) |
| record KE THUA | `base_ctor_len != 0` -> BO QUA than `__init__` (diem 4 cua docstring Python) | `Derived.__init__` CHAY, `Base.__init__` **KHONG BAO GIO chay** |

**2 case con fail deu la hieu qua cua chenh lech nay:**
- `field cua base (qua __init__ base)`: `Derived(3, 3)` -> `d.p` = 0, can 103.
  `Base::.ctor` chi gan `p = p` (khong co than inline). Tham so `Base.__init__`
  co chu thich kieu nen no la method THAT - nhung `_expr_call` chi goi
  `__init__` cua class DUNG record do, khong goi method cua base.
- `field rieng: __init__ con bi bo qua`: `d.q` = 6, can 3. TV goi
  `Derived.__init__` (theo co che "method that"), Python bo qua no.

**=> KHONG THE sua bang patch nho.** Phai chon 1 trong 2:

**(A) Chuyen TV sang co che "inline vao `.ctor`" (giong Python).**
- Thu thap `(sig_line, body_lines)` cua `__init__` o `tkv_compile.tkv:1796`
  (noi dang `continue`) vao dict `record_init_bodies`.
- Port `_split_method_il` + `_ctor_init_body_il` tu
  `compiler/il_codegen.tkv:6296` va `:6338`.
- `gen_record_types` nhan `record_init_bodies`, in `.maxstack`/`.locals` TRUOC,
  noi than `__init__` SAU khi field da gan, bo epilogue `ret`.
- **QUAN TRONG**: khi than da inline vao `.ctor` thi `_expr_call` KHONG duoc
  goi them `__init__` nua - neu khong, than chay 2 lan. Va phai bo qua khi
  `base_ctor_len != 0`.
- **RUI RO**: doi moi `.class` cua record -> IL diff lon tren toan bo file.
  Phai chay gate day du + parity probe. 9/11 -> 11/11 neu dung.

**(B) Sua 2 case ke thua theo co che hien tai (it xam nhap hon).**
- Cho `_expr_call` goi `__init__` cua class CHA theo chuoi (constructor
  chaining) khi class con ke thua record khac.
- Skip `Derived.__init__` khi so tham so `.ctor` > so tham so `__init__`.
- **NHUNG**: phai khop bo phan "9/11 con lai" cua `record_init_runs_test`, va
  test co the dang mo ta CHINH xu huong hien tai - doc lai docstring test
  truoc khi chon (hien no ghi "`.ctor` base chay... than `__init__` cua class
  con thi BI BO QUA", tuc mo ta co che Python).

**KHUYEN NGHI: (A)** - khop CPython, va 2 case con lai cua test chinh la
thuoc ve (A). Nhung can phien rieng vi lam doi IL cua moi record.

**Kiem truoc khi bat dau**: `gen_il_function` va `parse_typed_signature` co
san va goi duoc tu `gen_record_types` khong; `DinhNghiaLop` (tkv_compile.tkv:1642)
can them 1 field de giu `init_raw`.

### 3.3. ILFAIL (1)
- [ ] `p6_vectorize_test`: stobj, _vstart, _tstart (vectorization)

---
---

## Phase 4: Negative Tests (NEG 6/31 â†’ 31/31) â¬œ

- [ ] `abs_complex`, `agg_bad_kwarg_name`, `agg_key_signature`
- [ ] `break_in_try_finally`, `cond_mixed_types`, `datetime_args`
- [ ] `del_on_string`, `del_variable`, `delattr_not_supported`
- [ ] `for_tuple_pairs_var`, `fstring_bad_spec`
- [ ] `generator_return_no_gen_ret`, `getattr_missing_field`
- [ ] `module_var_without_global`, `reassign_int_str`
- [ ] `record_container_uninit`, `sorted_reverse_non_bool`
- [ ] `star_args_dynamic_src`, `star_kwargs_*` (5 cases)
- [ ] `str_tuple`, `tuple_empty_call`, `yield_from_bad_source`
- [ ] Má»—i case: fix compiler Ä‘á»ƒ reject Ä‘Ãºng, hoáº·c sá»­a test expectation náº¿u compiler Ä‘Ãºng

---

## Phase 5: Verification Cuá»‘i CÃ¹ng â¬œ

### 5.1. Gates â¬œ
- [ ] `testkit_gate.ps1`: 118/118 PASS, NEG 31/31
- [ ] `vong.exe`: IL_IDENTICAL á»•n Ä‘á»‹nh
- [ ] `parity_probe/run.ps1`: 119/119 match CPython
- [ ] `dang_ky_gate.py`: 0 violations
- [ ] `lint_rules_gate.ps1`: 8/8
- [ ] `ext_smoke.ps1`: 4/4

### 5.2. Dá»n dáº¹p â¬œ
- [ ] XÃ³a probes trong `%TEMP%\opencode\`
- [ ] Cáº­p nháº­t `docs/REPOSITORY-NOTES.md`
- [ ] Viáº¿t handoff cuá»‘i cÃ¹ng
- [ ] Commit vá»›i message rÃµ rÃ ng

---

## Tiáº¿n Ä‘á»™ tá»•ng thá»ƒ

| Phase | Tráº¡ng thÃ¡i |
|---|---|
| Phase 0: Generator overflow + Star-args + Record KeyError | âœ… XONG |
| Phase 1: Ternary-arg garbage | **XONG 10/10** (_expr_ternary + _infer_literal_dtype) |
| Phase 2: Ports | 4/6 (list(), tuple(), print sep/end, key=/reverse= XONG; con question_ternary, yield from, try/else) |
| Phase 3: BUILDFAIL + TESTFAIL + ILFAIL | 103/118, 11 BUILDFAIL + 2 TESTFAIL + 1 ILFAIL |
| Phase 4: NEGFAIL | 10/31 (3 xanh trong phien 10/10) |
| Phase 5: Verification + dá»n dáº¹p | â¬œ CHÆ¯A Báº®T Äáº¦U |

**Má»¥c tiÃªu cuá»‘i**: Gate 118/118, NEG 31/31, táº¥t cáº£ gates green, IL_IDENTICAL á»•n Ä‘á»‹nh.

