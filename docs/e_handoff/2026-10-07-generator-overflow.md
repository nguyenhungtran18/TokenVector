# Báo cáo: Generator Overflow ĐÃ FIX, Vòng Tự-Host Ổn Định (2026-10-07)

## Tóm tắt thành tựu

**Generator `list[...]` overflow ĐÃ FIX HOÀN TOÀN.**

### Nguyên nhân gốc
Khi compiler tự-host compile chính nó, các local variables `label_counter = [0]` (trong `gen_il_function` và `gen_il_generator_function`) và `stack = [0]` (trong `tkv_lexer.tkv::apply_layout`) được infer thành `List<TkvInt>` thay vì `List<int32>`. Khi runtime truy cập `label_counter[0]` và ép kiểu qua `TkvInt::ToI32`, giá trị rác (garbage) vượt quá int32 → `OverflowException: "chi so int qua lon: khong vua int32"`.

### Giải pháp
Thêm helper function `_zero_i32() -> "i32"` trả về literal 0 với kiểu i32 rõ ràng, sau đó thay:
- `label_counter = [0]` → `label_counter = [_zero_i32()]` (2 chỗ trong `il_codegen.tkv`)
- `stack = [0]` → `stack = [_zero_i32()]` (trong `tkv_lexer.tkv`)

Khi element là call expression trả về i32 (thay vì literal 0 là TkvInt), type inference cho ra `List<int32>` đúng.

### Vấn đề order-of-definition
`_zero_i32()` được định nghĩa trong `il_codegen.tkv` (ds_gop line 127) nhưng `stack` trong `tkv_lexer.tkv` (ds_gop line 12) compile trước → lỗi "trung ten ham" khi định nghĩa ở cả hai file. Giải pháp: chỉ định nghĩa `_zero_i32()` trong `tkv_lexer.tkv` (file compile trước), `il_codegen.tkv` dùng chung (vì tất cả files được merge thành một tv_gop.tkv duy nhất).

### Kết quả
- Vòng tự-host: **IL_IDENTICAL** (g1 == g2)
- Tất cả generator probes compile và run OK:
  - `probe_gen_min.tkv` (generator `list[i32]` tối thiểu)
  - `probe_gen5.tkv` (generator đơn giản)
  - `probe_recgen.tkv` (recursive generator)
  - `probe_walk.tkv` (recursive generator `list[i32]`)
- Testkit gate: **93/118 PASS**, NEG 6/31

## Trạng thái hiện tại

### Files đã sửa (giữ lại)
- `compiler_bootstrap/compiler/il_codegen.tkv`: thêm `_zero_i32()` helper (đã xóa sau khi chuyển sang tkv_lexer), thay 2 chỗ `label_counter = [0]` → `[_zero_i32()]`
- `compiler_bootstrap/compiler/tkv_parser/tkv_lexer.tkv`: thêm `_zero_i32()` helper, thay `stack = [0]` → `[_zero_i32()]`
- `compiler_src/ds_gop.txt`: thêm `call_star_args.tkv` (star-args port, từ phiên trước)
- `compiler_bootstrap/compiler/il_features/call_star_args.tkv`: module mới (từ phiên trước)
- Các files khác từ phiên trước: `kwarg_resolve.tkv` fix, `tuple_type.tkv` dictlit marker, `stmt_row.tkv` helpers, `il_core.tkv` star/star2, `expr_layout.tkv` KHUON, `bootstrap_all.tkv` wiring

### Files đã revert (gây regression)
- `compiler_bootstrap/compiler/il_features/list_type.tkv`: revert `try_rhs_list_call` (list() constructor) — gây KeyError khi compile tv_gop
- `compiler_bootstrap/compiler/il_features/question_ternary.tkv`: revert port (chưa hoàn chỉnh, gây KeyError)
- `compiler_bootstrap/compiler/il_features/record_feature.tkv`: revert port (có dict merge không hỗ trợ)
- `compiler_bootstrap/tkv_compile.tkv`: revert `rewrite_question_ternary` wiring
- `compiler_bootstrap/compiler/il_features/metaprogramming.tkv`: revert hasattr 'bool'→'i32' (cần rebuild lại để test)
- `tools/vong.tkv`: revert entry "main" (cần thêm lại nếu cần)

## Vấn đề còn lại

### 1. Record method calls với arguments → KeyError (NGHIÊM TRỌNG, pre-existing)
**Triệu chứng**: Bất kỳ record method call nào có arguments đều fail với `The given key was not present in the dictionary`, ngay cả với literal đơn giản như `b.add(3)`.

**Test**: `test_rec3.tkv` (Bag.add với literal 3) → KeyError. Trong khi:
- Record field access (`b.n`) → OK
- Method call không args (`b.get()`) → OK
- Function call với ternary arg (`pick(3 if 1 else 4)`) → OK

**Nguyên nhân**: Bug trong record method call resolution code khi match arguments. Có thể liên quan đến method signature lookup trong record method table.

**Ảnh hưởng**: `question_ternary_test.tkv` fail vì dùng `b.add(c ? 3 : 4)`. Nhiều tests khác dùng record methods cũng có thể fail.

**Cần làm**: Điều tra `compile_method_call` path cho records trong `il_codegen.tkv` hoặc `tkv_compile.tkv`. Tìm dictionary lookup nào throw KeyError khi resolve method arguments.

