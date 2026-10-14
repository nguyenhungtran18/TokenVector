# TOKENVECTOR ARCHITECTURE
### (Kiến trúc hệ thống TokenVector)

> **Có đúng MỘT compiler, và nó viết bằng TokenVector.** Nguồn là
> `compiler_bootstrap/` — **133 file `.tkv` thật**, liệt kê đúng trong
> `compiler_src/ds_gop.txt`. Không có CPython ở bất kỳ bước nào.

Tài liệu này mô tả **nơi lưu trữ file** và **vai trò từng nhóm**. Số liệu đếm
trực tiếp từ cây nguồn, không suy đoán.

---

## 0. VÒNG LẶP TỰ BIÊN DỊCH (đây là "self-hosted")

`tools/vong.tkv` (đóng gói thành `tools/vong.exe`) làm đúng 4 việc:

1. Gộp **133 file** theo `compiler_src/ds_gop.txt` thành một nguồn ≈ 2,9 MB.
2. `dist/tkvc-tv.exe` biên dịch nguồn đó → `g1.il` ≈ 13 MB.
3. **`g1.exe`** biên dịch lại **chính nó** → `g2.il`.
4. In `IL_IDENTICAL` nếu hai bản `.il` giống hệt nhau byte-for-byte.

Nếu in `IL KHAC NHAU` thì compiler **đã tự nâng cấp chính nó** — đó là tiến hoá
bình thường, chạy lại một vòng nữa là đúng. Một vòng mất 5–7 phút.

Mỗi thay đổi `compiler_bootstrap/` cần **một thay đổi compiler**, tức khoảng
12–20 phút tính cả các vòng tiến hoá.

---

## 1. SẢN PHẨM

- `dist/tkvc-tv.exe`: compiler TokenVector tự biên dịch. CLI **positional**, không
  subcommand, không flag:
  ```
  tkvc-tv.exe <nguon.tkv> <ra.exe> <ham_diem_vao>
  ```

---

## 2. LÕI BIÊN DỊCH (`compiler_bootstrap/compiler/`, 13 file)

| File | Vai trò |
|---|---|
| `il_codegen.tkv` | Trình sinh CIL chính: hàm, record/class, closure, scope, `.locals`, `main` |
| `il_core.tkv` | Hạt nhân biểu thức + phát lệnh CIL cơ bản |
| `il_dispatch.tkv` | Bảng đăng ký (`register_expr_builtin`, `register_stmt_codegen`, `Ctx`) |
| `il_extern_dtype.tkv` | Kiểu extern / khai báo assembly ngoài |
| `typed_dsl_parser.tkv` | Parser kiểu DSL (`i32`, `f64`, `str`, `TypeAnn`) |
| `expr_row.tkv` | Arena **node biểu thức** (`mk2`/`mk3`/`mk4`, `KHUON`) |
| `expr_layout.tkv` | Bảng bố cục trường của từng kind node |
| `stmt_row.tkv` | Arena **row câu lệnh** (`intern`, `dat_nut`, `items_nut`) |
| `ast_row.tkv`, `ast_walk.tkv` | Dựng & duyệt cây AST |
| `tkv_types.tkv` | `TypeAnn`, `Scope`, `Binding` — mô hình phân giải tên |
| `record_owner.tkv` | Quan hệ sở hữu record/method |
| `bootstrap_all.tkv` | Thứ tự đăng ký — **một phần của hành vi** |

### Parser (`compiler_bootstrap/compiler/tkv_parser/`, 4 file)

`tkv_lexer.tkv` → `tkv_ast.tkv` → `tkv_expr.tkv` → `tkv_parser.tkv`.

---

## 3. MÁY TÍNH NĂNG (`compiler_bootstrap/compiler/il_features/`, 113 file)

Đăng ký qua `il_dispatch`; thứ tự trong `bootstrap_all.tkv` **là một phần của hành
vi**. Các nhóm chính:

| File | Vai trò |
|---|---|
| `control_flow.tkv` | `if/while/for/break/continue/try`, LICM, auto-vectorizer P6 |
| `list_type.tkv`, `dict_type.tkv`, `set_type.tkv` | `List<T>` / `Dictionary<K,V>` / `HashSet<T>` |
| `tuple_type.tkv`, `record_feature.tkv` | Tuple bất biến; lớp/record, kế thừa |
| `string_feature.tkv`, `string_builtin.tkv`, `string_methods_batch*.tkv` | Chuỗi UTF-8, `TkvStr`, `.split/.join/.replace/...` |
| `int_type.tkv`, `int_narrow.tkv`, `int_builtin.tkv` | `TkvInt`, thu hẹp i64→i32, hàm `int()` |
| `comprehension.tkv` | `[...]`, `{...}`, `{k: v ...}` |
| `generator_lazy.tkv`, `generator_feature.tkv` | State machine CIL cho `yield` |
| `closures.tkv`, `multi_assign.tkv`, `metaprogramming.tkv` | Biến tự do, `nonlocal`, `eval/exec` |
| `simd_feature.tkv`, `vector_block.tkv`, `vector4_type.tkv` | SIMD thủ công: `f32x4`, `VBuf8` |
| `f32buf_type.tkv`, `nativebuf.tkv` | Bộ đệm native, `read_f32`/`write_f32` |
| `stdlib_*.tkv` | `re`, `datetime`, `json`, `math`, `os`, `pathlib`, `sqlite`, `http`, `zip` |
| `threading_feature.tkv`, `ffi_feature.tkv` | `thread_spawn`/`join`; P/Invoke, FFI C |
| `iter_next.tkv` | `iter()` / `next()` |

> Trước khi tạo file mới trong `il_features/`, kiểm tra file đó **chưa tồn tại** —
> đã từng vô tình ghi đè một module đang sống và làm hỏng toàn bộ compiler.

---

## 4. THƯ VIỆN & CÔNG CỤ

- `examples/stdlib/` — đúng **2 file**: `math.tkv`, `pystdlib.tkv` (các hàm `re`
  / `datetime` / `os` còn lại đã là builtin toàn cục trong compiler).
- `projects/` — **19 công cụ** viết bằng `.tkv` (codestat, graphreview,
  tkv_transpiler, ...).
- `tools/` — các cổng kiểm + `tkv_guide.tkv` (tool hỏi đáp ngôn ngữ, viết
  bằng TokenVector) + `vong.tkv` (vòng tự biên dịch) + `perf/` (4 kernel).

---

## 5. BỘ KIỂM THỬ (`tests/`)

**123 test nghiệm thu** (`*_test.tkv`) + **31 negative case** + `tkv_test_lib.tkv`.
Chạy bằng `tools\testkit_gate.ps1`. Bổ sung: `tests_suite/` — 154 case `.ca` +
203 mẫu vào, chạy bằng `chay.tkv`.

---

## 6. TÀI LIỆU

- `docs/REFERENCE.md` — **nguồn tham chiếu duy nhất**: cú pháp + hành vi + sai
  khác so với Python cho từng builtin.
- `docs/HANDBOOK.md` / `.vi.md` — định hướng + các ràng buộc hay cắn người viết.
- `docs/TUTORIAL.md` — sách hướng dẫn lập trình.
- `docs/PLAN.md` — danh sách thiếu sót, xếp hạng theo độ khó.
- `docs/TOKENVECTOR-PURITY.md` — mức độ thuần TokenVector của compiler.
- `docs/e_handoff/` — bàn giao từng phiên.
- `docs/llms.txt` — tóm tắt máy-đọc được.