# TokenVector - Trạng thái (LỊCH SỬ, dừng cập nhật 2026-07-28)

**File này là NHẬT KÝ PHÁT TRIỂN lịch sử (đến 2026-07-28), KHÔNG PHẢI
trạng thái hiện tại.** Nhiều mục ghi "CHƯA làm" bên dưới (generator/yield,
closures, kế thừa) **ĐÃ hoàn tất thật** trong các phiên sau — xem
[README.md](README.md) và [USAGE_GUIDE.md](USAGE_GUIDE.md) để biết trạng
thái/tính năng hiện tại. Giữ file này lại chỉ làm hồ sơ lịch sử quyết định
kiến trúc, không phải tài liệu tham khảo cho tính năng.

---

File này CHỈ để đọc nhanh trạng thái hiện tại (LÚC ĐÓ). Chi tiết kỹ thuật
đầy đủ nằm ở `AetherTypedDSL/HANDOFF.md` (dài, không cần đọc trừ khi cần
chi tiết) - đường dẫn nay đã đổi, xem ghi chú đầu file.

## Project này là gì

Folder riêng: `C:\Claude AI Project\TokenVector\`. Import `il_codegen.py` /
`typed_dsl_parser.py` từ `AetherTypedDSL/` qua `sys.path` (dùng chung code
core, KHÔNG copy file).

## Đã xong, verify thật ✅

- **`cli.py` / `tokenvector_compile.py`** — biên dịch `sklearn.MLPClassifier`
  (đã train) thành 1 file `.exe` độc lập. Test: 45/45 mẫu khớp 100% với
  sklearn model gốc.
- **`alphaai_codegen.py`** — Groq tự viết code DSL cho kiến trúc ngoài khuôn
  mẫu (vd 2 hidden layer), biên dịch thật, tự sửa khi lỗi. Test: 10/10 khớp
  numpy.
- Bug thật đã tìm+sửa: `Single.Parse` sai do locale máy (vi-VN) — đã sửa.

## Đã xong ✅ (hướng "TokenVector thay được Python")

- `py_transpile.py` — dịch THẲNG 1 file `.py` thật (chạy được dưới CPython)
  sang `.exe`, không cần viết ngôn ngữ riêng.
- `il_codegen.py` (trong AetherTypedDSL) đã thêm: nhiều hàm/1 chương trình
  gọi lẫn nhau (`gen_il_program`).
- 2 bug thật đã tìm+sửa (chi tiết trong `HANDOFF.md`): `InvalidProgramException`
  do `br` thừa sau `ret` trong if/else lồng + return sớm; output số sai locale
  (`Single.ToString` dùng CurrentCulture thay vì Invariant).
- Test `test/py_transpile_test.py`: **12/12 khớp** kết quả CPython thật (gồm
  gọi hàm chéo nhau + if/else lồng + return sớm cả 2 nhánh).

## Nghiên cứu cạnh tranh (2026-07-28)

Đã research thật (WebSearch, không đoán): Nuitka (Python đầy đủ→C→exe, cần C
toolchain lúc build, trưởng thành nhất), Codon/Mojo (gần giống nhất về kiến
trúc — subset kiểu tĩnh→native qua LLVM/MLIR, không cần C compiler), Cython/
mypyc (ra extension module, VẪN cần Python runtime — khác hẳn), Numba (JIT,
cần Python runtime; nhánh AOT `pycc` đã bị deprecate 2025), PyPy/RPython
(không phải công cụ AOT cho user).

**Kết luận trung thực**: ngách "Python subset → .exe độc lập, zero Python
runtime" KHÔNG còn trống (Nuitka/Codon/Mojo đã làm được). Điểm khác biệt
thật của TokenVector: nhắm .NET Framework CIL (đã có sẵn trên MỌI máy
Windows — build lẫn chạy đều KHÔNG cần cài thêm gì, kể cả C compiler/LLVM),
và file nguồn vẫn là `.py` chạy được thật dưới CPython (không phải ngôn ngữ
riêng như Mojo). Phạm vi hỗ trợ hẹp hơn Nuitka/Codon/Mojo rất nhiều (chưa có
string/list/dict/class/exception) — cần nói rõ giới hạn này, không so sánh
ngang hàng.

## ✅ String thật đã xong (2026-07-28)

- `il_codegen.py`: dtype mới `'str'` (chuỗi vô hướng, chưa hỗ trợ mảng chuỗi).
  Thêm `_infer_dtype()` — suy kiểu THẬT của từng biểu thức con thay vì ép
  đồng loạt theo `body_dtype` của hàm (cần thiết vì 1 hàm giờ có thể vừa có
  biến số vừa có biến string).
  - Nối chuỗi `+` → `String.Concat`.
  - So sánh `==`/`!=` chuỗi → `String.Equals` (không dùng `ceq` — đó là so
    sánh danh tính tham chiếu, SAI với string).
  - `str(x)` (x là 1 biến số đơn) → `ToString(InvariantCulture)`.
  - Bug thật tìm+sửa: `Single.ToString()` bỏ dấu `.` cho số tròn (`0.0` →
    `"0"`), khác Python `str(0.0)` → `"0.0"` — đã thêm hậu xử lý tự động
    thêm `.0` khi thiếu.
- `typed_dsl_parser.py`: thêm `'str'` vào `DTYPES`, chặn `str[...]` (mảng
  chuỗi) với lỗi rõ ràng — chưa hỗ trợ.
- Test thật: `test/string_test.py` — 3/3 khớp CPython thật (nối chuỗi,
  `str()`, so sánh chuỗi phân biệt hoa/thường).
- Regression: `py_transpile_test.py` (12/12) và `golden_path_test.py`
  (45/45) chạy lại vẫn PASS sau khi sửa core codegen — không có gì hỏng.

## ✅ While-loop đã xong (2026-07-28)

- `il_codegen.py`: thêm `while <cond>:` (giống cấu trúc `for` nhưng không có
  biến vòng lặp riêng — brfalse/br quanh nhãn start/end).
- Bug thật tìm+sửa: gán lại THAM SỐ (vd `n = n - 1` trong while) trước đây
  bị chặn (`_store_var` chỉ cho phép local) — Python cho phép việc này thật
  sự (mutating a parameter), phải dùng `starg.s` thay vì `stloc.s` cho tham
  số. Sửa xong.
- Bug thật thứ 2 (tự gây ra, bắt được ngay nhờ test): khi sửa `_store_var`
  để thêm `starg.s`, vô tình để lại 2 dòng `stloc.s {idx}` trùng lặp →
  double-store → stack underflow → `InvalidProgramException`. Phát hiện
  qua `while_test.py`, cô lập bằng cách gọi `_store_var` độc lập (không
  qua transpile), sửa xong.
- Test: `test/while_test.py` — **5/5 khớp CPython thật** (factorial,
  count_down_sum — vòng lặp + tự giảm tham số).
- Regression: 3 bộ test cũ (string 3/3, py_transpile 12/12, golden 45/45)
  chạy lại vẫn PASS.

## Nghiên cứu "tìm code có sẵn thay vì viết từ 0" (creative-thinking-agent)

Ý tưởng cao giá trị nhất: dùng thẳng `ast` module của Python (đã dùng cho
tầng hàm/chữ ký) SÂU HƠN — thay thế luôn parser regex tự viết trong
`il_codegen.py` (_ASSIGN_RE, _IF_RE, _FOR_RANGE_RE, tokenizer biểu thức tự
chế) bằng cách duyệt trực tiếp `ast.For`/`ast.If`/`ast.BinOp`/... — giảm
code tự viết, tận dụng parser đã test kỹ của CPython. Chưa làm (rủi ro:
refactor lớn, cần làm cẩn thận để không phá vỡ các test đã pass).

Ý tưởng khả thi ngay, chi phí thấp: dùng `System.Collections.Generic.List<T>`/
`Dictionary<K,V>` (đã có sẵn trong .NET Framework) cho list/dict thay vì tự
viết mảng động — chỉ cần đúng IL call signature (`newobj`, `callvirt Add/
get_Item/set_Item/get_Count`), không cần viết engine riêng.

## ✅ List động đã xong (2026-07-28) — Bước 4/9 (xem ROADMAP.md)

- `il_codegen.py`: dtype mới `shape == 'list'` — dùng thẳng
  `System.Collections.Generic.List<T>` có sẵn (không viết engine mảng
  động riêng, đúng gợi ý brainstorm trước đó).
- Cú pháp: `lst = []`, `lst.append(x)`, `lst[i]` (đọc/ghi), `len(lst)` —
  giữ nguyên cú pháp Python thật, không bịa syntax riêng.
- Dtype phần tử list được **suy tự động** từ lần gọi `.append()` đầu tiên
  (`_find_first_append_dtype`) — vì `lst = []` không tự mang thông tin
  kiểu, và không muốn ép cú pháp lạ.
- Bug thật #1: `for j in range(len(lst)):` không parse được — regex
  `_FOR_RANGE_RE` cũ không cho phép dấu `)` lồng bên trong `range(...)`
  (chặn mọi lời gọi hàm làm cận vòng lặp). Sửa bằng regex greedy backtrack
  đúng theo cú pháp Python thật (dòng luôn kết thúc bằng `):`).
- Bug thật #2 (quan trọng, dạng lỗi mới): gọi method trên generic type đã
  đóng (`List<float32>`) phải dùng placeholder **`!0`** cho phần kiểu phụ
  thuộc generic-param trong chữ ký method (`get_Item`/`set_Item`/`Add`),
  KHÔNG phải kiểu đã thay thế (`float32`) — dù phần khai báo kiểu (trước
  `::`) vẫn dùng `<float32>`. Viết sai gây `MissingMethodException` lúc
  CHẠY (không phải lúc `ilasm` assemble — assemble vẫn qua được).
- Test: `test/list_test.py` — **4/4 khớp CPython thật**.
- Regression: toàn bộ 5 bộ test cũ (string 3/3, while 5/5, py_transpile
  12/12, golden 45/45, alphaai_codegen 10/10) chạy lại vẫn PASS.

## ✅ Dict động đã xong (2026-07-28) — Bước 5/9 (xem ROADMAP.md)

- `il_codegen.py`: dtype mới `shape == 'dict'` — dùng thẳng
  `System.Collections.Generic.Dictionary<K,V>` có sẵn (cùng pattern List).
  `TypeAnn` thêm field `key_dtype` (list chỉ cần 1 dtype phần tử, dict cần
  CẢ khóa lẫn giá trị nên không tái dùng được `dtype` đơn).
- Cú pháp: `d = {}`, `d[k] = v` (ghi, tái dùng `_INDEXED_ASSIGN_RE` sẵn
  có), `d[k]` (đọc), **`key in d`** (toán tử mới trong bộ dịch biểu thức,
  ánh xạ `Dictionary.ContainsKey`) — giữ nguyên cú pháp Python thật.
- Dtype khóa/giá trị suy tự động từ lần gán chỉ số (`d[k]=v`) đầu tiên
  suy được cả 2 phía — khác với List (chỉ cần suy 1 dtype phần tử):
  `_find_first_dict_assign_dtypes` **chủ động bỏ qua** lần gán tự tham
  chiếu (vd `d[k] = d[k] + 1` trước khi `d` có dtype) và tìm tiếp thay vì
  bỏ cuộc — cần thiết cho mẫu word-count thật (`if k in d: d[k]+=1 else:
  d[k]=1`, nhánh else luôn suy được dù nhánh if tự tham chiếu).
- Generic 2 tham số (Dictionary`2): `get_Item`/`set_Item`/`ContainsKey`
  dùng **`!0` cho khóa, `!1` cho giá trị** — mở rộng đúng bug thật đã tìm
  ở List (đóng generic vẫn cần placeholder cho chữ ký method).
- `len()` mở rộng nhận cả dict (`get_Count`) cùng list.
- Test: `test/sample_dict.py` + `test/dict_test.py` — hàm dùng dtype khóa
  (i32) KHÁC dtype giá trị (f32) + nhánh `in` cả đúng lẫn sai (bỏ qua khóa
  0) — **4/4 khớp CPython thật**, qua NGAY lần chạy đầu (không bug mới).
- Regression: toàn bộ 6 bộ test cũ (string 3/3, while 5/5, list 4/4,
  py_transpile 12/12, golden 45/45, alphaai_codegen 10/10) chạy lại vẫn PASS.

## ✅ break/continue đã xong (2026-07-28) — Bước 6/9 (xem ROADMAP.md)

- `il_codegen.py`: mở rộng codegen `for`/`while` có sẵn bằng `ctx['loop_stack']`
  (stack (continue_label, break_label), push khi vào thân vòng lặp, pop khi
  ra) — không cần cấu trúc dữ liệu mới, đúng như dự kiến trong ROADMAP.
  - `break` → nhảy thẳng tới `end_lbl`.
  - `continue` trong `for` → nhảy tới nhãn MỚI đặt ngay TRƯỚC bước tăng
    biến vòng lặp (không phải `start_lbl`) — giữ đúng ngữ nghĩa Python
    (continue vẫn phải tăng biến rồi mới kiểm tra điều kiện lại).
  - `continue` trong `while` → nhảy thẳng `start_lbl` (không có bước tăng
    riêng như `for`).
- Bug thật tìm+sửa (phát hiện qua chính test, không phải review): 2 hàm
  test đầu dùng mẹo "chẵn/lẻ qua `i - (i/2)*2`" — SAI vì `/` trên i32 sinh
  `div` (chia NGUYÊN, CIL) nhưng Python thật `/` LUÔN là chia thực (true
  division) dù toán hạng là số nguyên — 2 ngữ nghĩa khác nhau THẬT SỰ
  (không phải bug DSL, là khác biệt cố hữu giữa i32 tĩnh kiểu và Python
  `/`), khiến mẹo chia-lấy-dư cho kết quả SAI LỆCH giả (4/16 mismatch,
  `sum_odds`/`sum_while_odds` CPython thật trả về 0 vì `i/2*2==i` luôn
  đúng với chia thực). Sửa bằng cách đổi 2 hàm test sang cờ toggle
  chẵn/lẻ (không dùng `/`) — không sửa `il_codegen.py` (hành vi hiện tại
  đúng theo kiểu tĩnh, chỉ cách viết code nguồn thử nghiệm sai).
- Test: `test/sample_break_continue.py` — 4 hàm (for+break, for+continue,
  while+break, while+continue) — **16/16 khớp CPython thật** sau khi sửa
  mẹo chia ở trên.
- Regression: toàn bộ 7 bộ test cũ (string 3/3, while 5/5, list 4/4, dict
  4/4, py_transpile 12/12, golden 45/45, alphaai_codegen 10/10) PASS.

## ⚠️ Giới hạn thật đã xác nhận: `/` trên i32 KHÔNG khớp Python `/`

DSL hiện dịch `/` theo dtype TĨNH của toán hạng: i32 → CIL `div` (chia
nguyên, làm tròn về 0), f32/f64 → chia thực. Python `/` thật LUÔN là chia
thực bất kể kiểu toán hạng (dùng `//` mới là chia nguyên). Đây KHÔNG phải
lỗi cần sửa ngay (nằm ngoài phạm vi Bước 6) — chỉ là giới hạn cần TRÁNH
khi viết code test mới: không dùng mẹo `i/2*2==i` kiểu C cho i32; nếu cần
`//` thật của Python, phải làm ở bước sau (thêm toán tử `//` riêng, ánh xạ
đúng `div` cho i32 VÀ `Math.Floor(a/b)` cho float — chưa làm).

## ✅ try/except đã xong (2026-07-28) — Bước 7/9, rủi ro cao nhất (xem ROADMAP.md)

