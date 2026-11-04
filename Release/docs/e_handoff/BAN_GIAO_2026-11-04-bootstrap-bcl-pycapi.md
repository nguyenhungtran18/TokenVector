# Bàn giao — nối lại `stdlib_bcl` / `pycapi_shim` (2026-11-04)

Trạng thái: **ĐÃ KIỂM CHỨNG XONG (2026-11-04 06:5x).** Fixpoint `IL_IDENTICAL`, test mới
9/9, gate 134/134 + 42/42. `dist/tkvc-tv.exe` đã rebuild (06:49). Phần dead-code đã commit
(`68cc168`); phần nối bootstrap còn dirty chờ commit.

Kết quả chạy thật:

```
build/selfhost/vong_run6.log : gop 133 file / g1 xong / g2 xong / IL_IDENTICAL
tests/bcl_pycapi_builtins_test.tkv : 9/9 PASS (PASS re_replace_digits ... pycapi_calls_run)
build/scratch/gate6.log      : PASS=134 BUILDFAIL=0 TESTFAIL=0 OTHER=0 TIMEOUT=0 ILFAIL=0 NEG=42/42
                               GATE: PASS (134/134, negative 42/42), GATE_EXIT=0
```

---

## 1. Bối cảnh: vì sao có việc này

Chuỗi việc trước đó (đã commit):

| Commit | Việc |
|---|---|
| `94ba838` | chặn `eb_ds` đọc tên method như danh sách node ở `_khai_bien_tam_gen_cho_goi` |
| `1494860` | thêm `--show N` cho `tools/audit_ds_accessors.py` |
| (đã xong, **chưa commit**) | xoá 11 helper chết sau khi quét `def` ↔ số lần được gọi |

Bước quét dead-code (`2247 def`) báo thêm 4 hàm `bootstrap_*` không được nhắc ở đâu:
`bootstrap_dynamic_exec`, `bootstrap_ffi_feature`, `bootstrap_pycapi_shim`,
`bootstrap_stdlib_bcl`. Khi đó tôi kết luận **sai** là "bị bỏ sót khi chuyển sang
`bootstrap_*` thời P6".

**Sự thật (đọc docstring của chính bốn file):** chúng bị loại **có chủ ý** từ
2026-09-17. Codegen của chúng phát lời gọi tới các helper chỉ tồn tại trong một hằng
chuỗi **không ai tham chiếu** (`STDLIB_BCL_CIL_HELPERS`, `PYCAPI_SHIM_CIL_HELPERS`,
`DYNAMIC_EXEC_CIL_HELPERS`, `FFI_CIL_HELPERS`) → chương trình **biên dịch trót lọt rồi
nổ `System.MissingMethodException` lúc chạy**. Vì vậy "nối dây" mà không phát helper
thật = biến lỗi biên dịch rõ ràng thành lỗi runtime âm thầm. Đừng nối lại kiểu đó.

Muốn nối thì phải phát helper **thật**, bằng khuôn `IPOW_CLASS`
(`il_features/stdlib_math.tkv`): một **class riêng** + `ctx.extra_classes.append(...)`
có canh gác `ctx.emitted_types`, vì lúc codegen **không có** cơ chế thêm method vào
chính class đang sinh.

## 2. Đã làm

### `il_features/stdlib_bcl.tkv` — viết lại

- Thêm `BCL_CLASS = 'TkvBcl'`, `_ensure_bcl_class(ctx)`, `_gen_bcl_class_il()`.
- Hai helper thật:
  - `ReReplace(string,string,string)` → `[System]System.Text.RegularExpressions.Regex::Replace`
    (`.assembly extern System` được phát sẵn cho mọi chương trình — xem
    `il_features/process_feature.tkv:52`).
  - `Randint(int32,int32)` → `Random.Next`, **+1 vào biên trên** để `[min, max]` đóng
    hai đầu như `random.randint` của Python (`.NET Next` là nửa mở).
  - `rnd` là **field tĩnh, khởi tạo lần đầu**, không `newobj Random` mỗi lần gọi:
    `Random()` không tham số seed bằng đồng hồ, tạo mới trong cùng một tick sẽ trả
    cùng một dãy — "ngẫu nhiên" thành hằng lặp lại.
