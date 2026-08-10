# Spike: số nguyên kiểu Python (ngang bằng hoàn toàn) — 2026-08-04

Ba file `.il` ở đây là **bằng chứng thiết kế đã chạy thật**, không phải phác
thảo. Chúng trả lời ba câu hỏi phải trả lời *trước khi* động vào ~100 chỗ
trong codegen.

## Vấn đề

Python có số nguyên **vô hạn chữ số**; TokenVector chỉ có `i32`/`i64`. Đo
được trên chính bộ công cụ này:

| | CPython | TokenVector (trước 2026-08-04) |
|---|---|---|
| `fact(13)` | 6227020800 | 1932053504 |
| `fact(20)` | 2432902008176640000 | −2102132736 |
| `2**31` | 2147483648 | **−2147483648** |

`13!` là phép tính hết sức bình thường và nó đã sai sẵn — im lặng, không lỗi.
Khoảng trống này **không nằm trong bất kỳ danh sách nào trước đây**.

## Câu hỏi 1 — `BigInteger` có dùng được trên bộ công cụ này không?

`bigint_factorial.il` — **CÓ**. `ilasm` v4.0.30319 + `System.Numerics`,
`30!` cho đúng 33 chữ số, khớp CPython. Không cần gì thêm ngoài một dòng
`.assembly extern System.Numerics`.

## Câu hỏi 2 — Giá bao nhiêu?

Vòng lặp 20 triệu phép cộng, lấy trung vị 3 lần, **cùng một phiên, cùng tải
máy** (không so số giữa các ngày khác nhau — nhiễu ~30% che khuất mọi khác
biệt do mã sinh):

| Cách làm | Thời gian | So `int32` | **So CPython** |
|---|---|---|---|
| CPython 3.x (`while` + cộng) | 5731 ms | — | 1,0× |
| `int32` thuần (`add.ovf`) | 109 ms | 1,0× | **52,6×** |
| **Đường nhanh NỘI TUYẾN** | **147 ms** | **1,4×** | **39,0×** |
| Đường nhanh qua hàm helper | 1039 ms | 9,5× | 5,5× |
| `BigInteger` thuần | 3445 ms | 31,6× | 1,7× |

**Đây là so sánh CÙNG NGỮ NGHĨA**: CPython ở dòng đầu cũng đang làm số nguyên
vô hạn chữ số. Nên cột cuối mới là cột có ý nghĩa với mục tiêu dự án.

Kết luận: thiết kế nội tuyến cho **đúng ngữ nghĩa Python ở tốc độ nhanh hơn
CPython 39 lần**.

> **Đính chính một nhận định sai lúc đầu.** Ban đầu tôi nói "BigInteger cho
> mọi số nguyên xung đột với mục tiêu *nhanh hơn Python*" — **sai**. Ngay cả
> phương án chậm nhất (`BigInteger` thuần) vẫn nhanh hơn CPython 1,7× **trên
> phép đo này**. Nó xung đột với mục tiêu **thắng Nuitka/Codon/Mojo** (các
> đối thủ chạy tốc độ native), chứ không phải với việc thắng Python. Chốt
> phương án nội tuyến vẫn đúng — nhưng vì lý do đó, không phải lý do tôi nêu.

### ⚠ ĐỪNG khái quát con số 39× — đã có phản ví dụ đo được

Bảng trên là **một vi-benchmark**: vòng lặp cộng số nguyên, ca thuận lợi
nhất cho trình biên dịch. Câu "TokenVector luôn nhanh hơn Python" là **SAI**.
Đo trên chính máy này, dồn chuỗi trong vòng lặp (`out = out + "x"`):

| n | CPython | TokenVector | |
|---|---|---|---|
| 20.000 | 159 ms | 154 ms | hoà |
| 50.000 | 269 ms | 574 ms | CPython nhanh 2,1× |
| 100.000 | 583 ms | 3.303 ms | CPython nhanh 5,7× |
| 200.000 | 1.756 ms | 18.025 ms | **CPython nhanh 10,3×** |

Khoảng cách **nới rộng theo n** — O(n²) so với O(n) khấu hao: mỗi phép `+`
cấp phát và chép lại toàn bộ chuỗi, còn CPython mở rộng **tại chỗ** khi
`refcount == 1`. Điểm hoà vốn quanh n ≈ 20–25 nghìn.

Nên khi báo cáo hiệu năng, luôn nói rõ **tải công việc nào**. Hướng sửa đã
ghi trong `PARITY_GAPS_2026-08-04.md` mục 7: nhận mẫu `x = x + ...` trong
thân vòng lặp rồi dựng `StringBuilder`.