- **Đã xác minh THẬT (không đoán) trước khi viết codegen**: mine trực tiếp
  cú pháp `.try`/`catch`/`leave` của ILASM bằng 2 file `.il` viết tay riêng
  (`_tryexcept_probe/probe.il`, `probe2.il` — đã xóa sau khi dùng xong),
  assemble + CHẠY THẬT bằng `ilasm.exe`, xác nhận hành vi đúng TRƯỚC khi
  đụng vào `il_codegen.py` — đúng kỷ luật ROADMAP đề ra ("mine pattern từ
  C# thật trước khi viết, KHÔNG đoán").
- Phát hiện quan trọng qua probe (ECMA-335 III.3.64, đã xác minh THẬT):
  **`ret` trực tiếp bên trong `.try`/`.catch` là SAI cú pháp CIL** — phải
  dùng `leave` để thoát khối bảo vệ trước, `ret` thật chỉ được đặt ở nhãn
  NGOÀI cả try lẫn catch.
- Cú pháp DSL: `try:` / `except:` (CHỈ bare except — bắt MỌI loại lỗi,
  giống Python `except:` trần — CHƯA hỗ trợ `except <Loại>:` cụ thể).
- Cơ chế "epilogue": khi `return` xảy ra BÊN TRONG try/except
  (`_contains_return` quét cây thật), tự động thêm biến tạm `__ret_tmp` +
  1 nhãn cuối hàm — `return` bên trong lưu giá trị + `leave` tới đó, `ret`
  THẬT chỉ nằm ở nhãn đó. Hàm KHÔNG có return-trong-try (chỉ gán lại biến
  rồi return sau) thì KHÔNG cần epilogue — tránh sinh code-không-thể-tới
  thừa (đúng bài học từ bug "br thừa sau ret" ở Bước 3).
- Test: `test/sample_try_except.py` — 2 hàm (`safe_div`: return trong cả
  2 nhánh, cần epilogue; `try_get_or_fallback`: chỉ gán lại biến, return
  sau try/except, KHÔNG cần epilogue) — **10/10 khớp CPython thật**, gồm
  cả 2 ca CHIA CHO 0 thật sự (`ZeroDivisionError` → vào nhánh `except`
  đúng, không crash chương trình).
- Bug thật gặp khi viết test (không phải bug `il_codegen.py`): đặt tên
  tham số `default` — trùng từ khóa dành riêng của ILASM (`_IL_RESERVED_WORDS`
  không có `default`) → `ilasm` báo lỗi cú pháp. Đổi tên tham số thành
  `fallback`, không đụng đến danh sách từ khóa dành riêng (ngoài phạm vi
  Bước 7).
- Regression: toàn bộ 8 bộ test cũ (string 3/3, while 5/5, list 4/4, dict
  4/4, break/continue 16/16, py_transpile 12/12, golden 45/45,
  alphaai_codegen 10/10) PASS.

## ✅ Self-host đã xong (2026-07-28) — Bước 8/9 (xem ROADMAP.md)

- **Phạm vi chọn (trung thực, không "tự thay toàn bộ Python")**: không thể
  tự-host TOÀN BỘ `cli.py`/`tokenvector_compile.py` (cần joblib, argparse,
  sklearn introspection, string/IL-text meta-programming — đều ngoài phạm
  vi DSL đã công bố "Không làm"). Chọn đúng phần lõi CÓ THỂ tự-host và có
  giá trị chứng minh nhất: **logic inference (MLP forward + argmax)** mà
  `tokenvector_compile.py` sinh ra qua 3 macro CHUYÊN DỤNG cho MLP
  (`dense`/`normalize`/`argmax`, định nghĩa sẵn trong `_expand_macros`).
- Viết lại CHÍNH XÁC phép tính đó bằng DSL THÔ — vòng lặp `for`/`if`/mảng
  2 chiều thường, **KHÔNG dùng 3 macro trên** — chứng minh ngôn ngữ TỰ NÓ
  (for/if/while/mảng đã có từ Bước 1-3, không cần macro riêng cho MLP) đủ
  mạnh viết lại tính năng lõi của chính công cụ.
- File `test/sample_self_host_classify.py` — file `.py` THẬT (chạy được
  dưới CPython thật, `from math import tanh` + `import numpy as np` ở
  module level để vừa chạy thật vừa khớp cú pháp gọi hàm 1-tên của DSL,
  không dùng `math.tanh` vì DSL chưa hỗ trợ gọi qua `.`).
- Transpile qua **CHÍNH `py_transpile.py`** (không viết pipeline riêng),
  build `Main()` tái dùng hạ tầng CÓ SẴN của `tokenvector_compile.py`
  (`_emit_1d`/`_emit_2d`/`_emit_str_array`/`_LocalAlloc` — đây là phần hạ
  tầng chung, KHÔNG phải phần được tự-host, chỉ đóng gói argv/hằng số).
- Verify: đối chiếu VỚI CHÍNH model `golden_iris` thật (đã train bởi
  `golden_path_test.py`, `activation='tanh'`, `MinMaxScaler`) trên **TOÀN
  BỘ 150 mẫu Iris** (không chỉ tập test con) — **150/150 khớp
  `sklearn.predict()` thật**, qua ngay lần chạy đầu (không bug mới —
  logic đã được xác nhận gián tiếp trước đó qua file cũ
  `AetherTypedDSL/AlphaAI/gen_vectorize_comparison.py`, vốn chỉ đo LOC chứ
  chưa từng thực thi thật; đây là lần đầu XÁC MINH CHẠY THẬT mẫu này).
- Regression: toàn bộ 9 bộ test cũ (string 3/3, while 5/5, list 4/4, dict
  4/4, break/continue 16/16, try/except 10/10, py_transpile 12/12, golden
  45/45, alphaai_codegen 10/10) PASS.

## ✅ Bước 9 đã xong (2026-07-28) — đổi `.py` → `.tkv`, ROADMAP HOÀN TẤT (9/9)

- **Xác minh THẬT trước khi đổi** (không giả định): `runpy.run_path()` +
  `ast.parse()` không hề quan tâm đuôi file — test độc lập xác nhận 1 file
  `.tkv` (nội dung y hệt 1 `.py` cũ) chạy được dưới CPython 100% giống
  nhau. Không có rủi ro kỹ thuật khi đổi đuôi.
- Đổi `py_transpile.py` → **`tkv_compile.py`** (API/tên hàm giữ nguyên —
  `extract_program`/`transpile_program`/`transpile_file` — chỉ đổi tên
  module + docstring, tham số `py_path` → `tkv_path`).
- Đổi TẤT CẢ file mẫu trong `test/` từ `.py` → **`.tkv`**: `sample_program`,
  `sample_program_str`, `sample_while`, `sample_list`, `sample_dict`,
  `sample_break_continue`, `sample_try_except`, `sample_self_host_classify`
  — nội dung KHÔNG đổi (vẫn là Python hợp lệ, chỉ đổi tên nhận diện).
  `.il`/`.exe` giữ nguyên đuôi (chuẩn ngành CIL + bắt buộc của Windows,
  đúng như ROADMAP.md đã định trước).
- Đổi `py_transpile_test.py` → **`tkv_compile_test.py`**, cập nhật mọi
  import (`from py_transpile import` → `from tkv_compile import`) và mọi
  đường dẫn `sample_*.py` → `sample_*.tkv` trong 7 file test còn lại.
- Regression: toàn bộ **10 bộ test** (string 3/3, while 5/5, list 4/4,
  dict 4/4, break/continue 16/16, try/except 10/10, tkv_compile 12/12,
  golden 45/45, alphaai_codegen 10/10, self-host 150/150) PASS sau khi
  đổi tên — không hành vi nào thay đổi, đúng như kỳ vọng (đổi tên thuần
  túy, không đổi logic).
- **Icon/metadata `.exe`**: CHƯA làm (nhúng icon Win32 thật vào PE qua
  `ilasm /win32icon:...` là khả thi và không phức tạp, nhưng cần 1 file
  `.ico` thật chưa có sẵn trong dự án — việc THIẾT KẾ hình ảnh nằm ngoài
  phạm vi yêu cầu "đổi `.py` sang `.tkv`" của phiên này; để lại làm sau
  nếu owner muốn, không tính là nợ kỹ thuật của Bước 9).

## 🎉 ROADMAP.md hoàn tất 9/9 bước

Tất cả 9 bước trong lộ trình "Python tiến hóa thành TokenVector" đã xong
và verify thật (không lý thuyết): nhiều hàm/1 chương trình, string, while,
list, dict, break/continue, try/except, self-host, đổi tên `.tkv`. Việc
tiếp theo (nếu có) là quyết định hướng đi MỚI ngoài roadmap này — xem
mục "Không làm" trong ROADMAP.md để biết phạm vi đã CHỦ ĐỘNG loại trừ
(class/OOP, decorator, generator, async, exec/eval động).

## ✅ Ngoài roadmap gốc — Bước 10: CLI biên dịch tự động (2026-07-28)

Sau khi kết luận "chưa thay được Python", ưu tiên cao nhất được chọn để
tiến gần hơn: trước giờ MỌI ví dụ/test đều phải tự tay viết `Main()` bằng
IL (đọc argv, gọi hàm, in kết quả) — TokenVector mới dùng được "qua
script Python", chưa phải "công cụ biên dịch gõ lệnh thật".

- `tkv_compile.py` thêm `build_generic_main()`/`compile_tkv_cli()`: tự
  động sinh `Main()` cho BẤT KỲ hàm entry nào có tham số/return VÔ HƯỚNG
  (i32/i64/f32/f64/str) — không thêm tính năng ngôn ngữ mới, chỉ đóng gói
  lại hạ tầng codegen đã verify (parse argv theo dtype, in kết quả).
  Chưa hỗ trợ tham số/return là mảng/list/dict (báo lỗi rõ ràng, không
  đoán mò cách serialize).
- File mới `tkv.py` — lệnh thật: `python tkv.py build file.tkv [--entry
  NAME] [--out out.exe]`. Tự chọn entry point nếu file chỉ có 1 hàm hoặc
  có hàm tên `main`; nhiều hàm mà không rõ entry → báo lỗi rõ, không đoán.
- **Dùng AlphaAI (Groq) phụ việc sinh nhanh 2 hàm test đa dạng dtype**
  (theo yêu cầu chủ dự án) — `avg_of_range(n:i32)->f32` và
  `clamp_i32(x,lo,hi:i32)->i32`. `avg_of_range` thất bại 3/3 lần thử đầu
  (báo lỗi rõ ràng, không giấu), sửa lại mô tả yêu cầu rõ hơn (chỉ dùng
  biến vô hướng tích lũy, không mảng) → thành công ngay lần sau.
- **Bug thật NGHIÊM TRỌNG tìm được qua chính việc dùng AlphaAI** (không
  phải qua review thủ công): `alphaai_codegen.py`'s prompt tài liệu SAI —
  ghi ternary là cú pháp Python `a if cond else b`, nhưng `il_codegen.py`
  THẬT SỰ chỉ hỗ trợ kiểu C `cond ? a : b`. AI dùng đúng theo tài liệu
  (sai) → `parse_expr()` **IM LẶNG bỏ qua phần còn lại của biểu thức**
  (không có kiểm tra còn dư token sau khi parse xong) → `clamp_i32` biên
  dịch "thành công" nhưng SAI KẾT QUẢ (trả về `x` gốc thay vì kẹp vào
  [lo,hi]) — chỉ lộ ra qua đối chiếu CPython thật, KHÔNG lộ qua bước biên
  dịch. Đây là loại bug nguy hiểm nhất: im lặng sai, không báo lỗi.
  - Sửa `parse_expr()` (`il_codegen.py`): thêm kiểm tra `EOF` ngay sau khi
    parse xong — token thừa giờ báo `SyntaxError` rõ ràng thay vì bị nuốt.
  - Sửa lại đúng phần mô tả ternary trong prompt của `alphaai_codegen.py`
    (kiểu C, có ví dụ đúng/sai rõ ràng).
  - AI sinh lại `clamp_i32` với prompt đã sửa → ra ĐÚNG cú pháp C-ternary
    ngay lần đầu; verify thủ công (không qua `.tkv`/ast vì `cond ? a : b`
    không phải Python hợp lệ) — cả 4/4 ca test khớp Python 100% SAU khi
    sửa (trước khi sửa: 2/4 sai).
- Test: `test/cli_test.py` — 5 hàm (i32/i32, f32/f32, str/str, 2 hàm
  AlphaAI sinh) qua **CHÍNH `tkv build`** — **20/20 khớp CPython thật**.
- Bug thật thứ 2 (nhỏ hơn, tự tìm được qua chính test mới): thiếu bước
  "thêm `.0` cho số tròn" (bug locale/format đã sửa ở nơi khác từ Bước 2)
  trong `build_generic_main`'s luồng in f32/f64 — quên áp dụng lại pattern
  đã có, sinh `"7"` thay vì `"7.0"`. Sửa xong, verify lại đúng.
- Regression: toàn bộ 11 bộ test (10 bộ cũ + `cli_test.py` mới) PASS sau
  khi sửa `parse_expr()` — xác nhận fix không phá hành vi cũ nào.

## ✅ Ngoài roadmap gốc — Hướng #2: `for x in lst:` (2026-07-28)

- **Cách làm rủi ro thấp nhất**: KHÔNG thêm codegen mới — `List<T>` đã hỗ
  trợ đọc theo chỉ số (`get_Item`/`get_Count`, Bước 4) nên chỉ cần khai
  triển `for x in lst:` THÀNH VĂN BẢN sang `for __iterlistN_idx in
  range(len(lst)): x = lst[__iterlistN_idx]` — đúng tinh thần macro
  `_expand_macros` đã có sẵn cho `dense`/`normalize`/`argmax` (macro
  TEXT-LEVEL, không sinh opcode CIL mới nào).
- Tên biến chỉ số ẩn dùng bộ đếm `counter` (giống các macro khác) → xác
  nhận AN TOÀN cả khi **LỒNG NHAU** (`for x in outer: ... for y in
  inner:`) — mỗi lần gặp macro này bộ đếm tăng, không trùng tên dù lồng
  sâu bao nhiêu.
- Regex `_FOR_IN_LIST_RE` yêu cầu container là 1 TÊN BIẾN TRẦN ngay trước
  dấu `:` — xác nhận KHÔNG khớp nhầm `for i in range(n):` (có dấu ngoặc
  nên không khớp `\w+$`).
- Không kiểm tra container có thật là list lúc expand (thuần text, chưa
  có `known_shapes`) — nếu dùng sai (vd trên biến scalar), lỗi sẽ lộ RÕ
  RÀNG sau ở `len()`/`index` của `_compile_expr`, không im lặng sai (bài
  học trực tiếp từ bug `parse_expr` vừa sửa ở trên).
- Test: `test/sample_for_in_list.tkv` — 2 hàm (đơn giản + lồng 2 lớp
  `for...for`) — **8/8 khớp CPython thật**, qua ngay lần chạy đầu.
- Regression: toàn bộ 12 bộ test (11 bộ cũ + `for_in_list_test.py` mới)
  PASS.
## ✅ Ngoài roadmap gốc — `for k, v in d.items():` (2026-07-28)

- **Xác minh THẬT trước khi viết codegen** (đúng kỷ luật Bước 7): mine cú
  pháp enumerator CIL thật bằng 1 file `.il` viết tay riêng (build
  `Dictionary<int32,float32>`, gọi `GetEnumerator`/`MoveNext`/`get_Current`/
  `get_Key`/`get_Value`), assemble + CHẠY THẬT, đối chiếu 1 phép tính tham
  chiếu bằng tay trước khi đụng `il_codegen.py`.
- Khác với `for x in lst:` (chỉ cần khai triển văn bản vì List có chỉ số
  vị trí) — Dictionary KHÔNG có chỉ số vị trí, buộc phải sinh CIL enumerator
  THẬT: `GetEnumerator()` → local `Dictionary<K,V>.Enumerator` (struct) →
  vòng lặp `MoveNext()`/`get_Current()` (trả `KeyValuePair<K,V>`, cũng là
  struct) → `get_Key()`/`get_Value()`. Struct cần địa chỉ (`ldloca.s`) để
  gọi instance method, giống mẫu `ToString()` đã gặp.
- Local ẩn (`enumerator`, `KeyValuePair` tạm) dùng tên DUY NHẤT qua
  `id(stmt)` (giống cơ chế `tern_temp_of_id` cho ternary) — không cần
  thêm bộ đếm xuyên suốt `_parse_block`, an toàn khi LỒNG NHAU.
- **Bug thật tìm được qua chính test** (không phải review): `GetEnumerator()`
  và `get_Current()` là method định nghĩa trên generic type MỞ
  (`Dictionary`2`/`Enumerator`2`), nên **return type** của chúng phải dùng
  placeholder `!0, !1` — tôi lại mắc ĐÚNG loại lỗi đã tìm+sửa cho List's
  `get_Item` ở Bước 4 (dùng nhầm kiểu đã thay thế thay vì placeholder) dù
  probe `.il` của tôi đã viết ĐÚNG — do khi chuyển từ probe sang
  `il_codegen.py` đã dùng chung 1 biến `enum_type`/`kv_type` (kiểu cụ thể)
  cho CẢ vị trí "kiểu khai báo" (đúng, cần cụ thể) LẪN vị trí "kiểu trả
  về" (sai, cần placeholder) — `MissingMethodException` lúc CHẠY (không
  phải lúc `ilasm` assemble). Sửa bằng cách tách riêng `enum_type_ph`/
  `kv_type_ph` (`!0, !1`) chỉ dùng cho 2 vị trí return-type đó.