- Codegen đổi điểm gọi từ `{ctx.class_name}::TkvReReplace/TkvRandomRandint` sang
  `TkvBcl::ReReplace/Randint`.
- Xoá hằng `STDLIB_BCL_CIL_HELPERS` (đã bị thay bằng phát thật).

### `il_features/pycapi_shim.tkv` — viết lại

- `PYCAPI_CLASS = 'TkvPyCapi'`, `_ensure_pycapi_class`, `_gen_pycapi_class_il`.
- `PyTupleNew(int32)` → `newobj List<object>(int32)`; `PyDictNew()` →
  `newobj Dictionary<object,object>`.
- Xoá `PYCAPI_SHIM_CIL_HELPERS`.
- **Giới hạn còn lại (không phải lỗi wiring):** giá trị trả về có dtype `object`, DSL
  chưa có phép toán nào trên `object` (không `len`/`index`/`str`). Đây là lớp nền cho
  C-extension truyền `PyObject`, không phải API người dùng cuối.

### `compiler/bootstrap_all.tkv` — nối 2 module

Thêm `from il_features.stdlib_bcl import bootstrap_stdlib_bcl`,
`from il_features.pycapi_shim import bootstrap_pycapi_shim`, và 2 lời gọi ở **cuối**
`bootstrap_all()` kèm comment. Không ràng buộc thứ tự: cả 4 builtin vào bảng
`expr_builtin_codegen` (tra theo tên), không vào danh sách tuần tự.

### `tests/bcl_pycapi_builtins_test.tkv` — MỚI (chưa chạy)

9 check: `re_replace` (chữ số / không khớp / khoảng trắng / backref `[$1]`),
`random_randint` (khoảng đóng `lo==hi`, 400 lần luôn trong `[2,5]`, 400 lần phải chạm
được biên trên 5), và smoke `py_tuple_new`/`py_dict_new`. Entry `run()` trả
`test_summary(...)` đúng chuẩn corpus.

## 3. Hai module CÒN để nguyên (có lý do, đừng nối)

**`dynamic_exec.tkv`** — helper là **đồ chơi**: `TkvEvalCode` chỉ tách chuỗi quanh dấu
`+` đầu tiên rồi `Int32::Parse` hai vế (`"1+2"` → 3, `"2*3"` → nổ), `TkvExecCode` chỉ
trả `"EXEC_OK:" + code`. Nối vào là công bố `eval`/`exec` giả. Muốn thật thì phải
quyết định ngữ nghĩa (thực thi biểu thức nào? có sandbox không?) trước.

**`ffi_feature.tkv`** — helper là P/Invoke thật vào `kernel32`
(`LoadLibraryA`/`GetProcAddress`) và `ucrtbase!puts`. Docstring ghi rõ đây là **quyết
định phạm vi tính năng ngôn ngữ** (mở đường gọi native tuỳ ý), không thuần kỹ thuật.
Cần người quyết trước khi nối.

## 4. Việc còn lại — theo đúng thứ tự

```bash
cd Release

# 1. Fixpoint: lượt trước bị dừng ở "g1 xong", chưa có g2 -> dist vẫn là bản CŨ
./tools/vong.exe > build/selfhost/vong_run6.log 2>&1
tail -3 build/selfhost/vong_run6.log      # cần: g1 xong / g2 xong / IL_IDENTICAL

# 2. Chạy test mới một mình trước khi chạy cả gate (nhanh hơn nhiều)
./dist/tkvc-tv.exe tests/bcl_pycapi_builtins_test.tkv build/scratch/bcl_t.exe run
./build/scratch/bcl_t.exe                  # kỳ vọng: 9 dòng PASS + "=== bcl_pycapi_builtins_test: 9/9 PASS ==="

# 3. Gate (133 -> 134 test)
powershell -NoProfile -ExecutionPolicy Bypass -File tools/testkit_gate.ps1
# kỳ vọng: PASS=134 ... NEG=42/42, GATE: PASS
```