## Câu hỏi 3 — Đường nhanh phải viết thế nào?

`tkvint_helper_calls.il` so với `tkvint_inline.il` trả lời dứt khoát:
**9,5× so với 1,4×**. Khác biệt duy nhất là gọi hàm hay nội tuyến.

→ **Đường nhanh BẮT BUỘC phải nội tuyến tại từng chỗ sinh mã.** Gói nó vào
một hàm helper cho gọn code sẽ mất gần hết lợi ích. Đây là kết luận đắt nhất
của spike này — đừng "dọn dẹp" nó đi.

## Thiết kế đã chốt (theo `tkvint_inline.il`)

Mỗi biến `int` giữ **hai local song song**:

- `lo` — `int64`, giá trị khi còn vừa
- `big` — `object`, `null` nghĩa là **đang ở đường nhanh**; khác `null` là
  `BigInteger` đã đóng hộp

Phép `a + b`, đường nhanh nội tuyến:

```
nếu a.big != null hoặc b.big != null  → đường chậm
r = a.lo + b.lo                        (add THƯỜNG, không .ovf)
nếu ((a.lo ^ r) & (b.lo ^ r)) < 0      → đường chậm (tràn)
ngược lại r chính là kết quả
```

Kiểm tràn bằng **phép bit, không dùng try/catch** — chỉ một nhánh rẽ. Đường
chậm (hiếm) mới gọi helper: nâng cả hai lên `BigInteger`, cộng, đóng hộp lại.

Đây đúng là mô hình `PyLong` của CPython (số nhỏ đi đường nhanh, tự thăng
hạng khi tràn), chỉ khác chỗ CPython lưu số nhỏ trong chính đối tượng còn ở
đây ta tách thành hai local để JIT giữ được trong thanh ghi.

## Spike 2 (2026-08-05) — struct hay hai local? `spike_int_repr.py`

Thiết kế "hai local song song" ở trên **không trả lời được** câu hỏi chặn
đường bước 2: `_compile_expr()` đẩy **đúng một** giá trị lên stack, vậy một
biểu thức `int` *trung gian* (`f(a + b)`) mang hai giá trị đi kiểu gì? Sửa
giao ước đó nghĩa là viết lại ~100 điểm gọi.

Đo thật, cùng một phiên, vòng lặp 10 triệu vòng × 2 phép cộng:

| Cách làm | ms | so CPython |
|---|---|---|
| CPython (int vô hạn) | 2223 | 1,0× |
| `int64` thuần (ngữ nghĩa **SAI**) | 25 | 88,9× |
| hai local song song | 50 | 44,5× |
| **struct, MỘT giá trị trên stack** | **59** | **37,7×** |

Struct đắt hơn hai-local **18%** và giữ nguyên được giao ước "một giá trị
trên stack" của toàn bộ codegen. → **Chọn struct.**

## Trạng thái

Bước 1 đã xong (`a5ce8d2`): `add.ovf`/`sub.ovf`/`mul.ovf` → tràn **báo lỗi**
thay vì quấn vòng im lặng. Chưa ngang bằng, nhưng biến lỗi âm thầm thành lỗi
ồn ào — đúng thứ tự ưu tiên của dự án.

Bước 2 — **lát 1 đã xong (2026-08-05)**, xem `compiler/il_features/int_type.py`:
khai báo kiểu, hằng số, `+ - *`, sáu phép so sánh, `str()`, nâng `i32`/`i64`
→ `int` tự động. `test/verify/bigint_test.py` đối chiếu **ba phía** (`.exe`,
file `.tkv` chạy dưới CPython, và `math.factorial`), đối chứng đột biến 4/4.

Đo thật trên `sum(1..10⁷)` bằng `int`: CPython 4319 ms, TokenVector **263 ms**
— **nhanh hơn 16,4×** với **cùng ngữ nghĩa**, đã tính cả thời gian khởi động
`.exe` (con số 39× của vi-benchmark ở trên không tính khởi động và không có
`str()`; đừng lẫn hai con số).

**Còn lại của bước 2 (lát sau):** `//` `%` `**` `/` trên `int`; `int` làm
phần tử `list`/`dict`/mảng (chưa đăng ký `IL_LDELEM`/`IL_STELEM`/
`IL_NEWARR_ELEM` → thiếu khoá sẽ báo `KeyError` **ồn ào** lúc biên dịch,
đúng ý); `int()`/`abs()`/`min`/`max` trên `int`; và quyết định có đổi
**mặc định** của hằng số nguyên từ `i32` sang `int` hay không (hiện chỉ đổi
bên trong hàm khai báo `-> "int"`).