- **Giới hạn thật ghi nhận thêm** (không phải bug mới, đã tồn tại từ Bước
  5 Dict, chỉ lộ rõ hơn qua test này): dtype khóa của dict có thể suy SAI
  khi biến khóa (vd biến vòng lặp `for i in range(n):`) được khai báo SAU
  dòng `d = {}` trong thứ tự duyệt — `_find_first_dict_assign_dtypes` thử
  suy trước khi `i` được đăng ký, rơi về `body_dtype` (vd f32 thay vì
  i32 đúng ngữ nghĩa Python). KHÔNG gây sai số học (khóa được lưu/đọc
  NHẤT QUÁN theo cùng dtype "sai" đó ở cả 2 phía ghi/đọc, xem test 8/8
  vẫn khớp) nhưng khóa CIL thật sự không phải kiểu Python gốc — chưa sửa
  (rủi ro: cần 1 pass riêng đăng ký for-loop var TRƯỚC khi suy dtype
  container, ngoài phạm vi yêu cầu lần này).
- Test: `test/sample_for_in_dict.tkv` — 2 hàm (đơn giản + lồng 2 lớp
  `for...for` qua `.items()`) — **8/8 khớp CPython thật**.
- Regression: toàn bộ 13 bộ test (12 bộ cũ + `for_in_dict_test.py` mới)
  PASS.

## ✅ Ngoài roadmap gốc — String mạnh hơn: `s[i]` + `len(s)` (2026-07-28)

- `len(s)` — mở rộng `len()` (trước chỉ list/dict) nhận thêm string, dùng
  `String.get_Length()` (tên khác `get_Count()` của List/Dictionary —
  BCL thật sự đặt tên khác nhau, không phải lỗi đánh máy).
- `s[i]` — đọc, trả về **1 chuỗi độ dài 1** (đúng ngữ nghĩa Python thật —
  Python không có kiểu `char` riêng). `.NET` indexer thật của string
  (`get_Chars`) trả `System.Char`, KHÔNG phải `String` — phải chuyển đổi:
  lấy `char` rồi dùng constructor `String(char, int32 count)` với
  `count=1` để có lại 1 chuỗi thật, tránh phải lấy địa chỉ 1 `char` tạm
  (né được giới hạn kiểu value-type tương tự `str()`/`ToString()`).
- `s[i] = x` (gán qua chỉ số) — báo lỗi biên dịch RÕ RÀNG thay vì cho
  qua: string là BẤT BIẾN trong Python thật (`TypeError` lúc CPython chạy
  thật), TokenVector cũng từ chối ngay lúc biên dịch.
- Test: `test/sample_string_index.tkv` — 4 hàm (`first_char`,
  `last_char` dùng `s[len(s)-1]`, `str_length`, `char_at` có tham số chỉ
  số) — build qua CHÍNH `compile_tkv_cli` (CLI tự động, dogfood tính
  năng CLI + tính năng string mới cùng lúc) — **13/13 khớp CPython thật**,
  qua ngay lần chạy đầu.
- Regression: toàn bộ 14 bộ test (13 bộ cũ + `string_index_test.py` mới)
  PASS.

## ✅ Ngoài roadmap gốc — File I/O cơ bản (2026-07-28)

- 4 hàm builtin mới, ánh xạ thẳng `System.IO.File.*`:
  - `read_file(path) -> str` (`File.ReadAllText`) — vị trí BIỂU THỨC
    (dùng như `content = read_file(path)`).
  - `write_file(path, content)` / `append_file(path, content)`
    (`File.WriteAllText`/`AppendAllText`) — cả 2 KHÔNG trả giá trị, phải
    dùng như **LỆNH ĐỘC LẬP** (không gán biến).
  - `file_exists(path) -> i32` (`File.Exists`, bool 0/1).
- **Cú pháp mới cần thêm cho DSL**: trước giờ MỌI lệnh gọi hàm đều nằm
  trong 1 biểu thức (gán biến/return/điều kiện...) — chưa có "gọi hàm như
  1 lệnh độc lập, bỏ qua giá trị trả về" (Python thật cho phép, vd
  `print(x)` không gán). Thêm `_CALL_STMT_RE` + kind `call_stmt` (tái
  dùng THẲNG `parse_expr` cho phần `name(args)`, không tự tách tham số
  bằng tay). CHỈ chấp nhận 2 hàm void có sẵn (`write_file`/`append_file`)
  — gọi hàm do người dùng định nghĩa theo cách này bị từ chối RÕ RÀNG
  (tránh im lặng bỏ qua return value nếu sau này mở rộng ẩu).
- **Vấn đề file `.tkv` thật gặp lại** (giống bug `tanh`/`math.tanh` ở
  Bước 8 Self-host): `read_file`/`write_file`/... không phải hàm CPython
  có sẵn — không thể định nghĩa trực tiếp trong `.tkv` (mọi `def` top-level
  đều bị `extract_program()` cố transpile, thân hàm thật mở file/method
  `.read()`/`.write()` không nằm trong cú pháp DSL, sẽ báo lỗi ngay).
  Giải pháp: file `test/_file_io_helpers.py` RIÊNG định nghĩa 4 hàm này
  bằng Python thật, `.tkv` chỉ `from _file_io_helpers import ...`
  (`ast.ImportFrom` được `extract_program()` bỏ qua hoàn toàn) — vừa chạy
  thật dưới CPython vừa không bị hiểu nhầm là thân hàm cần biên dịch.
- Test: `test/sample_file_io.tkv` — 3 hàm (ghi+kiểm tra tồn tại, ghi+đọc+
  đo độ dài, ghi+nối thêm+đọc) — build qua CHÍNH `compile_tkv_cli` —
  **3/3 khớp CPython thật**, qua ngay lần chạy đầu.
- Regression: toàn bộ 15 bộ test (14 bộ cũ + `file_io_test.py` mới) PASS.

## ✅ Ngoài roadmap gốc — `except <Loại>:` + `finally:` (2026-07-28)

- **Xác minh THẬT trước khi viết codegen** (đúng kỷ luật đã dùng ở Bước 7):
  mine 2 mẫu CIL bằng probe `.il` viết tay riêng — (1) NHIỀU `catch` trên
  cùng 1 `.try` (khớp theo loại lỗi, giống Python thử từng `except` theo
  thứ tự), (2) `.try`/`finally` LỒNG bên trong `.try`/`catch` (xác nhận
  `leave` từ bên trong tự động kích hoạt `finally` bên ngoài ĐÚNG 1 LẦN,
  dù có ngoại lệ hay không) — cả 2 đều assemble + CHẠY THẬT đúng trước
  khi đụng `il_codegen.py`. Bắt được 1 lỗi viết probe của chính mình
  (thiếu `ldloc.0` trước `ret`) qua chính bước cô lập này, không phải bug
  CIL — kỷ luật cô lập từng mảnh nhỏ trước khi ghép lại có tác dụng THẬT.
- Cú pháp: `except <Loại>:` (nhiều nhánh theo thứ tự, khớp Python) + tối
  đa 1 `except:` trần PHẢI là nhánh cuối cùng nếu có + `finally:` tùy
  chọn (đứng SAU mọi except, có thể KHÔNG cần except nào — Python cho
  phép `try: ... finally:` đơn thuần).
- Ánh xạ tên lỗi Python thật → kiểu CLR thật (`_EXC_TYPE_MAP`, KHÔNG đoán
  — chỉ map các loại lỗi THẬT SỰ có thể xảy ra từ code TokenVector sinh
  ra, vì DSL chưa có `raise`): `ZeroDivisionError`→`DivideByZeroException`,
  `KeyError`→`KeyNotFoundException`, `IndexError`→`ArgumentOutOfRangeException`
  (CHỈ khớp `List<T>` — mảng cố định `float32[]` ném
  `IndexOutOfRangeException` KHÁC LOẠI, một giới hạn thật đã biết, chưa
  hợp nhất), `ValueError`→`FormatException`, `OverflowError`→`OverflowException`.
- Codegen sinh 3 dạng tùy trường hợp: chỉ except (N handler, tổng quát
  hóa bản 1-handler cũ), chỉ finally (không except), CẢ HAI (lồng `.try`
  bên trong `.try`/`finally`).
- **Giới hạn cố ý (an toàn hơn là cố phân biệt đúng-sai)**: `return` HOẶC
  `break`/`continue` bên trong `finally:` bị từ chối RÕ RÀNG lúc biên dịch
  — CIL cấm `ret`/`br` thoát khỏi `finally` (chỉ `endfinally`); việc phân
  biệt "vòng lặp định nghĩa bên trong chính finally" (hợp lệ) với "thoát
  ra vòng lặp bên ngoài" (không hợp lệ) chưa làm — từ chối RỘNG HƠN cần
  thiết để không bao giờ sinh IL sai.
- Test: `test/sample_except_finally.tkv` — 4 hàm (nhiều except theo loại,
  bắt `KeyError` từ dict, `finally` không except — gồm cả ca KHÔNG bắt
  lỗi nên lỗi lan truyền tiếp mà `finally` VẪN chạy trước khi crash, và
  `except`+`finally` kết hợp) — **18/18 khớp CPython thật**, xác nhận
  `finally` THẬT SỰ chạy qua 1 file phụ ghi bởi `append_file` (không chỉ
  dựa vào giá trị trả về).
- Regression: toàn bộ 16 bộ test (15 bộ cũ + `except_finally_test.py`
  mới) PASS.

## ✅ Ngoài roadmap gốc — Tuple / nhiều giá trị trả về (2026-07-28)

- **Giới hạn cố ý**: CHỈ hỗ trợ tuple **ĐÚNG 2 phần tử** (không tổng quát
  N phần tử) — đơn giản hóa có chủ đích, đủ cho nhu cầu phổ biến nhất
  ("trả về 2 giá trị").
- **Xác minh THẬT trước khi viết codegen**: mine bằng probe `.il` riêng —
  xác nhận `System.ValueTuple<T1,T2>` (struct) có sẵn trong mscorlib trên
  .NET Framework 4.7+ (không phải gói riêng), và đọc trường `Item1`/`Item2`
  qua `ldfld` hoạt động TRỰC TIẾP trên 1 giá trị value-type (không cần
  địa chỉ như khi gọi instance method trên struct — khác `ToString()`).
- Cú pháp:
  - Chữ ký: `-> "(dtype, dtype)"` (mở rộng `typed_dsl_parser.parse_type_ann`
    nhận dạng `(` mở đầu).
  - `return a, b` — parse bằng `parse_expr_list()` MỚI (tái dùng thẳng
    `_ExprParser`, KHÔNG tự tách chuỗi theo dấu phẩy bằng tay — tránh cắt
    sai khi biểu thức con có dấu phẩy lồng trong lời gọi hàm, vd
    `return foo(a, b), c`).
  - `x, y = f(...)` — giải nén 1 lời gọi hàm tra ve tuple thật (lưu vào
    local tạm, đọc `Item1`/`Item2` 2 lần).
  - `x, y = a, b` — gán song song, ĐÚNG ngữ nghĩa hoán đổi Python thật
    (`x, y = y, x`): đánh giá CẢ 2 vế vào local tạm TRƯỚC, mới gán vào
    target — không bị ghi đè giữa chừng.
- CLI tự động (`tkv build`) KHÔNG hỗ trợ entry trả về tuple (chỉ vô
  hướng, đúng như thiết kế Bước CLI trước) — hàm trả tuple được kiểm
  chứng GIÁN TIẾP qua 1 hàm khác gọi + giải nén nó.
- Test: `test/sample_tuple.tkv` — `make_pair` (trả tuple), `use_pair`
  (gọi + giải nén), `swap_test` (hoán đổi) — **8/8 khớp CPython thật**,
  qua ngay lần chạy đầu.
- Regression: toàn bộ 17 bộ test (16 bộ cũ + `tuple_test.py` mới) PASS.

## ✅ Ngoài roadmap gốc — Class dạng record (2026-07-28)

- **Giới hạn cố ý**: CHỈ field-only (mọi field khai bao dạng
  `ten: "dtype"`, dtype vô hướng i32/i64/f32/f64/str) — KHÔNG kế thừa,
  KHÔNG method thật (ngoại trừ `__init__` — xem dưới), KHÔNG field kiểu
  record/list/dict/tuple lồng nhau. Sinh ra 1 **CIL struct thật**
  (`.class value ansi sealed ... extends [mscorlib]System.ValueType`)
  với field `public` + 1 `.ctor` TỰ SINH nhận đủ tham số theo đúng thứ tự
  field khai báo — tái dùng chính ý tưởng đã verify ở tuple (ValueTuple):
  `newobj` để khởi tạo, `ldfld` để đọc.
- **Khác tuple ở chỗ GHI được field**: `p.x = expr` cần ĐỊA CHỈ của
  struct (không chỉ giá trị) — `stfld` trên value type đòi
  `ldloca.s`/`ldarga.s` trước (hàm mới `_load_var_addr`), khác `ldfld`
  đọc (không cần địa chỉ, tiêu thụ thẳng giá trị trên stack).
- **`.tkv` vẫn là Python thật chạy được**: record được viết kèm 1
  `__init__(self, x, y): self.x = x; self.y = y` thật — nhưng
  `tkv_compile._extract_record_def` BỎ QUA HOÀN TOÀN `__init__` lúc biên
  dịch (không dùng để sinh CIL, chỉ tồn tại để `Point(1.0, 2.0)` gọi được
  thật dưới CPython khi đối chiếu kết quả) — cùng tinh thần "helper riêng
  không transpile" đã dùng ở File I/O (Bước trước).
