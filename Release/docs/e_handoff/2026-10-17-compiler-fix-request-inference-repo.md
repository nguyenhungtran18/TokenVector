# YÊU CẦU CHỈNH SỬA COMPILER — kiểm chứng từ `D:\TokenVector.Inference`

Ngày: **2026-10-17**
Repo kiểm chứng: `D:\TokenVector.Inference`

## TRẠNG THÁI (cập nhật sau build 19:03 — đã đóng hết trừ B-03)

| Mục | Trạng thái |
|---|---|
| B-01 `list[f64]` -> `list[f32]` | **ĐÃ ĐÓNG** |
| B-02 `*`/`+` i64 unchecked | **ĐÃ ĐÓNG** |
| B-03 `sys_argv()` | còn lại |
| B-04 `System.Numerics.Vectors.dll` | **ĐÃ ĐÓNG** (kèm P2-1) |
| B-05 `now_ms`/`now_us`/`gc_*` | **ĐÃ ĐÓNG** (kèm P1-1/P1-2) |
| B-06 chẩn đoán record ctor | **ĐÃ ĐÓNG** |
| B-07 `--verify-all` | **ĐÃ ĐÓNG** (kèm P2-2) |
| D-01 gợi ý "phải dùng nháy kép" trong thông báo lỗi | còn lại (góp ý chẩn đoán) |

Kết quả sau khi đóng: repo inference **48/48 module PASS `--verify-all`**,
26/26 case, gap 16/16, `build_inference.ps1` Completed Successfully, số đo chạy thật.

> **ĐÍNH CHÍNH:** mục "annotated local không biên dịch được" trong bản đầu của note
> này **KHÔNG phải bug compiler** — TokenVector yêu cầu type annotation dùng
> **nháy kép** (`"list[f32]"`). Với nháy kép cả 3 dạng (literal, gán từ biến khác,
> `[]` rồi `append`) đều chạy đúng ngay. Đã hạ xuống mục D-01.
> Repo inference dùng **nháy đơn ở chữ ký hàm** — vẫn hợp lệ, chỉ annotated local
> là yêu cầu nháy kép.

---

## NỘI DUNG YÊU CẦU (theo trạng thái ban đầu)

Compiler đã kiểm: `D:\TokenVector\Release\dist\tkvc-tv.exe` (build 2026-10-17 00:38)
Repo kiểm chứng: `D:\TokenVector.Inference` — hiện **build xanh toàn bộ**
(26/26 case, gap 16/16, `build_inference.ps1` Completed Successfully, 48/48 module).

> Các lỗi dưới đây đều đã được **tái hiện lại trên compiler mới nhất** và đang
> được workaround trong repo downstream. Mỗi workaround đều làm code khó đọc
> và che mất bug thật ở tầng compiler.

---

## P0 — SAI SỐ ÂM THẦM (không có bất kỳ chẩn đoán nào)

### B-01 `list[f64]` truyền vào tham số `list[f32]` → phần tử bị hỏng, không báo lỗi

`[]` + `.append(1.0)` suy ra `list[f64]`. Truyền vào tham số kiểu `list[f32]`:
`len()` đúng, **giá trị từng phần tử sai**, không cảnh báo, không lỗi.

Kỳ vọng: coerce theo phần tử (`f64 → f32`), hoặc tối thiểu phải **báo lỗi**.
Rủi ro hiện tại: trong repo này đã âm thầm làm hỏng một batch matmul trong
`lora_forward` — tìm ra sau khi phải đối chiếu kết quả với C# cũ.

Workaround đang dùng: copy phần tử vòng lặp
```python
for e in src:
    dst.append(e)
```

Nơi cần sửa:
- `compiler_bootstrap/compiler/il_features/operators.tkv` — suy ra kiểu của `append` / list-literal
- `compiler_bootstrap/compiler/il_codegen.tkv:1117` — coerce tham số hàm
- `compiler_bootstrap/compiler/il_core.tkv:1001` — đường coerce tổng quát
- `compiler_bootstrap/compiler/int_type.tkv:7`

> **Workaround được gợi ý trong `COMPILER-NOTES-2026-10-16.md` KHÔNG hoạt động.**
> Khai báo biến đúng kiểu vẫn bị từ chối:
> `_a: 'list[f32]' = []` → `il_codegen: khong dich duoc dong: "_a: 'list[f32]' = []"`
> (tương tự với `_a: 'list[f32]' = _b`).
> Nếu note này được dùng làm hướng dẫn cho repo khác thì cần sửa lại note.

---

## P1 — HÀNH VI SAI SO VỚI NGÔN NGỮ THAM CHIẾU

### B-02 `*` và `+` số nguyên dùng checked arithmetic

`(s * 1103515245 + 12345)` với `s: i64` → `OverflowException` lúc chạy.
Python trả kết quả đúng (wrap).

Nơi cần sửa: `compiler_bootstrap/compiler/il_features/operators.tkv:488`
(`out.append({'+': '    add.ovf', '-': '    sub.ovf', '*': '    mul.ovf'}[op])`).

Ghi chú trong chính file này (dòng ~476-486) đã thừa nhận chưa ngang bằng
Python và nói "bước sau mới đổi sang BigInteger". Đề nghị: bỏ `.ovf` cho kiểu
`int`/`i64` ngay, hoặc chuyển `.ovf` sang `BigInteger` như kế hoạch đã ghi.
(`/` và `%` không áp dụng — `//` và `%` đã có đường riêng.)

Workaround đang dùng: LCG 31-bit `(s * 1103515245 + 12345) & 0x7FFFFFFF`.