Nếu check `re_replace_backref` fail: `.NET Regex.Replace` nhận `[$1]` bình thường;
nếu bản dịch của DSL làm hỏng `$1` thì sửa kỳ vọng thành mẫu không backref (đừng sửa
helper cho vừa test).

Nếu `randint_inclusive_hi` fail: kiểm `_gen_bcl_class_il` có `ldc.i4.1 / add` trước
`callvirt ... Next` không — bản trong `dist` cũ có thể chưa có (xem mục 5).

## 5. Bằng chứng

**Đã chạy thật** (bản build TRƯỚC khi đổi `randint` sang đóng hai đầu — bằng chứng cho
phần `re_replace` và việc gọi helper không còn `MissingMethodException`):

- `re_replace("a1b22c", "[0-9]+", "-")` → `a-b-c`; `re_replace("abc", "z", "!")` →
  `abc` (không khớp thì giữ nguyên).
- `random_randint` chạy được và **khác nhau giữa các lần gọi** (`8`, `4` từ
  `[0,10)`) — chứng minh field tĩnh dùng chung hoạt động, không phải hằng.
- `t = py_tuple_new(3)`, `d = py_dict_new()` biên dịch + chạy, in `pycapi ok`
  (không có `MissingMethodException`).
- Lượt rebuild đó: `g1 xong / g2 xong / IL_IDENTICAL / EXIT=0`.

**Đã đóng nốt (lượt 06:47–06:5x), sau khi `+1` biên trên vào `stdlib_bcl.tkv`:**

- Fixpoint sạch `IL_IDENTICAL`; `dist/tkvc-tv.exe` 1 659 392 byte, mtime 06:49 — **mới hơn**
  mọi file nguồn, nên bản đang chạy đúng là bản có `+1` biên trên.
- `randint_inclusive_hi` **PASS** trên bản đó → `ldc.i4.1 / add` trước `callvirt Next` đúng.
- `re_replace_backref` (`[$1]`) **PASS** → `Regex.Replace` nhận backref qua đường DSL, không
  phải hạ kỳ vọng.
- Gate 134/134 + 42/42: 133 test cũ **không bị ảnh hưởng** bởi 4 builtin mới đăng ký.

## 6. Trạng thái git

`68cc168` đã commit nhóm (a) — 9 file, −149/+0. Còn dirty nhóm (b):

- **Xoá dead-code (lượt trước):** `expr_row` −5, `il_codegen` −14,
  `il_extern_dtype` −9, `int_type` −6, `question_ternary` −57, `stmt_row` −13,
  `tkv_lexer` −16, `typed_dsl_parser` −11, `tkv_compile` −18 (tổng −149, +0).
- **Nối builtin:** `bootstrap_all` +9/−0, `stdlib_bcl` +79/−46, `pycapi_shim` +58/−38,
  `dist/tkvc-tv.exe` (binary 06:49), untracked `tests/bcl_pycapi_builtins_test.tkv`.
- Untracked khác: `build/` (ignored), `.cloud-attachments/`.

Nhóm (b) giờ đã đủ điều kiện commit (gate xanh). Nhớ `git add` cả binary — đây là bản duy
nhất từng chứa `+1` biên trên.

## 7. Bẫy đã gặp, ghi lại để không lặp

1. **Hằng chuỗi helper IL không ai tham chiếu** là bẫy im lặng: codegen vẫn phát
   `call TKVApp::TkvX`, ilasm vẫn dịch (method chỉ được tham chiếu, không cần tồn tại
   lúc build), chết ở runtime. Bốn module này là di chứng.
2. **Docstring đầu file là nguồn sự thật**, không phải suy luận từ việc "thiếu dòng
   trong bootstrap_all". Tôi đã kết luận sai một lần vì bỏ qua nó.
3. `ctx.emitted_types is None` → `_ensure_*_class` **không phát** class (theo đúng khuôn
   `IPOW_CLASS`); chỉ những đường codegen có `emitted_types` mới dùng được helper.
4. `System.Random` không seed tường minh → phải giữ **một** instance tĩnh.
5. Gate chỉ tin dòng `FAIL ` hoặc `=== <tên>: A/B PASS ===` với A<B, cộng exit code;
   test im lặng in sai vẫn có thể xanh nếu không dùng `check()`.