- Cú pháp: `class Ten:` + field `ten: "dtype"` (top-level, không lồng
  trong hàm) → dùng làm dtype tham số/return (`p: "Point"`,
  `-> "Point"`) hoặc khai báo biến cục bộ (`p = Point(a, b)`); đọc field
  `p.x`; ghi field `p.x = expr`.
- **`.class value` của record được sinh RIÊNG** (`gen_record_types()`)
  và ghép vào file `.il` NGOÀI class chương trình chính (không lồng bên
  trong `Program`/`TKVApp`) — `compile_tkv_cli` ghép trước
  `.class public auto ansi <ClassName> extends System.Object`.
- CLI tự động (`tkv build`) KHÔNG hỗ trợ tham số/return kiểu record (chỉ
  vô hướng, đúng thiết kế cũ) — record được kiểm chứng qua 2 hàm vô
  hướng dùng `Point` NỘI BỘ (khởi tạo + đọc + ghi field).
- Test: `test/sample_record.tkv` (`Point` 2 field f32, `make_point` đọc,
  `move_point` ghi cả 2 field) — **7/7 khớp CPython thật, qua ngay lần
  chạy đầu** (không cần probe `.il` riêng — tái dùng trực tiếp pattern
  `newobj`/`ldfld` đã verify ở tuple; `ldloca.s`+`stfld` là suy luận trực
  tiếp từ ECMA-335, không phải mẫu mới chưa biết).
- Regression: toàn bộ 18 bộ test (17 bộ cũ + `record_test.py` mới) PASS.

## 📋 Kế hoạch phiên sau (2026-07-28, kiểm soát lại toàn bộ trạng thái)

### Đã có (18/18 test PASS, xem chi tiết các mục ✅ ở trên)
Biến vô hướng (i32/i64/f32/f64/str), mảng rank 1-2, `List`/`Dict` động,
`for`/`while`/`if`/`break`/`continue`, `try/except <Loại>/finally`, tuple
2 phần tử, class dạng record (field-only), string (nối/so sánh/`s[i]`/
`len`), File I/O cơ bản, `for x in lst:`, `for k,v in d.items():`, CLI tự
động (`tkv build`), AlphaAI-codegen (Groq generate+verify+retry).

### 3 khoảng trống ngôn ngữ còn thiếu (xếp ưu tiên, đã thống nhất với owner)
1. **Method thật trên record** (không chỉ field) — mở khoá OOP tối
   thiểu. Rủi ro cần probe: gọi instance method trên value type cần
   `ldloca.s` trước `call` (đã biết pattern từ string/`ToString()`), chưa
   test method DO NGƯỜI DÙNG định nghĩa trên struct tự sinh.
2. **Container lồng nhau** (`List<List<i32>>`, list/dict chứa record) —
   không có thì không biểu diễn được dữ liệu 2D/bảng thật. Rủi ro cần
   probe: `!0`/`!1` placeholder có lồng đúng khi generic-trong-generic
   không (chưa từng test).
3. **Import module TokenVector khác** (không phải import Python) — mở
   khoá chia dự án lớn thành nhiều file. Rủi ro: cross-file func_table,
   namespace CIL, trùng tên class record giữa file.

### Chiến lược AI-port (đã ghi memory `project-tokenvector-ai-port-strategy`)
Sau khi có đủ 3 khoảng trống trên (từ vựng ngôn ngữ đủ rộng), dùng
`alphaai_codegen.py` (AlphaAI/Groq) để dịch HÀNG LOẠT hàm/thuật toán có
sẵn (Python/numpy/stdlib) sang cú pháp TokenVector, verify tự động qua
compile+chạy đối chiếu CPython — KHÔNG làm bước này TRƯỚC khi 3 khoảng
trống xong (sẽ chỉ ra hàng loạt lỗi compile do thiếu từ vựng, không tiết
kiệm được gì).

**Chia việc (đã thống nhất với owner):**
- **Tôi (Claude):** thiết kế + code `il_codegen.py`/`typed_dsl_parser.py`
  cho 3 khoảng trống trên, probe `.il` xác minh THẬT trước khi viết
  codegen, duyệt lại kết quả AlphaAI sinh trước khi tin là PASS thật.
- **AlphaAI:** dịch hàng loạt hàm cụ thể sang cú pháp đã có sẵn (sau khi
  3 khoảng trống xong), tự viết test đối chiếu CPython qua vòng lặp
  generate→compile→verify→retry đã chứng minh hoạt động.

### 4 mục tiêu cứng của owner (xem memory `project-tokenvector-4-goals`)
1. Thay thế Python nói chung, 2. Vượt Nuitka/Codon/Mojo, 3. Ma trận/vector
cho AI (đã khớp hướng hiện tại), 4. Nhỏ gọn/chạy cấu hình thấp (đã khớp
hướng hiện tại). Mục 1+2 là mục tiêu DÀI HẠN — báo cáo tiến độ trung thực
từng bước, KHÔNG tuyên bố ngang bằng/vượt khi chưa verify thật.

**Bắt đầu phiên sau bằng:** khoảng trống #1 (method thật trên record) —
ưu tiên cao nhất vì rủi ro kỹ thuật thấp nhất (đã có sẵn manh mối
`ldloca.s`+`call` từ pattern string/ToString()) và mở khoá ngay OOP tối
thiểu.

## ✅ AlphaAI chạy song song (2026-07-28) — 2 bug thật + probe khoảng trống #1

**AlphaAI (Groq) sinh song song 5 hàm dùng tù vựng MỚI** (string/dict/list/
try-except/tuple — lần đầu AlphaAI dùng thử, `_DSL_REFERENCE` trong
`alphaai_codegen.py` đã cập nhật đầy đủ tù vựng hiện có) trong lúc Claude
làm probe khoảng trống #1 — xem `test/alphaai_batch_port.py`,
`test/sample_alphaai_ported.tkv`, `test/alphaai_ported_test.py`.

- **2 bug thật trong `il_codegen.py` do chính stress-test này lộ ra** (đã
  sửa, KHÔNG sửa code AlphaAI sinh — giữ nguyên 100% làm bằng chứng):
  1. `d[c] = 1` (dict value là hằng số nguyên) trong 1 hàm TRẢ VỀ `str` —
     dtype giá trị dict suy sai thành `'str'` (fallback về `body_dtype`
     của HÀM thay vì kiểu THẬT của giá trị) → `KeyError: 'str'` tại
     `IL_LDC_OP['str']` (không có mã `ldc` cho string). Sửa bằng
     `_infer_literal_dtype()` MỚI — đoán dtype từ CHÍNH cú pháp hằng số
     (có dấu `.` → float, không → int) làm tầng fallback TRƯỚC
     `body_dtype`, áp cho `declare_scalar` và `_find_first_dict_assign_dtypes`.
  2. `i > n / 2.0` (so sánh biến `i32` với 1 phép chia có hằng số float
     LỒNG BÊN TRONG) — `compare` tính `operand_dtype` chỉ để phát hiện
     `'str'` rồi BỎ QUA, vẫn dùng dtype tổ tiên (`i32`) ép cả 2 vế → hằng
     số `2.0` bị ép `ldc.i4 2.0` — **lỗi cú pháp ILASM thật** (assembly
     fail, không phải runtime crash). Sửa bằng `_contains_float_literal()`
     (duyệt nông qua binop/compare/neg/ternary tìm hằng số float Ở BẤT KỲ
     ĐÂU trong cây con) + `_resolve_compare_operand_dtype()` — CHỈ áp cho
     `compare` (an toàn tuyệt đối vì kết quả so sánh LUÔN LÀ i32 bất kể
     chọn dtype nào cho toán hạng, khác `binop` nơi kết quả còn dùng tiếp
     nên KHÔNG đụng vào để tránh phá vỡ hành vi đang chạy đúng).
- **1 giới hạn ngữ nghĩa THẬT ghi nhận (không sửa, không phải bug)**: chia
  float cho 0 trong CIL/.NET là IEEE754 hợp lệ (trả `Infinity`, KHÔNG ném
  exception) trong khi Python thật ném `ZeroDivisionError` — nên
  `except ZeroDivisionError:` trên PHÉP CHIA FLOAT (khác phép chia i32,
  vẫn ném đúng) không bao giờ bắt được gì. Cùng nhóm với giới hạn `/` i32
  đã biết ở Bước 6 (khác biệt CLR/Python, không né được bằng sửa codegen).
- Kết quả: **23/23 mẫu khớp CPython thật** (4/5 hàm đúng ngay từ AlphaAI,
  1/5 lộ bug thật đã sửa xong).
- Regression: toàn bộ 18 bộ test cũ vẫn PASS sau cả 2 fix.
- **Kết luận cho chiến lược AI-port**: xác nhận đúng dự đoán trong
  [[project-tokenvector-ai-port-strategy]] — AI dịch được TRONG PHẠM VI
  từ vựng đã có, và quan trọng hơn: **chính việc AI dùng từ vựng theo
  cách con người ít nghĩ tới (hằng số float lồng sâu, dict value là số
  trong hàm trả string) lại là cách hiệu quả để tìm bug thật trong
  compiler** — đúng vai trò đã phân công (AlphaAI tạo khối lượng, Claude
  soát + vá lõi).

## ✅ Khoảng trống ngôn ngữ #1 — Method thật trên record (2026-07-28)

**Cú pháp**: `class Point: ... def method(self, k: "f32") -> "f32": ...`
— `self` KHÔNG được có annotation (giống Python thật), tự động bind vào
scope ở arg index 0. `__init__` vẫn bị bỏ qua hoàn toàn lúc biên dịch
(chỉ để file chạy thật dưới CPython); các method KHÁC (không phải
`__init__`) được biên dịch THẬT thành CIL instance method trên chính
struct đó.

- **2 phát hiện kỹ thuật mới xác nhận qua probe** (`il_test/probe_record_method.il`,
  chạy trước khi sửa `il_codegen.py`, kết quả khớp tính tay 7/6/8):
  1. Method KHÔNG mutate field: gọi như bình thường — `ldloca.s`/`ldarga.s`
     (địa chỉ object) trước `call instance`, giống pattern `ToString()`
     đã biết.
  2. Method CÓ mutate field: bên trong thân method, `ldarg.0` (self)
     **ĐÃ LÀ địa chỉ** (kiểu `!T&`, không phải `!T`) do đúng quy ước gọi
     instance method trên value type — dùng thẳng `ldfld`/`stfld` qua nó,
     KHÔNG được `ldarga.s` lại (sẽ tạo "địa chỉ của địa chỉ" sai). Đây là
     điểm khác với tham số record thường (truyền theo giá trị).