### 2. question_ternary (`c ? a : b` syntax) — chưa port xong
**Trạng thái**: Module đã port sang `compiler_bootstrap/compiler/il_features/question_ternary.tkv` nhưng chưa wire vào build (đã revert vì gây regression).

**Vấn đề khi port**:
- Tuple literals `('and', 'or')` ở module level không hỗ trợ → đã fix bằng hàm helper
- Triple-quoted docstrings gây lỗi parse → đã fix bằng cách thay `"""` thành `"`
- Typed globals không hỗ trợ → đã fix bằng hàm helper
- Nhưng khi thêm vào build, gây KeyError (có thể do interaction với record method bug ở trên)

**Cần làm**: Port lại question_ternary sau khi fix record method bug. Hoặc test question_ternary độc lập trước khi wire vào build.

### 3. list() constructor — chưa port xong
**Trạng thái**: Đã port `try_rhs_list_call` (parse `list()` và `list(ys)`) nhưng gây KeyError khi compile tv_gop → đã revert.

**Vấn đề**: `fpw_assign_list_from` dùng `ctx.infer_scope[src_name][2]` sai pattern (phải dùng `.tra().ta`). Đã fix nhưng vẫn KeyError ở chỗ khác (có thể `known_shapes` dict access).

**Cần làm**: Port lại list() constructor sau khi hiểu rõ dict access patterns trong bootstrap. Hoặc dùng approach đơn giản hơn: chỉ support `list()` (empty) trước, `list(ys)` sau.

### 4. tuple() từ list literal — chưa port
**Trạng thái**: Chưa bắt đầu port. Python bootstrap có `try_rhs_tuple_call` trong `tuple_type.tkv`.

**Cần làm**: Port `try_rhs_tuple_call`, `fpw_assign_tuple_literal`, `codegen_assign_tuple_literal` từ Python bootstrap.

### 5. Các BUILDFAIL còn lại (ước tính ~20)
Từ gate cuối (93/118):
- `generator_yield_from_test`: `yield from` syntax chưa hỗ trợ
- `try_except_else_test`: `else` clause trong try/except chưa hỗ trợ
- `question_ternary_test`: blocked bởi record method bug
- `list_ctor_test`: blocked bởi list() constructor chưa port
- `tuple_ctor_test`: blocked bởi tuple() chưa port
- Các tests khác: `agg_key`, `comprehension_multi_for`, `decorator_py_tree`, `funcvar`, `gap_exc_gen`, `kwargs_enumerate`, `multiline_string`, `nested_literal`, `record_container_field`, `record_init_runs`, `record_method_name_collision`, `set_iteration`, etc.

### 6. TESTFAIL (2)
- `parity_pin_test`: thiếu `_emit_container_coerce` (coerce int↔i32 cho containers)
- `record_lt_test`: cần kiểm tra lại (đã fix 16/16 qua probe trước khi revert)

### 7. ILFAIL (1)
- `p6_vectorize_test`: stobj, _vstart, _tstart (vectorization)

### 8. NEGFAIL (25, pre-existing)
Danh sách đầy đủ trong gate log. Hầu hết là pre-existing, không liên quan đến generator fix.

## Lệnh chạy

```powershell
# Vòng tự-host
& 'tools\vong.exe'

# Testkit gate (mất ~28 phút)
& 'tools\testkit_gate.ps1'

# Compile test
& 'dist\tkvc-tv.exe' tests\meta_format_test.tkv "$env:TEMP\opencode\mf.exe" run
& "$env:TEMP\opencode\mf.exe"

# Test generator probes
& 'dist\tkvc-tv.exe' "$env:TEMP\opencode\probe_gen_min.tkv" "$env:TEMP\opencode\pgm.exe" run
& 'dist\tkvc-tv.exe' "$env:TEMP\opencode\probe_recgen.tkv" "$env:TEMP\opencode\prg.exe" run
```

## Files quan trọng

- `compiler_bootstrap/compiler/il_codegen.tkv`: `gen_il_function` (L7820), `gen_il_generator_function` (L8131), `_zero_i32` helper
- `compiler_bootstrap/compiler/tkv_parser/tkv_lexer.tkv`: `apply_layout` (stack fix), `_zero_i32` helper
- `compiler_bootstrap/compiler/il_features/generator_lazy.tkv`: generator compilation
- `build/selfhost/g1.il`, `build/selfhost/g2x.il`: IL để so sánh
- `%TEMP%\opencode\probe_*.tkv`: test probes
- `%TEMP%\opencode\stubber2.py`: stubber để bisect

## Khuyến nghị tiếp theo

1. **Ưu tiên 1**: Fix record method calls với arguments (KeyError). Đây là blocker cho question_ternary_test và nhiều tests khác. Cần điều tra method resolution code.
2. **Ưu tiên 2**: Port lại question_ternary sau khi fix (1). Test độc lập trước khi wire vào build.
3. **Ưu tiên 3**: Port lại list() constructor (chỉ `list()` empty trước, đơn giản hơn).
4. **Ưu tiên 4**: Port tuple() từ list literal.
5. **Ưu tiên 5**: Fix các BUILDFAIL đơn giản còn lại (multiline_string, nested_literal, etc.).
6. **Cuối cùng**: Chạy gate để xác nhận, sau đó xử lý NEGFAIL.