### B-03 `sys_argv()` luôn trả `[]`

`stdlib_sys.tkv:9`. CLI không nhận được tham số dòng lệnh.
`GetCommandLineArgs()` được mô tả trong docstring nhưng chưa nối tới runtime.

---

## P1 — RUNTIME HỎNG / SỐ ĐO KHÔNG DÙNG ĐƯỢC

### B-04 SIMD biên dịch được nhưng chạy lỗi

Toàn bộ `simd_*` → `System.Numerics.Vectors.Vector`: biên dịch OK, chạy thì
`FileNotFoundException: System.Numerics.Vectors`.

Nơi cần sửa: `compiler_bootstrap/compiler/il_features/simd_feature.tkv:22`
(`_VEC_EXTERN`), và `_ensure_extern` khoảng dòng 536.
Cần: copy `System.Numerics.Vectors.dll` cạnh output, hoặc sinh code IL thuần
cho `Vector<float>`/`Vector<double>` khi không có assembly.

### B-05 Hàm thời gian và GC là stub trả `0`

`now_ms()`, `now_us()`, `gc_*` trả `0`.
Hệ quả: benchmark in `0.0 ms`, tỷ lệ so sánh giữa các backend ra `infx`.
Repo này **không thể dùng benchmark để so sánh hiệu năng** cho tới khi
được vá.

---

## P2 — CHẨN ĐOÁN KHÓ HIỂU

### B-06 Quy tắc positional của record constructor cần chốt và viết rõ

Hành vi thực tế (đã kiểm chứng trên nhiều class):

| Khai báo | Positional map theo |
|---|---|
| `__init__` có tham số **bắt buộc** | đúng thứ tự tham số `__init__`, **không** có `_ok` |
| `__init__` chỉ có tham số **mặc định** | tất cả field không container, **kèm `_ok`** |
| không có `__init__` | tất cả field không container, **kèm `_ok`** |

Hai nhánh cùng tồn tại trong một repo, người viết phải mở từng class để biết
dùng cách nào. Khi sai, lỗi báo:

```
il_codegen: record 'X' can N tham so (ten1, ten2, ...), gap M
```

Đề nghị:
1. Ghi rõ quy tắc trong tài liệu (hiện chỉ suy ra từ hành vi).
2. Khi không khớp, **in ra cả hai khả năng** — hiện chỉ in một, rất dễ đoán sai.

Nơi cần sửa: `compiler_bootstrap/compiler/il_features/record_feature.tkv:110`
(`codegen_attr_assign`) và nhánh container khoảng dòng 173.

---

## P3 — GÓP Ý CHẨN ĐOÁN (không phải bug)

### D-01 Thông báo lỗi annotated local không nhắc quy tắc nháy kép

TokenVector **bắt buộc** type annotation dùng **nháy kép** (`"list[f32]"`).
Dùng nháy đơn sẽ bị:

```
il_codegen: khong dich duoc dong: "a: 'list[f32]' = [1.0]"
```

Thông báo hiện tại không nói lý do, nên rất dễ bị hiểu nhầm là bug compiler.
Đề nghị bổ sung gợi ý vào thông báo:
`... (type annotation phai dung nhay kep: "list[f32]")`.

> Lưu ý: nháy đơn **vẫn hợp lệ trong chữ ký hàm** (`def f(a: 'list[f32]')`),
> repo `TokenVector.Inference` dùng nháy đơn ở mọi chữ ký và biên dịch bình
> thường. Chỉ **annotated local** (`x: 'T' = ...`) yêu cầu nháy kép.

---

## P2 — THIẾU TÍNH NĂNG

### B-07 Không có chế độ biên dịch toàn bộ thân hàm (lazy compilation)

Compiler chỉ type-check hàm khi hàm được **gọi**. Với repo 48 module / 577 hàm,
điều này khiến "48/48 module compile" **không chứng minh được** phần lớn code
đúng — phải mất công viết probe riêng để ép biên dịch 366 hàm.

Đề nghị thêm cờ, ví dụ `--verify-all` hoặc `TKV_VERIFY_ALL=1`: sinh phần gọi
giả cho mọi hàm cấp module rồi type-check thân từng hàm. Đây là giá trị lớn
nhất cho toàn bộ hệ sinh thái downstream.

---

## Ưu tiên đề nghị

| Mức | Mục | Lý do |
|---|---|---|
| 1 | B-01 | Sai số âm thầm, đã làm hỏng kết quả thật |
| 2 | B-02 | Chặn code kiểu LCG/băm phổ biến |
| 3 | B-04 | SIMD không dùng được |
| 4 | B-07 | Chặn việc chứng minh đúng cho mọi repo downstream |
| 5 | B-05 | Vô hiệu hoá benchmark |
| 6 | B-03, B-06 | Chất lượng chẩn đoán |

## Ghi chú

- Repo này **không chỉnh sửa compiler**. Mọi sửa đổi nếu có phải thực hiện trong
  `compiler_bootstrap/compiler/**`, **không** sửa `build/selfhost/tv_gop.tkv`
  (đó là bản merge).
- Khi vá xong B-01/B-02, các workaround tương ứng trong
  `tv/onnx/translator.tkv` và `tv/training/autograd.tkv` có thể gỡ bỏ — nhưng
  **gỡ từng cái một và chạy lại test**, không gỡ hàng loạt.
- Chi tiết kỹ thuật chi tiết hơn: `2026-10-16-inference-repo-list-alias-and-overflow-bugs.md`,
  `2026-10-16-inference-repo-record-container-type.md` (cùng thư mục).