- **1 bug thật lộ ra ngay từ test đầu tiên** (không phải AlphaAI, tự viết
  tay `scale()` — method mutate, không `return`): `gen_il_function` chưa
  BAO GIỜ tự sinh `ret` cuối hàm cho hàm/method **void** — trước giờ mọi
  hàm top-level đều có return type nên chưa lộ. CIL void không được "rơi
  tự do" hết thân hàm mà không có `ret` (khác Python ngầm định `return
  None`) → `InvalidProgramException` thật. Sửa: thêm `ret` cuối cùng khi
  `sig.return_type is None` (DSL hiện chưa hỗ trợ `return` trần/không
  giá trị, nên luôn cần bước này cho hàm/method void).
- **Kiến trúc**: tái dùng TOÀN BỘ `gen_il_function` (parse/first-pass/
  codegen đã test kỹ qua 19 bộ test) qua tham số mới `self_type_ann` —
  không viết pipeline riêng cho method. `records` (field) và
  `record_methods` (chữ ký method, cho lookup gọi từ BẤT KỲ đâu — hàm
  top-level hay method khác) là 2 bảng TÁCH RIÊNG (không đổi shape của
  `records` đang dùng ở nhiều nơi — giữ đúng kỷ luật phạm vi).
- Test: `test/sample_record_method.tkv` (`total()` không mutate,
  `scale()` mutate, `combined_with(other: Point)` — method nhận 1 record
  KHÁC làm tham số, gọi method trên cả `self` lẫn tham số) — **7/7 khớp
  CPython thật**.
- Regression: toàn bộ 20 bộ test (19 bộ cũ + `record_method_test.py`
  mới) PASS.
- **Còn thiếu (ngoài phạm vi phiên này)**: kế thừa, đa hình, method tĩnh
  (static method trên record), field/tham số record kiểu container
  (list/dict record) — record method hiện CHỈ nhận/trả vô hướng hoặc
  record khác, giống giới hạn field.

## ✅ Khoảng trống ngôn ngữ #2 — Container lồng nhau: List/Dict chứa record (2026-07-28)

**Phạm vi THẬT**: `List<Point>` (khởi tạo `[]`/`append`/`[i]`/`len`/`for p in lst:`)
và `Dictionary<K, Point>` (`{}`/gán/đọc/`in`/`len`) — GIÁ TRỊ (phần tử
list, value của dict) có thể là 1 record đã khai báo; KHOÁ dict vẫn CHỈ
vô hướng (record làm khoá cần `GetHashCode`/`Equals` đúng, chưa verify —
ngoài phạm vi). **Không làm** `List<List<T>>` (list-lồng-list) trong đợt
này — mảng cố định 2 chiều (`f32[N,M]`) đã phủ nhu cầu ma trận/vector
AI thường gặp hơn; record-trong-container mới là khoảng trống thật.

- **Không cần probe `.il` riêng** — tái dụng ĐÚNG cơ chế `List<T>`/
  `Dictionary<K,V>` đã verify thật cho dtype vô hướng (Bước 4/5), CHỈ đổi
  đối số generic `<T>`/`<K,V>` từ `IL_SCALAR[dtype]` sang `valuetype
  TenRecord` khi phần tử là record — cùng cơ chế .NET generic áp dụng
  ĐỒNG NHẤT cho scalar lẫn value-type tự định nghĩa (ECMA-335 chuẩn,
  không phải suy đoán).
- **Kiến trúc**: hàm mới `il_list_elem_ilstr(dtype, records)` (dtype vô
  hướng → `IL_SCALAR[dtype]`, HOẶC tên record đã khai báo → `valuetype
  TenRecord`) dùng CHUNG cho cả `il_list_type()` VÀ `il_dict_type()`
  (dict tái dùng cho phần VALUE). `records` (bảng field record) được
  luồn thêm qua ~10 điểm gọi nội bộ (đọc/ghi chỉ số, `.append`, `len()`,
  `in`, khởi tạo `[]`/`{}`, `.locals` signature) — KHÔNG đổi shape bảng
  `records` đang dùng, chỉ thêm 1 tham số optional mặc định `None`
  (tương thích ngược 100% với code cũ).
- `_infer_dtype`'s tag `'call'` mở rộng: nhận diện `Point(...)` (khởi
  tạo record) trả về CHÍNH TÊN RECORD làm "dtype" — cần thiết để
  `pts.append(Point(a, b))`/`d[k] = Point(a, b)` tự suy đúng dtype phần
  tử của list/dict (giống cách `declare_scalar` đã làm cho `p = Point(...)`
  ở khoảng trống #1).
- `declare_scalar`'s nhánh suy dtype chung (không chỉ nhánh khởi tạo
  trực tiếp) SỬA để gán `shape='record'` (không phải `None`) khi dtype
  suy được trùng tên 1 record đã khai báo — cần thiết cho `p = pts[i]`/
  `for p in pts:` (macro mở rộng thành gán chỉ số) để `p.field`/
  `p.method()` dùng được sau đó.
- **Cố ý CHƯA làm** (kết hợp 2 tính năng, không phải giới hạn CIL):
  `for k, v in d.items():` trên dict-chứa-record (`il_dict_enumerator_type`/
  `il_kvpair_type` chưa nhận `records`) — sẽ báo `KeyError` thô (chưa
  phải `SyntaxError` rõ ràng) nếu dùng, ghi nhận ở đây thay vì sửa ngay
  (đọc qua `d[k]` sau `k in d`/vòng lặp chỉ số vẫn dùng được bình thường,
  xem `dict_of_points_sum` trong test).
- Test: `test/sample_container_record.tkv` (`sum_of_points_list` —
  List<Point>+`for...in`, `point_at_index` — List<Point>+chỉ số,
  `dict_of_points_sum` — Dictionary<i32,Point>+`in`) — **9/9 khớp
  CPython thật, qua ngay lần chạy đầu**.
- Regression: toàn bộ 21 bộ test (20 bộ cũ + `container_record_test.py`
  mới) PASS.
- **3/3 khoảng trống ngôn ngữ đã lên kế hoạch trước đó đều xong** (method
  thật trên record, container lồng nhau). Còn lại theo kế hoạch cũ:
  import module TokenVector khác (chia dự án nhiều file).

## ✅ Khoảng trống ngôn ngữ #3 — Import module TokenVector khác (2026-07-28)

**Vấn đề THẬT phải né**: `import` chuẩn của Python không dùng được để
tham chiếu 1 file `.tkv` khác — cơ chế import của Python chỉ tìm `.py`,
không biết đuôi `.tkv` (khác biệt với `ast.parse`/`runpy.run_path`, vốn
đọc THẲNG nội dung file bất kể đuôi — `import` là một cơ chế RIÊNG, dựa
trên finder/loader, không phải chỉ đọc file).

**Giải pháp**: PRAGMA riêng của compiler — `__tkv_import__ = "ten_file"`
(hoặc list nhiều tên) ở cấp module, **không** dùng từ khoá `import`. Đây
là 1 phép GÁN CHUỖI hợp lệ 100% dưới CPython thật (không làm gì lúc
runtime) — cùng tinh thần "annotation là chuỗi" đã dùng xuyên suốt dự án
để giữ file `.tkv` luôn là Python thật.

- `_parse_program_ast()` (tách từ `extract_program` cũ) nhận diện
  `ast.Assign` với target `__tkv_import__`, giá trị là 1 chuỗi hoặc list
  chuỗi hằng số.
- `extract_program_file(tkv_path)` MỚI — đọc file thật, đệ quy giải
  quyết `__tkv_import__` (tìm `<tên>.tkv` CÙNG thư mục), gộp
  ham/record/method của file import vào kết quả CHUNG — báo lỗi RÕ RÀNG
  nếu trùng tên hàm/class giữa 2 file (không âm thầm ghi đè). Chống
  import vòng lặp qua tập `_visited` (đường dẫn tuyệt đối đã xử lý — file
  đã gộp thì lần gặp lại (kể cả A↔B) chỉ bị bỏ qua, không đệ quy vô hạn).
  `extract_program(source_text)` (API cũ, chỉ có văn bản không có đường
  dẫn) GIỮ NGUYÊN hành vi cho file KHÔNG import — báo lỗi rõ ràng nếu file
  có `__tkv_import__` mà gọi qua API này (cần đường dẫn thư mục để tìm
  file import, API cũ không có).
- `compile_tkv_cli`/`transpile_file` chuyển sang dùng
  `extract_program_file` (không đổi chữ ký hàm, tương thích ngược hoàn
  toàn với mọi file không dùng import — `transpile_program(source_text)`
  giữ nguyên, chỉ không hỗ trợ import).
- **Bài học từ chính việc viết test** (không phải bug compiler): lúc
  đầu đối chiếu CPython thật bị `NameError` — `runpy.run_path()` trả về
  1 BẢN SAO của namespace, KHÔNG PHẢI `__globals__` thật mà hàm dùng để
  tra cứu biến tự do lúc gọi (`ns is ns['f'].__globals__` là `False`,
  xác minh trực tiếp) — phải cập nhật THẲNG vào `func.__globals__`, không
  phải dict `runpy.run_path` trả về, mới ghép được namespace 2 file
  `.tkv` để đối chiếu.
- Test: `test/sample_import_shapes.tkv` (record `Rect` + hàm `double_it`)
  + `test/sample_import_main.tkv` (`__tkv_import__ = "sample_import_shapes"`,
  dùng cả record lẫn hàm từ file kia) — **7/7 khớp CPython thật, qua
  ngay lần chạy đầu** (lỗi duy nhất gặp phải nằm ở chính test harness,
  không phải compiler).
- Regression: toàn bộ 22 bộ test (21 bộ cũ + `import_test.py` mới) PASS.
- **Giới hạn cố ý**: import CÙNG THƯ MỤC (không hỗ trợ đường dẫn tương
  đối/tuyệt đối phức tạp); gộp THEO VĂN BẢN vào 1 chương trình CIL duy
  nhất (không sinh assembly/module `.NET` riêng cho mỗi file — đơn giản
  hoá có chủ đích, đủ cho mục tiêu "chia code thành nhiều file", không
  cần cơ chế reference-assembly đầy đủ).
- **Cả 4 khoảng trống ngôn ngữ theo kế hoạch phiên trước đều đã xong.**

## ✅ Toán tử/cú pháp nhỏ, tần suất dùng cao (2026-07-28)

Mục #1 kế hoạch "Đề xuất mục tiêu tiếp theo" — rẻ, không cần probe rủi
ro (trừ `raise`/`throw`, xác minh riêng), mở khoá AI-port diện rộng vì
code thật hầu như luôn dùng ít nhất 1 trong 4 cái này.

- **`%`** (chia lấy dư) — thêm vào tokenizer/`parse_term` (cùng mức ưu
  tiên `*`/`/`), CIL `rem`. Test dùng toán hạng dương (tránh khác biệt
  dấu số âm CLR-vs-Python, cùng nhóm giới hạn đã biết với `/` i32 — chưa
  gặp thật, không sửa trước).
- **Gán rút gọn** `+=`/`-=`/`*=`/`/=`/`%=` — macro TEXT-LEVEL (không
  codegen mới): `x += e` → `x = x + (e)`, tương tự cho `obj.field += e`
  và `lst[i] += e` — tái dùng 100% máy gán/attr-assign/idx-assign đã có.
- **`not`** — thêm 1 tầng ưu tiên `parse_not` giữa `and`/`or` (lỏng hơn)
  và so sánh (chặt hơn), đúng thứ tự ưu tiên Python thật (`not a == b`
  nghĩa là `not (a == b)`). Codegen: `ldc.i4.0` + `ceq` (lật 0/1 boolean,
  KHÔNG dùng `not` bitwise của CIL — sẽ lật sai bit).
- **`raise <Loại>("msg")`** — tái dùng `_EXC_TYPE_MAP` đã có cho
  `except`. **Xác minh THẬT bằng probe riêng** (`il_test/probe_raise.il`,
  chưa từng dùng `throw`/`newobj`-exception-với-message trong dự án
  trước đây): `.ctor(string)` gán đúng `Message` (với `System.Exception`),
  và code chết SAU `throw` (không phải branch) KHÔNG bị verifier từ chối
  — khác hẳn bug "br sau ret" đã gặp trước đây, vì `throw` (không kèm
  branch) là 1 dạng kết thúc khối hợp lệ theo ECMA-335. Ghi nhận giới hạn
  đã biết: `ArgumentOutOfRangeException` (ánh xạ của `IndexError`) dùng
  `.ctor(string)` 1 tham số sẽ gán vào `paramName`, KHÔNG PHẢI `Message`
  — quy ước riêng của chính class đó trong .NET, không sửa (documented).
- Cập nhật `_DSL_REFERENCE` (prompt AlphaAI) với cả 4 cú pháp mới —
  hoàn thành mục #2 kế hoạch, AlphaAI có thể dùng ngay ở lần gọi tới.
- Test: `test/sample_operators.tkv` (`mod_test`, `compound_var_test`,
  `counter_test` — `+=` trên field record CẢ trong method lẫn top-level,
  `list_compound_test` — `+=`/`*=` trên chỉ số list, `not_test`,
  `raise_and_catch` — raise trong try, bắt bằng except) — **21/21 khớp
  CPython thật**.
- Regression: toàn bộ 23 bộ test (22 bộ cũ + `operators_test.py` mới) PASS.
- **Việc còn lại theo kế hoạch cũ**: chạy AI-port quy mô lớn hơn (15-20
  hàm thực tế, 1 domain cụ thể) + tổng hợp số liệu % thành công vào bảng
  báo cáo tiến độ cho mục tiêu 1+2 (thay Python nói chung / vượt
  Nuitka-Codon-Mojo).

## ✅ Mục #3 — AI-port quy mô lớn (18 hàm) + 1 bug thật tìm thấy (2026-07-28)

- Viết `test/alphaai_batch_port_18.py` (18 hàm thật, domain: xử lý chuỗi
  + list/dict động + toán học/logic điều kiện — dùng THUẦN từ vựng đã
  xác nhận, chưa dùng record vì AlphaAI chưa hỗ trợ ctx `records`).
- **Groq đụng trần TPD (100.000 token/ngày) giữa chừng** — 8/18 hàm thật
  sự gọi được LLM, 10 hàm còn lại lỗi `429 rate_limit_exceeded` (KHÔNG
  phải lỗi compiler, ghi nhận trung thực, không tính vào tử số/mẫu số
  đánh giá compiler). Trong 8 hàm gọi được: **5/8 biên dịch cú pháp
  thành công** (4/8 ngay lần đầu).
- **3 hàm thất bại → 1 bug thật của compiler + 2 do AI tự sinh sai cú
  pháp (không phải giới hạn ngôn ngữ)**:
  1. `count_digits`: AI viết `s[i] >= '0' and s[i] <= '9'` — DSL chưa hỗ
     trợ so sánh `>=`/`<=` trên string (chỉ có `==`/`!=`, xem giới hạn đã
     biết). KHÔNG sửa (đúng như thiết kế hiện tại).
  2. `reverse_str`: AI viết phép trừ `-` trên string (không tồn tại kể cả
     trong Python thật) — lỗi tự sinh sai của AI, không phải giới hạn DSL.
  3. **`unique_char_count`: `count_dict[s[i]] += 1` bị từ chối với "khong
     dich duoc dong"** — đây LÀ BUG THẬT của compiler, không phải giới
     hạn AI. Root cause: `_INDEXED_ASSIGN_RE` và `_COMPOUND_INDEX_RE`
     dùng `[^\]]+` cho phần chỉ số trong `[...]`, nên KHÔNG khớp được khi
     chỉ số tự nó chứa `]` (chỉ số lồng ngoặc vuông, vd `d[lst[i]]` hay
     `d[s[i]]`) — ký tự `]` đầu tiên gặp phải (từ chỉ số con) bị hiểu
     nhầm là dấu đóng của chỉ số ngoài. **Đã sửa**: đổi `[^\]]+` →
     `.+` (greedy, tự backtrack tìm đúng `]` cuối cùng trước `=`/toán tử
     gán rút gọn — an toàn vì mỗi dòng chỉ có đúng 1 `=`/1 toán tử gộp ở
     cấp cao nhất). Verify: `test/sample_nested_index.tkv` +
     `test/nested_index_test.py` (2 hàm, `d[s[i]] += x` và
     `d[i] = lst[idx_lst[i]]`) — **8/8 khớp CPython thật**. Regression:
     toàn bộ 24 bộ test cũ vẫn PASS.
- **Bảng số liệu tiến độ THẬT** (mục #4 kế hoạch, không phóng đại):
  | Chỉ số | Giá trị thật |
  |---|---|
  | Hàm gọi được LLM (trước khi hết quota) | 8/18 |
  | Biên dịch cú pháp thành công (trong 8 hàm gọi được) | 5/8 (62.5%) |
  | Thành công ngay lần đầu (không cần AI tự sửa) | 4/8 (50%) |
  | Bug compiler thật tìm thấy | 1 (`d[expr_có_]]` — đã sửa) |
  | Lỗi do AI tự sinh sai cú pháp (không phải giới hạn DSL) | 2 |
  | Thời gian trung bình/hàm (khi gọi được) | ~5.8s (bao gồm cả AI Connect
    latency lẫn biên dịch thật qua ilasm.exe) |
  - **Đọc trung thực**: 8/18 KHÔNG phải "tỷ lệ thành công của compiler"
    — 10 hàm chưa từng chạm compiler (hết quota Groq trước khi tới lượt).
    Tỷ lệ đáng tin cậy duy nhất ở đây là 5/8 (trong số hàm THẬT SỰ được
    thử) — chưa đủ mẫu để kết luận diện rộng, cần chạy lại phần còn lại
    (10 hàm) khi quota Groq reset (~20-24h/ngày, giới hạn free tier).
  - File chi tiết từng lần thử: `test/alphaai_batch_port_18_results.json`.
## ✅ Batch 18/18 hoàn tất qua chat thủ công (Gemini) + 2 bug thật nữa (2026-07-28)

Groq TPD vẫn không reset sau ~1h chờ (quota bị chia sẻ với hoạt động nền
khác trong môi trường, không converge). **Quyết định: bỏ Groq hoàn toàn
cho việc này** (chỉ thị người dùng "Không dùng groq nữa"). Chuyển hẳn
sang cách thủ công: dựng 1 prompt gộp (dùng nguyên `_DSL_REFERENCE`) cho
11 hàm còn lại, người dùng tự dán vào chat Gemini, dán kết quả AI trả về
lại — biên dịch THẬT qua ilasm.exe + đối chiếu CPython, giống HỆT nguyên
tắc áp dụng cho AlphaAI ("không tin mù code AI").

- Kết quả LẦN ĐẦU biên dịch 11 hàm Gemini sinh: **lộ thêm 2 bug thật của
  compiler** (không phải lỗi AI):
  1. **Biến vòng lặp `for i in range(n):` chưa từng được đăng ký vào
     `infer_scope`** (scope suy dtype dùng ở first-pass) — `declare_scalar_int`
     chỉ thêm vào `locals_decl`, quên gọi `infer_scope.set(...)`. Biểu
     hiện: `sq = i * i` (dùng thẳng biến vòng lặp trong 1 biểu thức số
     học ngay trong thân for) ném `KeyError: 'i'`. **Đã sửa**: thêm tham
     số `infer_scope` cho `declare_scalar_int`, gọi `.set()`.
  2. **`declare_list`/`declare_dict` quét CẢ CÂY tìm `.append(...)`/
     `d[k]=...` ĐẦU TIÊN để suy dtype phần tử, nhưng có thể chạm tới 1
     biến (vòng lặp HOẶC biến thường) được gán Ở SAU trong cây trước khi
     `walk()` tuần tự kịp đăng ký biến đó** — khi suy dtype thất bại
     (`KeyError` bị nuốt, trả `None`), code fallback NHẦM về `body_dtype`
     thay vì báo lỗi, gây sai NGẦM (không crash). Biểu hiện thật:
     `unique_char_count` — `c = s[i]` (gán trong thân for) rồi `d[c] = 1`
     (dict key) khiến `d` bị suy nhầm `Dictionary<i32,i32>` (lẽ ra phải
     `Dictionary<str,i32>`, vì lúc `declare_dict('d')` chạy, biến `c`
     chưa được `walk()` đăng ký) → **kết quả SAI hoàn toàn nhưng KHÔNG
     báo lỗi** (biên dịch xong, chạy được, ra số sai — loại bug nguy
     hiểm nhất vì im lặng). Kiểm chứng: `unique_char_count("hello world")`
     ra `11` (= độ dài chuỗi) thay vì `8` (số ký tự khác nhau thật). **Đã
     sửa**: mở rộng pre-pass (đổi tên `_pre_register_for_vars` →
     `_pre_register_infer_scope`) để đăng ký TRƯỚC vào `infer_scope` cả
     biến vòng lặp LẪN biến `assign_scalar` thường (đệ quy toàn cây,
     dùng ĐÚNG logic suy dtype của `declare_scalar`) — chạy 1 lần trước
     `walk(stmts)` chính, idempotent (không đụng `locals_decl`/
     `declared_names`, walk() vẫn là nơi đăng ký thật duy nhất).
  3. **Bug thứ 3 (nhỏ)**: biến tên `rem` (Gemini đặt cho `rem = x % 2`)
     va chạm từ khóa ILASM `rem` (chính là mnemonic phép `%`) — cùng
     loại va chạm mà `_IL_RESERVED_WORDS`/`_rename_reserved_identifiers`
     đã thiết kế để tự xử lý (như `add`/`get`/`set`...), chỉ thiếu entry
     này. **Đã sửa**: thêm `'rem'` vào `_IL_RESERVED_WORDS`.
- Test: `test/sample_manual_chat_11.tkv` + `test/manual_chat_11_test.py`
  (11 hàm, ghép nguyên code Gemini KHÔNG sửa tay) — **40/40 khớp CPython
  thật** (sau khi vá cả 3 bug). Regression: toàn bộ 25 bộ test PASS.
- **Kết quả cuối batch 18 hàm** (mục #4, số liệu thật):
  | Chỉ số | Giá trị |
  |---|---|
  | Tổng hàm sinh thành công (cú pháp đúng, khớp CPython) | 16/18 (89%) |
  | — qua AlphaAI/Groq (trước khi hết quota) | 5/18 |
  | — qua chat thủ công (Gemini, dán tay) | 11/18 |
  | Thất bại do GIỚI HẠN NGÔN NGỮ thật (không sửa, đúng thiết kế) | 2/18
    (`count_digits`: so sánh `>=`/`<=` trên string; `reverse_str`: AI tự
    sinh phép `-` trên string, không tồn tại cả trong Python thật) |
  | Bug compiler thật phát hiện + đã vá trong batch này | 3 (2 bug lộ ra
    từ AlphaAI + 3 bug lộ ra từ đợt Gemini, tổng cả phiên: xem danh sách
    trên) |
- **Bài học quy trình quan trọng nhất**: dùng AI-port QUY MÔ để STRESS-TEST
  compiler hiệu quả hơn hẳn so với viết test tay — phát hiện 4 bug thật
  trong 1 batch (kể cả 1 bug SAI NGẦM không crash, loại nguy hiểm nhất).
  Nguồn AI (Groq API hay chat thủ công) không quan trọng bằng việc BẮT
  BUỘC biên dịch+đối chiếu CPython thật cho mọi code AI sinh ra.
- **Quyết định người dùng**: ngừng dùng Groq (`ai_connect.py`/
  `alphaai_codegen.py`) cho việc này — dùng đường chat thủ công (dán
  prompt `_DSL_REFERENCE` + tổng hợp, người dùng tự chạy qua chat AI bất
  kỳ) làm mặc định từ nay.

## ✅ So sánh thứ tự chuỗi `>`/`<`/`>=`/`<=` (2026-07-28)

Đóng đúng lỗ hổng vừa lộ ra từ batch AI-port (`count_digits` thất bại vì
thiếu cái này). Trước đó string chỉ hỗ trợ `==`/`!=`.

- **Probe riêng trước khi sửa** (`il_test/probe_str_compare.il`, lần đầu
  dùng `String.CompareOrdinal` trong dự án): xác nhận `CompareOrdinal(a,b)`
  so sánh theo mã Unicode từng ký tự — khớp ngữ nghĩa Python thật cho
  chuỗi ASCII (`'0' < '9'` → True, `'z' > 'a'` → True).
- Codegen: `call int32 String::CompareOrdinal(string,string)` rồi so
  sánh kết quả (int32) với 0 bằng ĐÚNG toán tử gốc (`cgt`/`clt` cho `>`/
  `<`, tái dùng cơ chế phủ định có sẵn cho `>=`/`<=` — giống hệt cách xử
  lý so sánh số, không code path riêng).
- Test: `test/sample_string_compare.tkv` + `test/string_compare_test.py`
  (4 hàm: đếm chữ số bằng `>=`/`<=`, kiểm tra chữ thường, so sánh 2
  chuỗi `<`/`>=`) — **14/14 khớp CPython thật**. Regression: 25 bộ test
  cũ vẫn PASS (26 sau khi thêm bộ này).
- **Mục #1 kế hoạch hoàn tất.** Tiếp theo: mục #2 (AI-port quy mô lớn,
  domain mới).

## 📊 Mục tiêu #4 — Baseline footprint THẬT lần đầu (2026-07-28)

Kế hoạch mới (chốt sau khi user xác nhận "cả 4 mục tiêu gốc không ngoài
tầm"): đo #4 trước (rẻ, đo ngay được) → mở rộng #3 (nền benchmark) → đo
#2 thật (so Nuitka) → tiếp tục #1 (mở rộng vocab liên tục). Script:
`test/benchmark/benchmark_goal4_footprint.py` (đo thật qua `psutil`, 15 lần chạy
lấy median, KHÔNG suy đoán).

- **A) Overhead khởi động thuần** (`fib_sum_upto`, hàm nhỏ): `.exe` =
  119ms (median), `python -c` = 204.6ms (median) → **.exe nhanh hơn
  ~1.7x**. Chênh lệch này chủ yếu là overhead khởi động interpreter
  CPython, KHÔNG phải tốc độ tính toán (đó là phạm vi mục tiêu #2).
- **B) Suy luận MLP thật** (`self_host_classify`, đã khớp 100% sklearn):
  `.exe` = 97ms vs chạy sklearn thật (`joblib.load` + `numpy` +
  `sklearn` cold import) = **11.639 GIÂY** → **.exe nhanh hơn ~120x**.
  RAM: `.exe` 13.25MB vs sklearn thật 155MB.
  - **Đọc trung thực**: con số 120x chủ yếu do chi phí IMPORT sklearn
    lần đầu (known pain point thật của hệ sinh thái sklearn, không phải
    TokenVector "tính toán nhanh hơn 120 lần"). Đây là số liệu FOOTPRINT
    THỰC TẾ khi triển khai (đúng ý nghĩa mục tiêu #4 "chạy cấu hình
    thấp" — máy yếu không cần cài numpy/sklearn/joblib nữa), KHÔNG phải
    benchmark tốc độ tính toán thuần (việc đó thuộc mục tiêu #2, cần so
    với Nuitka/Codon/Mojo trên CÙNG 1 phép toán, chưa làm).
- **C) Kích thước file**: `.exe` TokenVector 4-5.6 KB (CIL, cần .NET
  Framework có sẵn trên Windows — không đóng gói runtime riêng, khác
  Nuitka đóng gói cả Python runtime). So sánh: `site-packages/sklearn`
  40.4MB + `numpy` 31.3MB + `joblib` 1.8MB = **~73.5MB** phụ thuộc cần
  cài để chạy tương đương bằng Python thật.
- **Giới hạn phép đo (ghi rõ, không giấu)**: mới đo trên Windows/.NET
  Framework 4.8 tại chỗ, chưa đo trên máy cấu hình thấp thật (N5030
  3.7GB RAM của owner) hay so sánh với 1 file `.exe` build bởi Nuitka
  (việc đó là mục tiêu #2, bước tiếp theo). Chưa tối ưu gì (baseline
  thô), có thể còn cải thiện thêm.

## ✅ Mục tiêu #3 — Phép toán mảng TỔNG QUÁT + 1 bug thật nữa (2026-07-28)

**Phát hiện quan trọng**: phép toán mảng tổng quát (`c[i] = a[i] + b[i]`,
kích thước RUNTIME qua `list`, không chỉ 3 macro cố định `add`/`sub`/
`mul`/`scale`/`matvec`) **ĐÃ hoạt động từ trước** — không cần tính năng
compiler mới, chỉ cần viết đúng vòng lặp bằng cú pháp `list` đã có sẵn
(macro `add(a,b)` chỉ là ĐƯỜNG TẮT cú pháp cho đúng pattern này trên
mảng CỐ ĐỊNH). Lưu ý: `np.zeros(N,...)` chỉ nhận N là HẰNG SỐ biên dịch
(thiết kế đã biết từ trước, không phải bug) — mảng kích thước runtime
PHẢI dùng `list`.

- Trong lúc verify lộ ra **1 bug thật nữa**: `a.append(i * 1.0)` (biến
  vòng lặp `i` kiểu i32 nhân với hằng số float `1.0`) bị ilasm từ chối
  (`ldc.i4 1.0`) — **CÙNG GỐC** với 2 bug đã vá trước đó trong phiên này
  (hằng số float lồng sâu trong biểu thức bị `_infer_dtype` bỏ sót do
  short-circuit trên toán hạng khác), nhưng lần này ở
  `_find_first_append_dtype` (suy dtype phần tử list) thay vì
  `compare`/dict. **Đã sửa**: áp dụng đúng pattern `_contains_float_literal`
  đã có sẵn cho cả `_find_first_append_dtype` VÀ `_find_first_dict_assign_dtypes`
  (key + value dtype) — nhất quán cho toàn bộ nhóm hàm suy dtype phần
  tử container.
- Test: `test/sample_general_array.tkv` + `test/general_array_test.py`
  (cộng tung phần tử, nhân từng phần tử, dot product — đều trên list
  runtime-size) — **9/9 khớp CPython thật**. Regression: 26 bộ test cũ
  PASS.
- **Đọc trung thực cho mục tiêu #3**: vocab đủ cho phép toán mảng 1D
  TỔNG QUÁT (không giới hạn 3 macro), NHƯNG matrix-matrix multiply
  (matmul tổng quát, khác `matvec` hiện có = ma trận×vector) và mảng 2D
  runtime-size (`List<List<T>>`) VẪN CHƯA có — ghi nhận là giới hạn còn
  lại, không phải đã "xong" mục tiêu #3.
- Tiếp theo: mục #2 (benchmark thật so Nuitka, dùng chính vocab mảng
  vừa xác nhận).

## ✅ Mục tiêu #2 — Benchmark thật đầu tiên so Nuitka (2026-07-28)

Máy chỉ 3.65GB RAM — build Nuitka `--onefile` LẦN ĐẦU **crash thật do
hết RAM** (bundling numpy vào 1 file, linking 123 file cùng lúc, RAM
tụt còn 0.18GB/95.2% dùng trước khi lỗi). **Chia nhỏ theo đúng nguyên
tắc dự án** (`feedback-fragment-large-builds`): bỏ numpy (viết lại
bằng list Python thuần — đúng ngữ nghĩa Nuitka thật, vì mục tiêu Nuitka
là compile Python thường KHÔNG cần type hint), tách dot-product và
matmul thành 2 file `.py` riêng, build `--standalone` (bỏ bước nén
onefile, nhẹ hơn) thay vì `--onefile`. Cả 2 build THÀNH CÔNG (RAM ổn
định 75-85%).

**So sánh THẬT** (cùng thuật toán vòng lặp lồng thuần, KHÔNG vector hoá,
IL lấy từ benchmark trước đó trong `AetherTypedDSL/benchmark_results.md`
— IL chính là `il_codegen.py`, công nghệ nền của TokenVector):

| Building block | TokenVector (IL) | Nuitka (`--standalone`) | Tỉ lệ |
|---|---|---|---|
| dot-product (SEQ=128), ms/call | **0.00028** | 0.0084 | **IL nhanh hơn ~30x** |
| matmul (D=64), ms/call | **1.2589** | 36.5131 | **IL nhanh hơn ~29x** |
| Kích thước phân phối | 4-5.6 KB (.exe, cần .NET Framework có sẵn) | 12 MB/workload (`--standalone`, tự đóng gói runtime CPython) | |

- **Đọc trung thực bắt buộc** (không tuyên bố "vượt Nuitka" chung
  chung):
  1. So sánh KHÔNG cân bằng về công sức lập trình viên: TokenVector cần
     code TYPED (kiểu tường minh) viết từ đầu; Nuitka compile Python
     THƯỜNG (không cần gõ lại kiểu) — đây chính là lợi thế bán hàng cốt
     lõi của Nuitka (tương thích Python 100%), TokenVector KHÔNG có.
  2. Kích thước: TokenVector .exe nhỏ hơn nhiều NHƯNG dựa vào .NET
     Framework có sẵn trên Windows; Nuitka `--standalone` tự đóng gói
     toàn bộ runtime CPython nên file to hơn nhưng KHÔNG phụ thuộc gì
     cài sẵn — 2 mô hình triển khai khác nhau, không so 1-1 hoàn toàn
     công bằng.
  3. Chưa benchmark được Codon/Mojo (không cài được trong môi trường
     này — Mojo cần SDK Modular không có sẵn offline, Codon chưa thử).
  4. Đây là 1 workload duy nhất (vòng lặp số học lồng nhau, không dùng
     thư viện ngoài) — KHÔNG đại diện cho mọi loại code Python.
- **Kết luận CÓ CĂN CỨ (không phóng đại)**: trên ĐÚNG loại workload
  TokenVector nhắm tới (mục tiêu #3 — vòng lặp số học/ma trận nhỏ gọn),
  IL backend nhanh hơn Nuitka thật ~29-30x khi đo cùng máy cùng lúc.
  Đây là bằng chứng đầu tiên có số liệu cho mục tiêu #2, giới hạn ở
  ĐÚNG 1 loại workload, chưa phải "vượt Nuitka nói chung".
- File: `AetherTypedDSL/nuitka_bench/dot_only.py`,
  `AetherTypedDSL/nuitka_bench/matmul_only.py` (build ra `.dist/` chứa
  `.exe` — không commit binary, chỉ commit source).
- Codon/Mojo: chưa làm được, ghi nhận rõ ràng là việc còn thiếu, không
  bỏ qua âm thầm.

## ✅ Mục tiêu #1 — Domain toán học/số học, 12 hàm qua chat thủ công (2026-07-28)

`test/sample_manual_chat_math12.tkv` + `test/manual_chat_math12_test.py`
(12 hàm: `is_prime`, `count_primes_upto`, `gcd_euclid`, `lcm_via_gcd`,
`is_perfect_square`, `sum_of_digits`, `reverse_number`,
`is_palindrome_number`, `power_int`, `fibonacci_nth`, `collatz_steps`,
`digital_root` — Gemini sinh qua chat thủ công, dán nguyên không sửa).

- Lần đối chiếu đầu: **35/47 khớp** — 12 case lệch, NHƯNG **không phải
  bug mới**, mà là biểu hiện của giới hạn ĐÃ BIẾT trước đó ("`/` trên
  i32 làm tròn về 0, khác `/` luôn chia nổi của Python thật"): 5 hàm
  dùng `temp = temp / 10` để tách chữ số (`sum_of_digits`,
  `reverse_number`, `is_palindrome_number`, `digital_root`,
  `lcm_via_gcd`) — DSL biên dịch ĐÚNG Ý ĐỊNH thuật toán (chia nguyên),
  nhưng chạy CHÍNH văn bản đó bằng CPython thật thì `/` là chia nổi,
  khiến vòng lặp KHÔNG BAO GIỜ về đúng 0 (dội số thập phân, có ca ra cả
  `inf`) — phân kỳ khỏi ý định gốc.
  - **Kiểm chứng lại bằng `//`** (chia nguyên thật của Python, đúng ý
    định thuật toán): **CẢ 12 case đều khớp CHÍNH XÁC** kết quả `.exe`
    (`lcm(4,6)=12`, `sum_of_digits(12345)=15`, `reverse_number(123)=321`,
    `is_palindrome_number(121)=1`, `digital_root(9875)=2`, ...) — chứng
    minh `.exe` TokenVector tính ĐÚNG thuật toán, chỉ khác cách CPython
    literal diễn giải CÙNG 1 ký tự `/`.
  - **Không sửa gì** (đúng nguyên tắc đã áp dụng nhất quán từ Bước 6):
    giới hạn này đã biết, đã ghi nhận từ trước, KHÔNG phải bug mới của
    session này.
