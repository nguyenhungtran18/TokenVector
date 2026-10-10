# PLAN: TokenVector Tá»±-Host Äáº§y Äá»§ (118/118 + NEG 31/31)

**NgÃ y báº¯t Ä‘áº§u**: 08/10/2026
**Cáº­p nháº­t cuá»‘i**: 10/10/2026 (phien 5)
**Tráº¡ng thÃ¡i**: Gate **101/118** (them print(sep=,end=), key=/reverse=, khoi phuc infer_literal_dtype), NEG **10/31**, IL_IDENTICAL. Gate khac: parity 119/119, dang_ky 0, lint 8/8, ext_smoke 4/4

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

### 1.2. Fix Ä‘Ã£ implement (chá» verify) ðŸ”„
- [x] Sá»­a `_expr_ternary`: infer natural dtype, compile branches theo natural, widen vá» requested sau khi load temp
- [ ] Cháº¡y vong.exe láº§n 2 Ä‘á»ƒ converge (láº§n 1: IL KHAC NHAU, Ä‘Ã£ upgrade g2 â†’ cáº§n cháº¡y láº¡i)
- [ ] Verify: `pick(c ? 10 : 20)` tráº£ vá» Ä‘Ãºng 10
- [ ] Verify: `b.set(c ? 10 : 20)` gÃ¡n Ä‘Ãºng
- [ ] Cháº¡y `question_ternary_test` â†’ má»¥c tiÃªu 9/9 (hiá»‡n 7/9)

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

### 2.2b. `question_ternary` (`c ? a : b`)
- [ ] Fix module-level code (tuple literals -> ham helper, triple-quote docstrings, typed globals)
- [ ] Wire `rewrite_question_ternary` vao `tkv_compile.tkv::_parse_program_ast`
- [ ] Them vao `ds_gop.txt` + `bootstrap_all.tkv`
- [ ] Rebuild, verify IL_IDENTICAL; chay test -> 9/9 (phu thuoc Phase 1)

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

### 3.1. Tests dá»… (Æ°u tiÃªn) â¬œ
- [ ] `multiline_string_test`: triple-quoted strings (`_join_triple_quoted` + TRIPLESTR token)
- [ ] `nested_literal_test`: nested containers (EXPR_CODEGEN cho dict/set literal)
- [ ] `comprehension_multi_for_test`: multi-for comprehensions
- [ ] `kwargs_enumerate_test`: kwargs handling
- [ ] `agg_key_test`: aggregate key handling
- [ ] `decorator_py_tree_test`: decorators
- [ ] `funcvar_test`: func variable (reduce signature check)
- [ ] `gap_exc_gen_test`: exception in generators
- [ ] `set_iteration_test`: set iteration
- [ ] `record_container_field_test`: record vá»›i container fields
- [ ] `record_init_runs_test`: record `__init__` execution
- [x] `record_method_name_collision_test`: 18/18 PASS 09/10 (dict.update macro guard via is_known_record_var)
- [x] `set_iteration_test`: PASS (loop var reuse relax)
- [x] `record_container_field_test`: PASS (build OK)
- [x] `fstring_bigint_test`: 12/12 PASS (verified 09/10)
- [~] `record_init_runs_test`: 9/11 (was BUILDFAIL; -> None accepted; remaining needs _ctor_init_body_il)
- [~] `decorator_py_tree_test`: builds but decorator signature check fails (int/i32 compat, same as funcvar)

### 3.2. TESTFAIL (2) â¬œ
- [ ] `parity_pin_test`: thÃªm `_emit_container_coerce` (coerce intâ†”i32 cho containers)
- [ ] `record_lt_test`: kiá»ƒm tra láº¡i (Ä‘Ã£ 16/16 qua probe)

### 3.3. ILFAIL (1) â¬œ
- [ ] `p6_vectorize_test`: stobj, _vstart, _tstart (vectorization)

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
| Phase 1: Ternary-arg garbage | ðŸ”„ ÄANG LÃ€M (fix Ä‘Ã£ implement, chá» vong converge) |
| Phase 2: Ports | 4/6 (list(), tuple(), print sep/end, key=/reverse= XONG; con question_ternary, yield from, try/else) |
| Phase 3: BUILDFAIL + TESTFAIL + ILFAIL | 101/118, 13 BUILDFAIL + 3 TESTFAIL + 1 ILFAIL |
| Phase 4: NEGFAIL | 10/31 (3 xanh trong phien 10/10) |
| Phase 5: Verification + dá»n dáº¹p | â¬œ CHÆ¯A Báº®T Äáº¦U |

**Má»¥c tiÃªu cuá»‘i**: Gate 118/118, NEG 31/31, táº¥t cáº£ gates green, IL_IDENTICAL á»•n Ä‘á»‹nh.