- **Kết quả cuối domain toán học: 12/12 hàm ĐÚNG THẬT** (chỉ khác biệt
  ở phương pháp đối chiếu, không phải sai sót compiler). Regression: 26
  bộ test cũ PASS.
- **Tổng vocab AI-port qua các domain đã thử** (mục tiêu #1, số liệu
  cộng dồn từ đầu phiên): string/list/dict (18 hàm, 89%) + toán học (12
  hàm, 100% đúng thuật toán) = 30 hàm thực tế đã stress-test, tìm+vá 7
  bug compiler thật trong suốt quá trình.

## 🗺️ Nghiên cứu lộ trình "thay Python" — 3 tầng, quyết định phạm vi (2026-07-28)

Owner đặt câu hỏi thẳng: "các mục tiêu tiếp theo có khẳng định TokenVector
thay được Python?" — trả lời trung thực: KHÔNG, kể cả sau khi làm xong
mọi thứ ở Tầng 1 dưới đây (thiếu closures/OOP đầy đủ/kiểu động/toàn bộ
thư viện chuẩn). Owner phản hồi: ưu tiên làm phần khả thi trước, phần
khó thì NGHIÊN CỨU chứ không từ bỏ mục tiêu. Phân loại 3 tầng:

- **Tầng 1 (khả thi thật, không rào cản kiến trúc — làm trước)**: list/
  dict comprehension, set/frozenset, tuple >2 phần tử, f-string,
  container lồng nhau, generator/yield giới hạn, closures/hàm
  first-class, decorator thật (sau closures), `with`, class kế thừa.
- **Tầng 2 (đánh đổi kiến trúc thật, không né được)**: kiểu động (duck
  typing)/`exec`/`eval` đòi hỏi bỏ kiểu tĩnh-biết-lúc-compile — đánh đổi
  TRỰC TIẾP với lợi thế tốc độ đã chứng minh (nhanh hơn Nuitka ~29-30x,
  mục tiêu #2/#4). Cần quyết định chiến lược: giữ kiểu tĩnh vĩnh viễn
  (giữ tốc độ) hay thêm "any" đóng hộp (mở kiểu động, chấp nhận chậm
  hơn cho code dùng "any"). **CHƯA QUYẾT ĐỊNH** — owner yêu cầu tiếp tục
  nghiên cứu hướng "opt-in dynamic" (chỉ biến khai báo dynamic mới chịu
  chi phí, code tĩnh hiện có giữ nguyên tốc độ) thay vì từ bỏ.
- **Tầng 3 (quy mô, không phải độ khó)**: toàn bộ thư viện chuẩn Python
  + hệ sinh thái pip — không có "vạch đích", chỉ có % phủ tăng dần theo
  từng hàm được thêm thủ công.

## ✅ Tầng 1 — List/dict comprehension (2026-07-28)

- **Cải tiến nền tảng cho phép comprehension hoạt động**: `_expand_macros`
  trước đây chỉ chạy 1 VÒNG duy nhất qua các dòng — không đủ khi
  comprehension sinh ra văn bản `for x in lst:` (chính nó LÀ 1 macro
  khác, `_FOR_IN_LIST_RE`, cần vòng mở rộng THỨ HAI). Đổi thành lặp ĐẾN
  ĐIỂM CỐ ĐỊNH (tối đa 10 vòng, dừng ngay khi không còn thay đổi) —
  `_expand_macros_once` giữ nguyên logic cũ, `_expand_macros` (tên cũ)
  giờ là hàm bao gọi lặp. Verify: regression 7 bộ test cốt lõi PASS
  TRƯỚC khi thêm comprehension (xác nhận refactor an toàn, tách riêng
  rủi ro).
- Parser dùng tìm từ khoá `for`/`in`/`if` ĐẦU TIÊN (không dùng 1 regex
  khối, học từ bug `d[lst[i]]` trước đó — biểu thức bên trong `[...]`
  có thể tự chứa `]` lồng nhau).
- Hỗ trợ: `[expr for x in range(N)]`, `[expr for x in range(N) if cond]`,
  `[expr for x in lst]` (list biến thường), `{kexpr: vexpr for x in
  range(N) (if cond)}`, `{kexpr: vexpr for k, v in d.items()}` — TẤT CẢ
  chỉ là đường tắt cú pháp cho for-loop+append/idx_assign ĐÃ CÓ SẴN,
  KHÔNG sinh codegen mới.
- Test: `test/sample_comprehension.tkv` + `test/comprehension_test.py`
  (5 hàm) — **16/16 khớp CPython thật**.
- **Sửa 1 test cũ bị nhiễu** (không phải bug compiler): `manual_chat_math12_test.py`
  báo "SAI LỆCH" mỗi lần chạy regression vì so trực tiếp với CPython chạy
  literal `/` (giới hạn đã biết, xem mục trước) — sửa test dùng hàm tham
  chiếu viết tay bằng `//` cho 5 hàm bị ảnh hưởng, đúng tiền lệ
  `alphaai_ported_test.py` đã áp dụng cho ca chia-cho-0-số-thực.
- Regression: toàn bộ 28 bộ test PASS (27 cũ + comprehension mới).
- **Giới hạn chưa làm**: comprehension với 2 biến vòng lặp cho LIST
  (`[x for k, v in d.items()]`) chưa hỗ trợ (chỉ dict comprehension mới
  chấp nhận 2 biến); comprehension lồng nhau (2 tầng `for`) chưa test.

## ✅ Tầng 1 — Set/frozenset (2026-07-28)

- **Probe riêng trước khi sửa** (`il_test/probe_hashset.il`): phát hiện
  ngay `HashSet<T>` nằm ở assembly **`System.Core`**, KHÔNG PHẢI
  `mscorlib` như `List<T>`/`Dictionary<K,V>` — khác biệt thật, gây lỗi
  `TypeLoadException` ở lần thử đầu (đã sửa: thêm `.assembly extern
  System.Core` với đúng `publickeytoken`/`.ver` vào header `.il` sinh
  ra, trong `tkv_compile.py`). Xác nhận `Add(T)`/`Contains(T)` trả về
  `bool` (khác `List<T>.Add` trả `void`) và `get_Count()`.
- **2 va chạm từ khóa ILASM thật, phát hiện ngay khi test đầu tiên**:
  cú pháp mới `set()` (khởi tạo rỗng) và `.add(x)` (thêm phần tử) đều
  trùng đúng từ khóa `_IL_RESERVED_WORDS` đã có (`set`, `add` — cùng
  nhóm với `get`/`remove` đã biết từ trước) — `_rename_reserved_identifiers`
  đổi mù quáng `set()` → `set_()` và `.add(` → `.add_(`, phá cú pháp
  ngay lập tức. **Đã sửa**: bảo vệ đúng 2 cụm từ này bằng kỹ thuật thay
  placeholder tạm trước khi đổi tên, khôi phục sau — CHỈ áp dụng cho
  chính xác `set()` (ngoặc rỗng) và `.add(` (gọi method), KHÔNG ảnh
  hưởng bảo vệ hiện có cho biến/method người dùng trùng tên khác (vẫn
  đổi tên bình thường, đúng hành vi cũ — chấp nhận giới hạn đã biết từ
  trước: record tự định nghĩa method tên `add` vẫn nên tránh, xem
  `operators_test.py` đã đổi `add`→`increase`).
- Test: `test/sample_set.tkv` + `test/set_test.py` (`count_unique_mod`,
  `contains_test`, `set_comp_evens` — cả `add`/`in`/`len`/set
  comprehension) — **9/9 khớp CPython thật**. Regression: 28 bộ test cũ
  PASS (29 sau khi thêm bộ này).
- **Việc còn thiếu**: `frozenset` (bất biến) chưa làm riêng — hiện tại
  `set` động đã đủ dùng cho hầu hết trường hợp thực tế; phép toán tập
  hợp (`union`/`intersection`/`difference`) chưa hỗ trợ.

## ✅ Tầng 1 — Tuple >2 phần tử (2026-07-28)

Tổng quát hoá `ValueTuple\`2` (trước đây CỐ Ý chỉ hỗ trợ đúng 2 phần tử)
thành `ValueTuple\`2..\`7`.

- **Probe riêng trước khi sửa** (`il_test/probe_tuple3.il`, `ValueTuple\`3`):
  xác nhận pattern `Item1..ItemN` GIỐNG HỆT nhau cho mọi arity, không có
  gì khác biệt giữa N=2 và N=3 ngoài số tham số generic — tổng quát hoá
  an toàn.
- Sửa đồng bộ 5 chỗ: `il_tuple2_type`→`il_tupleN_type(dtypes)` (dùng
  `ValueTuple\`{n}<...>`, chặn N ngoài [2,7]); parser kiểu tuple
  (`typed_dsl_parser.py`, bỏ check `!= 2`); regex `_TUPLE_ASSIGN_RE`
  (dùng `(?:\s*,\s*\w+)+` thay vì đúng 2 nhóm cố định); parsing `return`
  (chấp nhận 2-7 giá trị thay vì đúng 2); first-pass + codegen thật cho
  cả `return_tuple` và `tuple_assign` (vòng lặp qua N phần tử thay vì
  `d1, d2`/`t1, t2` viết tay).
- Test: `test/sample_tuple3.tkv` + `test/tuple3_test.py` (`divmod3` trả
  3 giá trị, unpack, gán song song có hoán đổi vòng `x,y,z=z,x,y`) —
  **6/6 khớp CPython thật** (dùng `//` làm tham chiếu cho phần chia
  nguyên, cùng giới hạn `/` đã biết). Regression: `tuple_test.py` cũ
  (2-tuple) vẫn PASS — xác nhận không hồi quy. Toàn bộ 30 bộ test PASS.

## 🔧 Refactor: chia `il_codegen.py` theo tính năng (bắt đầu 2026-07-28)

Theo yêu cầu owner (tiêu chí: exe nhẹ — không ảnh hưởng, đã tối ưu sẵn
qua .NET lazy-load; dễ gọi/test/sửa bug/update — thắng rõ): chia
`il_codegen.py` (2973 dòng, 46 hàm) thành nhiều file theo **tính
năng/kiểu dữ liệu** (list.py, dict.py, set.py, tuple.py...), không phải
theo nhóm quan tâm chung chung.

- **Phase 1 (xong, `5a825fb`)**: tách các hàm kiểu-IL thuần (`il_list_type`,
  `il_dict_type`, `il_set_type`, `il_tupleN_type`, `il_array_rank_type`)
  ra `il_core.py` (kernel dùng chung: `IL_SCALAR`, opcode, đổi tên từ
  khóa reserved) + `il_features/{list,dict,set,tuple}_type.py`.
  `il_codegen.py` import lại, giữ nguyên 100% tên hàm/hằng số cũ (không
  đổi API bên ngoài) — rủi ro thấp vì đây là hàm thuần, không đụng
  `_compile_expr`/`_codegen_stmts`. Verify: 30/30 test PASS.
- **Phase 2 = Phase 0 của plan chi tiết (XONG, `e40b7c7`→`39bc4c1`, 6 commit)**:
  plan chi tiết đầy đủ được duyệt tại `C:\Users\Nguyen Hung\.claude\plans\serene-beaming-falcon.md`
  (2 agent Explore khảo sát toàn bộ if/elif + 1 agent Plan thiết kế kiến
  trúc, đối chiếu line-number khớp 100% với code thật). Đã chuyển CẢ 5
  hàm khổng lồ sang dispatch-table (CHƯA di dời file nào — Phase 3/Phase
  1-của-plan sẽ làm việc đó):
  - `il_dispatch.py` (registry rỗng ban đầu): `LINE_PARSERS`/
    `ASSIGN_RHS_PARSERS`/`MACRO_EXPANDERS` (list có thứ tự) +
    `EXPR_CODEGEN`/`STMT_CODEGEN`/`FIRST_PASS_WALK`/`FIRST_PASS_PRESCAN`
    (dict không thứ tự).
  - `_compile_expr` (15 tag) → `EXPR_CODEGEN` dict, mỗi tag 1 hàm `_expr_XXX`.
  - `_codegen_stmts` (23 kind) → `STMT_CODEGEN` dict, mỗi kind 1 hàm
    `_stmt_XXX` (nhận thêm `codegen_stmts_fn` để tự đệ quy, tránh
    circular import khi tách file sau này). GIỮ NGUYÊN lỗ hổng có sẵn:
    không raise khi kind lạ (`.get()` + `if fn:`).
  - `_parse_block` (17 nhánh + cascade assign 13a-13f) → `LINE_PARSERS`
    (CÓ thứ tự — vd `list_append`/`set_add` phải thử trước
    `method_call_stmt`) + `ASSIGN_RHS_PARSERS` lồng trong 1 entry
    `'assign'` duy nhất.
  - `_expand_macros_once` (13 macro) → `MACRO_EXPANDERS` (có thứ tự).
    Đổi từ 1 counter DÙNG CHUNG sang 1 counter RIÊNG mỗi loại macro (mỗi
    macro có tiền tố tên biến tạm khác nhau nên vẫn KHÔNG BAO GIỜ trùng
    trong 1 thân hàm — chỉ số thứ tự cụ thể đổi, không ảnh hưởng test vì
    tên biến tạm không bao giờ bị so sánh).
  - `_first_pass_collect_locals`'s `walk()`/`_pre_register_infer_scope()`
    (21+6 kind) → `FIRST_PASS_WALK`/`FIRST_PASS_PRESCAN` dict. Handler
    nhận 1 dict `ctx` gộp (không theo đúng chữ ký từng-tham-số-riêng của
    plan — quá nhiều tham số, đổi sang ctx dict cho gọn, không đổi hành
    vi). `declare_scalar`/`declare_array`/`declare_list`/`declare_set`/
    `declare_dict`/`declare_named`/`collect_ternary_temps` VẪN là closure
    định nghĩa NGAY TRONG `_first_pass_collect_locals` (đúng cam kết —
    không tách được nếu không tái cấu trúc lớn hơn). `ternary` tag's
    `id(node)`-keyed lookup KHÔNG bị đụng tới.
  - Full 31 test PASS sau MỖI bước (6 bước, 6 commit riêng).
- **Phase 3 = Phase 1 của plan chi tiết (ĐANG LÀM)**: di dời từng tính
  năng ra file riêng theo đúng thứ tự đã duyệt trong plan (10 bước:
  set+list ghép chung → dict → tuple → comprehension → string →
  operators (gộp 7 macro trước) → file_io → record → control_flow cuối
  cùng). Verify regression sau MỖI bước, commit riêng từng bước.
  - **Bước chuẩn bị (`907ef1f`)**: chuyển hẳn bộ dịch biểu thức nhỏ
    (`_ExprParser`/`parse_expr`/`parse_expr_list`, thuần túy không phụ
    thuộc `_Scope`/CIL) từ `il_codegen.py` sang `il_core.py` — cần thiết
    vì MỌI file `il_features/*.py` sắp tới đều cần `parse_expr` để dịch
    cú pháp riêng của nó (vd `lst.append(...)`), mà `il_features/*.py`
    tuyệt đối không được import `il_codegen.py` (circular import). Đây
    là tiền đề bắt buộc, không nằm trong 10 bước gốc của plan.
  - **Bước 1: set+list (`7c1c0e1`, XONG)**: di dời toàn bộ logic parse/
    codegen/first-pass của list → `il_features/list_type.py`, của set →
    `il_features/set_type.py` (set gọi lại `find_first_append_dtype`
    của list_type.py, đúng như plan mô tả "dùng chung"). **Sai lệch có
    chủ đích so với chữ ký hàm trong văn bản plan**: các hàm core mà
    handler đã-di-dời cần gọi lại (`_compile_expr`/`_load_var_ref`/
    `_store_var`/`_load_var_addr`/`_widen_if_needed`, và ở first-pass:
    `_infer_dtype`/`_contains_float_literal`/`_INT_DTYPES`/`TypeAnn`)
    được "tiêm" (dependency injection) qua chính dict `ctx` đã có sẵn
    xuyên suốt `_codegen_stmts`/`_compile_expr`, KHÔNG liệt kê riêng
    từng tham số như văn bản plan mô tả — vì plan không giải quyết rõ
    vấn đề "feature file cần `parse_expr`/`_compile_expr` nhưng không
    được import `il_codegen.py`". Cách tiêm qua `ctx` giữ đúng tinh
    thần "không circular import" của plan mà không cần đổi mọi chữ ký
    hàm hiện có. Full 31 test: 30/30 áp dụng được PASS
    (`alphaai_codegen_test` bị chặn bởi rate-limit Groq bên ngoài, không
    liên quan tới thay đổi).
  - **Bước 2: dict (`5ae6172`, XONG)**: di dời toàn bộ logic parse/
    codegen/first-pass của dict (kể cả `for k, v in d.items():` — biến
    thể for-loop nhưng cú pháp riêng của dict, đúng như plan) sang
    `il_features/dict_type.py`. walk_ctx thêm `infer_literal_dtype`
    (cần cho `find_first_dict_assign_dtypes`). **Khoảng hở phạm vi đã
    biết**: `_compile_index_store`'s dict branch (phần GHI của `d[k]=v`,
    dùng bởi `idx_assign`) vẫn ở core — chỉ phần ĐỌC (`compile_index_dict`,
    tag `index`) và `compile_in_dict` đã di dời. Không ảnh hưởng đúng
    đắn, chỉ là chưa tập trung 100% logic dict vào 1 file — để lại cho
    lượt sau. Full 31 test: 30/30 áp dụng được PASS.
  - **Bước 3: tuple (`8037af5`, XONG)**: di dời `tuple_assign`/`return_tuple`
    sang `il_features/tuple_type.py`. **Ngoại lệ ĐÚNG NHƯ PLAN dự đoán**:
    line-parser của `return_tuple` vẫn ở core's `_lp_return` (dùng
    CHUNG 1 regex/hàm với `return` thường — chỉ phân biệt được SAU khi
    parse xong số lượng biểu thức, không tách được thành 2 line-parser
    độc lập mà không parse 2 lần) — sẽ chuyển khi `control_flow.py` ra
    đời ở bước 10. Full 31 test: 30/30 áp dụng được PASS.
  - **Bước 4: comprehension (`70c883e`, XONG)**: di dời macro list/dict/
    set-comprehension sang `il_features/comprehension.py` — thuần túy
    text-macro, KHÔNG cần tiêm `ctx` (không phụ thuộc `_Scope`/CIL). Full
    31 test: 30/30 áp dụng được PASS.
  - **Bước 5: string (`f576cec`, XONG)**: di dời sang
    `il_features/string_feature.py`. Tag `str_lit` đăng ký TRỰC TIẾP (tag
    độc lập). 5 nhánh còn lại (`index`/`len()`/`str()`/`binop`/`compare`)
    nằm trong các tag DÙNG CHUNG nhiều kiểu — theo đúng thiết kế của
    plan, phần "cây quyết định theo dtype/shape" ở lại core, chỉ THÂN của
    nhánh string di dời. ctx thêm `int_dtypes`/`float_dtypes`/
    `compare_opcode`/`compare_negated`. Full 31 test: 30/30 áp dụng được
    PASS.
  - **Bước 6: operators (`f42f6b2`, XONG)**: di dời `binop`/`boolop`/
    `neg`/`not`/`compare` (TOÀN BỘ tag, khác list/dict — vì đây là tag
    SỐ HỌC cơ bản, string là trường hợp đặc biệt được ủy quyền RA
    string_feature.py, không phải ngược lại) + 9 macro dense/normalize/
    argmax/add/sub/mul/scale/matvec/apply + compound-assign trên biến/
    chỉ-số sang `il_features/operators.py`. **Bỏ qua có chủ đích** bước
    gộp-7-macro-thành-1-dispatch mà plan đề xuất làm trước khi tách file
    — đó là cải tiến DRY độc lập, không cần thiết cho tính đúng đắn của
    việc tách file. Full 31 test: 30/30 áp dụng được PASS.
  - **Bước 7: file_io (`7524326`, XONG)**: `call_stmt` kind di dời TRỌN
    VẸN (chỉ gồm write_file/append_file) sang `il_features/file_io.py`;
    `read_file`/`file_exists` trong tag `call` ủy quyền ra tương tự
    `str()` của string_feature.py. Full 31 test: 30/30 áp dụng được PASS.
  - **Bước 8: record (`68fdda1`, XONG)**: `attr_assign` (line-parser/
    stmt-codegen/first-pass), macro `compound_attr` (`obj.field += expr`),
    tag `attr`/`method_call` di dời sang `il_features/record_feature.py`.
    `declare_scalar` (core) giữ nguyên closure nhưng gọi ra
    `is_record_ctor_rhs()` do record_feature.py sở hữu để phát hiện
    `p = Point(1.0, 2.0)` — tri thức "thế nào là record ctor" tách ra,
    state `locals_decl`/`declared_names` dùng chung ở lại core. Thêm
    `il_type_str` vào `ctx` (hàm public API, method_call cần để sinh chữ
    ký CIL, không import trực tiếp được vì tránh circular import). Full
    31 test: 31/31 PASS (lần này `alphaai_codegen_test` cũng PASS, hết
    bị Groq rate-limit).
  - **Bước 9 (cuối cùng, `c7cdbf4`, XONG)**: control_flow — rủi ro cao
    nhất, đã hoàn tất. Di dời if/for/while/try/break/continue/return/raise
    (line-parser/stmt-codegen/first-pass đầy đủ) + macro `for_in_list` +
    helper `_contains_return`/`_contains_break_continue`/
    `_stmts_end_in_return`/`gen_il_guard_lines` + `_EXC_TYPE_MAP` sang
    `il_features/control_flow.py`. `return`/line-parser của nó (dùng
    chung với `return_tuple`) chuyển đúng đích như plan đã ghi chú từ
    bước 4. `declare_scalar_int` (chỉ `for` dùng) đi theo luôn.
    `gen_il_function` gọi `gen_il_guard_lines` qua import thẳng (hàm
    thuần, không cần ctx-injection). Full 31 test: 31/31 PASS.

  **PHASE 1 HOÀN TẤT (9/9 bước)**: set+list → dict → tuple →
  comprehension → string → operators → file_io → record → control_flow.
  `il_codegen.py` co từ 2855 dòng xuống còn 1578 dòng — chỉ còn
  orchestrator (5 vòng dispatch mỏng) + public API
  (`gen_il_function`/`gen_il_program`/`gen_record_types`/`gen_il_method`/
  `il_type_str`) + phần cố ý KHÔNG tách theo plan (dispatch ladder của
  `index`/`in`/`call`, `_compile_index_store`, `ternary` (object-identity,
  không được tách), `_Scope`/tokenizer, `declare_scalar`/`declare_array`/
  `declare_named` dùng chung mọi feature). API công khai không đổi tên/vị
  trí/tham số/kiểu trả về ở bất kỳ bước nào trong toàn bộ refactor.

## Nghiên cứu Qwen3 "thay Python" (2026-07-28)

Chủ dự án hỏi "mục tiêu thay Python đạt chưa?" — trả lời thẳng: CHƯA, đây
là typed subset (numeric/list/dict/string/record), không phải general
Python replacement. ROADMAP.md tự loại decorator/generator/async/exec-eval/
kế thừa khỏi phạm vi. Chạy nghiên cứu thật qua Groq (`qwen/qwen3.6-27b`,
`reasoning_effort='none'` để tắt `<think>` block gây cắt cụt câu trả lời —
bug đã biết, xem `feedback-qwen3-layered-research-agent.md`) — prompt +
câu trả lời đầy đủ lưu tại `TokenVector/qwen3_research_prompt_python_parity.md`
+ `qwen3_research_reply_python_parity.md`. Kết luận đã áp vào ROADMAP.md +
task list:
- **exec/eval + kiểu động tuỳ ý**: bức tường kiến trúc THẬT, loại bỏ vĩnh
  viễn (không phải "chưa tới lượt").
- **async/await**: chi phí/lợi ích quá kém, cũng loại vĩnh viễn.
- **Decorator**: có đường tắt rẻ (special-case built-in qua AST transform,
  KHÔNG cần chờ closures) — nâng ưu tiên lên trước closures nếu muốn quick win.
- **Closures**: "display class" pattern (giống C#), tiền đề cho decorator
  tổng quát + lambda.
- **Generator/yield**: sinh class ẩn implement `IEnumerator<T>`, khả thi
  nhưng khó hơn try/except đáng kể — defer sau closures.
- **Kế thừa/đa hình**: bắt buộc đổi record struct→class (value→reference
  type), phá mô hình 1-dtype-cố-định — thay đổi kiến trúc lớn nhất, rủi ro
  hiệu năng cao nhất trong các tính năng đang xét.

---

## 📊 Đo lại benchmark — mốc hoàn thành Giai đoạn 0.2 (2026-08-03)

Ngoại lệ có chủ ý với dòng "dừng cập nhật 2026-07-28" ở đầu file: chính
sách benchmark (`test/benchmark/README.md`) yêu cầu ghi số đo + ngày vào
đây để so được theo thời gian, nên các lần đo sau nối tiếp ở mục này.

Mốc: xong nhóm 8 = trọn **Giai đoạn 0.2** (15+9 builtin/method gọi được ở
mọi vị trí biểu thức). Trước khi đo: `test/verify/` chạy **79/79 PASS, 0
FAIL** (2 file `alphaai_*` bỏ qua — cần mạng/Groq). Lệnh:
`python test/benchmark/benchmark_goal4_footprint.py`.

| Hạng mục | 2026-07-28 | 2026-08-03 |
|---|---|---|
| A) Khởi động nguội: `.exe` (median) | 119ms | **120,3ms** |
| A) Khởi động nguội: `python -c` (median) | 204,6ms | **239,7ms** |
| A) Tỷ lệ | 1,7x | **2,0x** |
| B) Suy luận MLP: `.exe` (median) | — | **107,1ms**, RAM 13,48MB |
| B) Suy luận MLP: sklearn thật (median) | — | **17.000,2ms**, RAM 153,6MB |
| B) Tỷ lệ | 113,6x | **158,7x** |
| C) `self_host_classify.exe` | — | 5.632 bytes (vs numpy 31,3MB + sklearn 40,4MB) |

**Đọc số cho đúng — đừng đọc thành "TokenVector nhanh lên":**

- Phía `.exe` **gần như không đổi** (119 → 120,3ms). Giai đoạn 0.2 chỉ
  đổi cách *phân tích cú pháp* (nơi gọi được builtin), không đụng chất
  lượng IL sinh ra — kỳ vọng đúng là "không đổi", và số đo khớp kỳ vọng.
  Đây là giá trị chính của lần đo này: **xác nhận KHÔNG có hồi quy hiệu
  năng** sau khi xoá hàng loạt đường phân tích cũ.
- Tỷ lệ A và B **tăng vì phía Python chậm đi ở lần chạy này** (204,6 →
  239,7ms; sklearn 12s → 17s), không phải vì IL nhanh lên. Máy 3,7GB RAM,
  tải nền thay đổi giữa 2 lần đo. **Không được dùng 158,7x làm bằng chứng
  cải thiện.**
- Tỷ lệ B vẫn là so **ở tầng triển khai** (khởi động nguội), phần lớn thời
  gian phía sklearn là nạp `joblib/numpy/sklearn` + `joblib.load()`, KHÔNG
  phải "IL nhanh hơn numpy 158 lần". Diễn giải đầy đủ ở
  `test/benchmark/README.md`.
- Số này hậu thuẫn **mục tiêu #4** (footprint/khởi động). Mục tiêu #1/#2
  (thay thế Python / thắng Nuitka-Codon-Mojo) benchmark này KHÔNG hậu thuẫn.

## 📊 Đo lại benchmark — sau đợt "sửa để dùng được hằng ngày" (2026-08-03, lần 2)

Mốc: xong toàn bộ 3 mức ưu tiên rút ra từ phép đo thật
(`scratch/probe_confidence.py`) — sửa ngữ nghĩa `//` `%` với số âm, thêm
`elif`/`True`/`False`/`in`/`*`/`join`/hằng số module, nâng `def` lồng lên
top-level, tuple làm entry CLI. Trước khi đo: `test/verify/` **91/91
PASS**; probe **42/42** biên dịch được (lúc bắt đầu đo là 34/42).

| Hạng mục | 28/7 | 3/8 (lần 1) | 3/8 (lần 2) |
|---|---|---|---|
| A) `.exe` khởi động nguội | 119ms | 120,3ms | **88,0ms** |
| A) `python -c` | 204,6ms | 239,7ms | **173,2ms** |
| A) Tỷ lệ | 1,7x | 2,0x | **2,0x** |
| B) MLP `.exe` | — | 107,1ms | **88,8ms** |
| B) MLP sklearn thật | — | 17.000ms | **10.487ms** |
| B) Tỷ lệ | 113,6x | 158,7x | **118,1x** |
| B) RAM `.exe` / sklearn | — | 13,48 / 153,6MB | **13,26 / 153,24MB** |

**Đọc cho đúng — cả 3 cột đều đo cùng một thứ, khác nhau chủ yếu vì máy:**

- Lần 2 **cả hai phía đều nhanh hơn** lần 1 (`.exe` 120→88ms, `python -c`
  240→173ms, sklearn 17,0→10,5s). Máy lúc đo lần 1 đang tải nặng hơn (vừa
  chạy xong bộ 90 test). Tỷ lệ A giữ nguyên 2,0x, tỷ lệ B tụt từ 158,7x
  xuống 118,1x — **không phải TokenVector chậm đi**, chỉ là phía sklearn
  bớt bị nhiễu.
- **Không kết luận được** đợt sửa vừa rồi làm nhanh lên hay chậm đi: biên
  độ nhiễu giữa 2 lần đo (~30%) lớn hơn mọi khác biệt có thể do thay đổi
  mã sinh. Muốn khẳng định thì phải đo cả 2 phiên bản binary trong **cùng
  một phiên**, chưa làm.
- Điều **có** khẳng định được: `//` và `%` nay sinh thêm 2 nhánh rẽ so với
  1 lệnh `div`/`rem` trước đây. Đây là cái giá phải trả để **đúng** — và
  nó chỉ nằm trên đường dùng phép chia nguyên, không phải mọi phép tính.
- Tỷ lệ B vẫn là so ở **tầng triển khai** (khởi động nguội), phần lớn thời
  gian phía sklearn là nạp `joblib/numpy/sklearn`. Hậu thuẫn mục tiêu #4,
  không hậu thuẫn #1/#2.
